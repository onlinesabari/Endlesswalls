import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

import '../services/nature_engine.dart';
import '../utils/wallpaper_actions.dart';
import 'full_screen_preview.dart';

class NatureStudio extends StatefulWidget {
  const NatureStudio({Key? key}) : super(key: key);

  @override
  State<NatureStudio> createState() => _NatureStudioState();
}

class _NatureStudioState extends State<NatureStudio> {
  double density = 0.5;
  String symmetry = 'Bilateral';
  String season = 'Spring';
  int seed = 0;

  final List<String> _symmetryOptions = ['Radial', 'Bilateral', 'Chaos'];
  final List<String> _seasonOptions = ['Spring', 'Summer', 'Autumn', 'Winter'];

  bool _isGenerating = false;
  bool isApplying = false;
  File? currentImageFile;

  @override
  void initState() {
    super.initState();
    _generateNewSeed();
  }

  void _resetAll() {
    setState(() {
      density = 0.5;
      symmetry = 'Bilateral';
      season = 'Spring';
    });
    _generateNewSeed();
  }

  void _generateNewSeed() {
    setState(() {
      seed = Random().nextInt(1000000);
    });
    _generateInstantPreview();
  }

  Future<void> _generateInstantPreview() async {
    if (_isGenerating || !mounted) return;
    setState(() => _isGenerating = true);

    try {
      final file = await NatureEngine.generate(
        density: density,
        symmetry: symmetry,
        season: season,
        seed: seed,
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
        title: const Text("Nature Studio", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
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
                      text: "GENERATE SEED", 
                      icon: Icons.auto_awesome, 
                      onTap: _generateNewSeed
                    ),
                    const SizedBox(height: 28),

                    // Style Selector (Symmetry)
                    const Text("Symmetry", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _symmetryOptions.map((s) {
                        bool isSel = symmetry == s;
                        return GestureDetector(
                          onTap: () {
                            setState(() => symmetry = s);
                            _generateInstantPreview();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? Colors.white : Colors.white10,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s.toUpperCase(),
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

                    // Season Selector
                    const Text("Season", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _seasonOptions.map((s) {
                        bool isSel = season == s;
                        return GestureDetector(
                          onTap: () {
                            setState(() => season = s);
                            _generateInstantPreview();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? Colors.white : Colors.white10,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s.toUpperCase(),
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
                          const Text("Growth Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          EditableSliderRow(label: "Density", value: density, min: 0.0, max: 1.0, onChanged: (v) => setState(() => density = v), onChangeEnd: _generateInstantPreview),
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
    // format to 2 decimal places for 0.0 - 1.0 range
    _controller = TextEditingController(text: widget.value.toStringAsFixed(2));
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _controller.text = widget.value.toStringAsFixed(2);
      }
    });
  }

  @override
  void didUpdateWidget(EditableSliderRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = widget.value.toStringAsFixed(2);
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
      _controller.text = clamped.toStringAsFixed(2);
      widget.onChanged(clamped);
      widget.onChangeEnd(); 
    } else {
      _controller.text = widget.value.toStringAsFixed(2);
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              _controller.text = v.toStringAsFixed(2); 
              widget.onChanged(v);
            },
            onChangeEnd: (_) => widget.onChangeEnd(),
          ),
        ),
      ],
    );
  }
}
