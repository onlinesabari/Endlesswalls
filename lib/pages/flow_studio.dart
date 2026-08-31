import 'dart:io';
import 'package:flutter/material.dart';

import '../services/flow_engine.dart';
import '../randomwall/flow_randomizer.dart';
import '../utils/wallpaper_actions.dart';
import 'full_screen_preview.dart';
import '../utils/color_picker_helper.dart';
import 'aura_studio.dart'; // To reuse EditableSliderRow 

class FlowStudio extends StatefulWidget {
  const FlowStudio({Key? key}) : super(key: key);

  @override
  State<FlowStudio> createState() => _FlowStudioState();
}

class _FlowStudioState extends State<FlowStudio> {
  int particleCount = 2000;
  double noiseScale = 0.003;
  int trailLength = 100;
  double strokeWidth = 1.5;
  
  Color primaryColor = const Color(0xFF00F0FF); // Cyan
  Color secondaryColor = const Color(0xFFFF007F); // Pink
  Color bgColor = const Color(0xFF0F0F0F);

  bool _isGenerating = false;
  bool isApplying = false;
  File? currentImageFile;

  @override
  void initState() {
    super.initState();
    _generateInstantPreview();
  }

  void _resetAll() {
    setState(() {
      particleCount = 2000;
      noiseScale = 0.003;
      trailLength = 100;
      strokeWidth = 1.5;
      primaryColor = const Color(0xFF00F0FF);
      secondaryColor = const Color(0xFFFF007F);
      bgColor = const Color(0xFF0F0F0F);
    });
    _generateInstantPreview();
  }

  void _generateRandomFlow() {
    final randomState = FlowRandomizer.generate();
    setState(() {
      particleCount = randomState.particleCount;
      noiseScale = randomState.noiseScale;
      trailLength = randomState.trailLength;
      strokeWidth = randomState.strokeWidth;
      primaryColor = randomState.primaryColor;
      secondaryColor = randomState.secondaryColor;
      bgColor = randomState.bgColor;
    });
    _generateInstantPreview();
  }

  Future<void> _generateInstantPreview() async {
    if (_isGenerating || !mounted) return;
    setState(() => _isGenerating = true);

    try {
      final file = await FlowEngine.generate(
        particleCount: particleCount,
        noiseScale: noiseScale,
        trailLength: trailLength,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        bgColor: bgColor,
        strokeWidth: strokeWidth,
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
        title: const Text("Flow Studio", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
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
                      onTap: _generateRandomFlow
                    ),
                    const SizedBox(height: 28),
                    
                    // Colors Card
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Palette Configuration", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _colorPickerBtn("Primary", primaryColor, (c) { setState(() => primaryColor = c); _generateInstantPreview(); }),
                              _colorPickerBtn("Secondary", secondaryColor, (c) { setState(() => secondaryColor = c); _generateInstantPreview(); }),
                              _colorPickerBtn("Background", bgColor, (c) { setState(() => bgColor = c); _generateInstantPreview(); }),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Controls Card
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Vector Field Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          
                          EditableSliderRow(label: "Particle Count", value: particleCount.toDouble(), min: 100, max: 10000, onChanged: (v) => setState(() => particleCount = v.toInt()), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: "Flow Scale (Noise)", value: noiseScale * 1000, min: 0.1, max: 20.0, onChanged: (v) => setState(() => noiseScale = v / 1000), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: "Trail Length", value: trailLength.toDouble(), min: 10, max: 500, onChanged: (v) => setState(() => trailLength = v.toInt()), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: "Stroke Width", value: strokeWidth, min: 0.1, max: 10.0, onChanged: (v) => setState(() => strokeWidth = v), onChangeEnd: _generateInstantPreview),
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

  Widget _colorPickerBtn(String label, Color color, ValueChanged<Color> onChanged) {
    return Column(
      children: [
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => ColorPickerHelper.show(context: context, initialColor: color, onColorChanged: onChanged),
          child: Container(width: 44, height: 44, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2))),
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
          gradient: const LinearGradient(colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)]), // Switched to a nice flow gradient
          boxShadow: [BoxShadow(color: const Color(0xFF00C9FF).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
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
