import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

import '../services/crystal_engine.dart';
import '../randomwall/crystal_randomizer.dart';
import '../utils/wallpaper_actions.dart';
import 'full_screen_preview.dart';
import '../utils/color_picker_helper.dart';

class CrystalStudio extends StatefulWidget {
  const CrystalStudio({Key? key}) : super(key: key);

  @override
  State<CrystalStudio> createState() => _CrystalStudioState();
}

class _CrystalStudioState extends State<CrystalStudio> {
  // Settings
  double rows = 6;
  double cols = 4;
  double jitter = 0.5; // 0 = Perfect grid, 1 = Shattered chaos
  double lineWidth = 4.0;
  Color lineColor = Colors.black;
  List<Color> activeColors = [];

  bool _isGenerating = false;
  bool isApplying = false;
  File? currentImageFile;

  @override
  void initState() {
    super.initState();
    _resetAll();
  }

  void _resetAll() {
    setState(() {
      rows = 6;
      cols = 4;
      jitter = 0.5;
      lineWidth = 4.0;
      lineColor = Colors.black;
      activeColors = [
        const Color(0xFFE63946),
        const Color(0xFFA8DADC),
        const Color(0xFF1D3557),
      ];
    });
    _generateInstantPreview();
  }

  List<Offset> _calculatePoints() {
    List<Offset> points = [];
    double cellW = 1080.0 / cols;
    double cellH = 1920.0 / rows;
    Random rnd = Random(42); // Seeded so slider adjustments don't cause flickering jumps

    for (int r = 0; r < rows.toInt(); r++) {
      for (int c = 0; c < cols.toInt(); c++) {
        double cx = c * cellW + cellW / 2;
        double cy = r * cellH + cellH / 2;

        // Apply Jitter offset
        double offsetX = (rnd.nextDouble() - 0.5) * jitter * cellW * 1.5;
        double offsetY = (rnd.nextDouble() - 0.5) * jitter * cellH * 1.5;

        points.add(Offset(cx + offsetX, cy + offsetY));
      }
    }
    return points;
  }

  void _generateRandomCrystal() {
    final state = CrystalRandomizer.generate();
    setState(() {
      rows = state.rows.toDouble();
      cols = state.cols.toDouble();
      jitter = state.jitter;
      lineWidth = state.lineWidth;
      lineColor = state.lineColor;
      activeColors = state.palette;
    });
    _generateInstantPreview();
  }

  Future<void> _generateInstantPreview() async {
    if (_isGenerating || activeColors.isEmpty || !mounted) return;
    setState(() => _isGenerating = true);

    try {
      final file = await CrystalEngine.generate(
        points: _calculatePoints(),
        colors: activeColors,
        lineColor: lineColor,
        lineWidth: lineWidth,
      );
      if (mounted) setState(() => currentImageFile = file);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _addColor() {
    if (activeColors.length >= 8) return;
    final r = Random();
    Color randomColor = Color.fromARGB(255, r.nextInt(256), r.nextInt(256), r.nextInt(256));
    setState(() => activeColors.add(randomColor));
    _generateInstantPreview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Universal Dark Background
      appBar: AppBar(
        title: const Text("Crystal Studio", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
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
                  
                  // Image Canvas (Flexible)
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

          // --- 2. THE CONTROL DECK ---
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
                      text: "SHATTER (SURPRISE)", 
                      icon: Icons.auto_awesome, 
                      onTap: _generateRandomCrystal
                    ),
                    const SizedBox(height: 28),

                    // --- CARD 1: PHYSICS & GRID ---
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Cell Density & Physics", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          
                          EditableSliderRow(label: "Columns", value: cols, min: 2, max: 10, onChanged: (v) => setState(() => cols = v), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: "Rows", value: rows, min: 2, max: 15, onChanged: (v) => setState(() => rows = v), onChangeEnd: _generateInstantPreview),
                          
                          const Divider(color: Colors.white10, height: 24),
                          
                          EditableSliderRow(label: "Chaos Jitter (%)", value: jitter * 100, min: 0, max: 100, onChanged: (v) => setState(() => jitter = v / 100), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: "Line Thickness", value: lineWidth, min: 0, max: 20, onChanged: (v) => setState(() => lineWidth = v), onChangeEnd: _generateInstantPreview),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- CARD 2: COLORS ---
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Crystal Palette", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              if (activeColors.length < 8)
                                GestureDetector(
                                  onTap: _addColor,
                                  child: const CircleAvatar(radius: 14, backgroundColor: Colors.white12, child: Icon(Icons.add, color: Colors.white, size: 18)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Horizontal Palette List
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: activeColors.length,
                              itemBuilder: (ctx, i) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16, top: 5),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      GestureDetector(
                                        onTap: () => ColorPickerHelper.show(
                                          context: context, 
                                          initialColor: activeColors[i], 
                                          onColorChanged: (c) {
                                            setState(() => activeColors[i] = c);
                                            _generateInstantPreview();
                                          }
                                        ),
                                        child: Container(
                                          width: 50, height: 50,
                                          decoration: BoxDecoration(color: activeColors[i], shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2)),
                                          child: const Icon(Icons.edit, color: Colors.white, size: 18),
                                        ),
                                      ),
                                      if (activeColors.length > 2)
                                        Positioned(
                                          top: -5, right: -5,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() => activeColors.removeAt(i));
                                              _generateInstantPreview();
                                            },
                                            child: const CircleAvatar(radius: 11, backgroundColor: Colors.redAccent, child: Icon(Icons.close, size: 12, color: Colors.white)),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          const Divider(color: Colors.white10, height: 24),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Line Color", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                              GestureDetector(
                                onTap: () => ColorPickerHelper.show(context: context, initialColor: lineColor, onColorChanged: (c) { setState(() => lineColor = c); _generateInstantPreview(); }),
                                child: Container(width: 36, height: 36, decoration: BoxDecoration(color: lineColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24))),
                              ),
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

  // ==========================================
  // UNIVERSAL STUDIO UI COMPONENTS
  // ==========================================

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

// ==========================================
// EDITABLE SLIDER COMPONENT
// ==========================================
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