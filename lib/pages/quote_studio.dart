import 'dart:io';
import 'package:flutter/material.dart';

import '../services/quote_engine.dart';
import '../randomwall/quote_randomizer.dart';
import '../utils/wallpaper_actions.dart';
import 'full_screen_preview.dart';
import '../utils/color_picker_helper.dart';

class QuoteStudio extends StatefulWidget {
  const QuoteStudio({Key? key}) : super(key: key);

  @override
  State<QuoteStudio> createState() => _QuoteStudioState();
}

class _QuoteStudioState extends State<QuoteStudio> {
  Color bgColor = const Color(0xFF0F0F0F);
  Color primaryColor = const Color(0xFF00F0FF);
  Color accentColor = const Color(0xFFFF007F);
  QuoteStyle style = QuoteStyle.matrix;
  double fontSize = 60.0;
  double density = 100.0;
  List<String> texts = ["DESIGN", "CREATE", "INSPIRE", "ART", "FLOW"];

  bool _isGenerating = false;
  bool isApplying = false;
  File? currentImageFile;
  
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.text = texts.join(", ");
    _generateInstantPreview();
  }
  
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _resetAll() {
    setState(() {
      bgColor = const Color(0xFF0F0F0F);
      primaryColor = const Color(0xFF00F0FF);
      accentColor = const Color(0xFFFF007F);
      style = QuoteStyle.matrix;
      fontSize = 60.0;
      density = 100.0;
      texts = ["DESIGN", "CREATE", "INSPIRE", "ART", "FLOW"];
      _textController.text = texts.join(", ");
    });
    _generateInstantPreview();
  }

  void _generateRandomQuote() {
    final randomState = QuoteRandomizer.generate();
    setState(() {
      bgColor = randomState.bgColor;
      primaryColor = randomState.primaryColor;
      accentColor = randomState.accentColor;
      style = randomState.style;
      fontSize = randomState.fontSize;
      density = randomState.density;
      texts = randomState.texts;
      _textController.text = texts.join(", ");
    });
    _generateInstantPreview();
  }

  void _updateTexts(String val) {
    setState(() {
      texts = val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (texts.isEmpty) texts = ["TYPE", "SOMETHING"];
    });
    _generateInstantPreview();
  }

  Future<void> _generateInstantPreview() async {
    if (_isGenerating || !mounted) return;
    setState(() => _isGenerating = true);

    try {
      final file = await QuoteEngine.generate(
        texts: texts,
        bgColor: bgColor,
        primaryColor: primaryColor,
        accentColor: accentColor,
        style: style,
        fontSize: fontSize,
        density: density,
      );
      if (mounted) setState(() => currentImageFile = file);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Typography Studio", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), tooltip: "Reset All", onPressed: _resetAll),
        ],
      ),
      body: Column(
        children: [
          // --- 1. PREVIEW SECTION ---
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Button (Apply)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildGlassButton(
                      color: Colors.greenAccent,
                      customWidget: isApplying 
                          ? const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent))
                          : const Icon(Icons.check_circle, color: Colors.greenAccent, size: 26),
                      onTap: isApplying ? null : () => WallpaperActions.showApplyMenu(context: context, imageFile: currentImageFile, onLoading: (val) => setState(() => isApplying = val)),
                    ),
                  ),
                  
                  // Image Canvas
                  Flexible(
                    child: AspectRatio(
                      aspectRatio: 1080 / 1920,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: currentImageFile == null 
                            ? const Center(child: CircularProgressIndicator(color: Colors.white)) 
                            : Image.file(currentImageFile!, fit: BoxFit.cover, alignment: Alignment.center),
                        ),
                      ),
                    ),
                  ),

                  // Right Button (Fullscreen)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildGlassButton(
                      icon: Icons.fullscreen,
                      color: Colors.white,
                      onTap: () { if (currentImageFile != null) Navigator.push(context, MaterialPageRoute(builder: (context) => FullScreenPreview(imageFile: currentImageFile!))); },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),

          // --- 2. CONTROL DECK ---
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gradient Magic Button
                    _buildGradientButton(
                      text: "SURPRISE ME", 
                      icon: Icons.auto_awesome, 
                      onTap: _generateRandomQuote
                    ),
                    const SizedBox(height: 28),

                    // Words Input
                    const Text("Words (comma separated)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        hintText: "Enter words here",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      ),
                      onSubmitted: _updateTexts,
                    ),
                    const SizedBox(height: 24),

                    // Style Selector
                    const Text("Layout Style", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: QuoteStyle.values.map((s) {
                        bool isSel = style == s;
                        return GestureDetector(
                          onTap: () {
                            setState(() => style = s);
                            _generateInstantPreview();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? Colors.white : Colors.white10,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s.name.toUpperCase(),
                              style: TextStyle(
                                color: isSel ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Sliders
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Typography Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          EditableSliderRow(label: "Font Size", value: fontSize, min: 20, max: 200, onChanged: (v) => setState(() => fontSize = v), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: "Density", value: density, min: 10, max: 200, onChanged: (v) => setState(() => density = v), onChangeEnd: _generateInstantPreview),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Colors
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Colors", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildColorPicker("Background", bgColor, (c) { setState(() => bgColor = c); _generateInstantPreview(); }),
                              _buildColorPicker("Primary", primaryColor, (c) { setState(() => primaryColor = c); _generateInstantPreview(); }),
                              _buildColorPicker("Accent", accentColor, (c) { setState(() => accentColor = c); _generateInstantPreview(); }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(String label, Color color, ValueChanged<Color> onChanged) {
    return Column(
      children: [
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => ColorPickerHelper.show(context: context, initialColor: color, onColorChanged: onChanged),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildGlassButton({IconData? icon, Widget? customWidget, required Color color, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.1), width: 1)),
        child: customWidget ?? Icon(icon, color: color, size: 26),
      ),
    );
  }

  Widget _buildGradientButton({required String text, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)]),
          boxShadow: [BoxShadow(color: const Color(0xFFE94057).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: child,
    );
  }
}

// Slider code repeated for independence
class EditableSliderRow extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final VoidCallback onChangeEnd;

  const EditableSliderRow({
    Key? key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  }) : super(key: key);

  @override
  State<EditableSliderRow> createState() => _EditableSliderRowState();
}

class _EditableSliderRowState extends State<EditableSliderRow> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toInt().toString());
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _controller.text = widget.value.toInt().toString(); 
      }
    });
  }

  @override
  void didUpdateWidget(EditableSliderRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = widget.value.toInt().toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitValue(String val) {
    double? parsed = double.tryParse(val);
    if (parsed != null) {
      double clamped = parsed.clamp(widget.min, widget.max);
      _controller.text = clamped.toInt().toString();
      widget.onChanged(clamped);
      widget.onChangeEnd(); 
    } else {
      _controller.text = widget.value.toInt().toString();
    }
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
            Container(
              width: 50,
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white12)
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                onSubmitted: _submitValue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6.0,
            activeTrackColor: Colors.white, 
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
          ),
          child: Slider(
            value: widget.value,
            min: widget.min,
            max: widget.max,
            onChanged: (v) {
              _controller.text = v.toInt().toString(); 
              widget.onChanged(v);
            },
            onChangeEnd: (_) => widget.onChangeEnd(),
          ),
        ),
      ],
    );
  }
}
