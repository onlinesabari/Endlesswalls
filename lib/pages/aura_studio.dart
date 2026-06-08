import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

import '../services/aura_engine.dart';
import '../randomwall/aura_randomizer.dart';
import '../utils/wallpaper_actions.dart';
import 'full_screen_preview.dart';
import '../utils/color_picker_helper.dart';

class AuraStudio extends StatefulWidget {
  const AuraStudio({Key? key}) : super(key: key);

  @override
  State<AuraStudio> createState() => _AuraStudioState();
}

class _AuraStudioState extends State<AuraStudio> {
  List<AuraOrb> orbs = [];
  double globalBlur = 250.0;
  Color bgColor = const Color(0xFF0F0F0F);

  bool _isGenerating = false;
  bool isApplying = false;
  File? currentImageFile;

  int activeLayerIndex = 0;

  @override
  void initState() {
    super.initState();
    _resetAll();
  }

  void _resetAll() {
    setState(() {
      bgColor = const Color(0xFF0F0F0F);
      globalBlur = 250.0;
      orbs = [
        AuraOrb(x: 200, y: 300, radius: 500, color: const Color(0xFFFF007F)), // Pink
        AuraOrb(x: 800, y: 960, radius: 600, color: const Color(0xFF00F0FF)), // Cyan
        AuraOrb(x: 300, y: 1600, radius: 450, color: const Color(0xFF240046)), // Deep Purple
      ];
      activeLayerIndex = 0;
    });
    _generateInstantPreview();
  }

  void _generateRandomAura() {
    final randomState = AuraRandomizer.generate();
    setState(() {
      orbs = randomState.orbs;
      bgColor = randomState.bgColor;
      globalBlur = randomState.blurRadius;
      activeLayerIndex = 0; 
    });
    _generateInstantPreview();
  }

  void _resetLayer(int index) {
    setState(() {
      orbs[index].x = 540;
      orbs[index].y = 960;
      orbs[index].radius = 400;
    });
    _generateInstantPreview();
  }

  void _addOrb() {
    if (orbs.length >= 8) return;
    
    // Using the same random vibrant color logic from Wave Studio
    final r = Random();
    Color randomColor = Color.fromARGB(255, r.nextInt(256), r.nextInt(256), r.nextInt(256));

    setState(() {
      orbs.add(AuraOrb(x: 540, y: 960, radius: 400, color: randomColor));
      activeLayerIndex = orbs.length - 1; // Auto-focus new orb
    });
    _generateInstantPreview();
  }

  void _deleteLayer(int index) {
    if (orbs.length <= 1) return;
    setState(() {
      orbs.removeAt(index);
      if (activeLayerIndex >= orbs.length) activeLayerIndex = orbs.length - 1;
    });
    _generateInstantPreview();
  }

  Future<void> _generateInstantPreview() async {
    if (_isGenerating || orbs.isEmpty || !mounted) return;
    setState(() => _isGenerating = true);

    try {
      final file = await AuraEngine.generate(
        orbs: orbs,
        bgColor: bgColor,
        globalBlur: globalBlur,
      );
      if (mounted) setState(() => currentImageFile = file);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (activeLayerIndex >= orbs.length) activeLayerIndex = orbs.length - 1;
    AuraOrb activeOrb = orbs[activeLayerIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Universal Dark Background
      appBar: AppBar(
        title: const Text("Aura Studio", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), tooltip: "Reset All", onPressed: _resetAll),
        ],
      ),
      body: Column(
        children: [
          // --- 1. PREVIEW SECTION (Universal Layout) ---
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
                      text: "SURPRISE ME", 
                      icon: Icons.auto_awesome, 
                      onTap: _generateRandomAura
                    ),
                    const SizedBox(height: 28),

                    // --- LAYER TABS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Aura Orbs", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        if (orbs.length < 8) 
                          GestureDetector(
                            onTap: _addOrb,
                            child: const CircleAvatar(radius: 16, backgroundColor: Colors.white12, child: Icon(Icons.add, color: Colors.white, size: 20)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: orbs.length,
                        itemBuilder: (ctx, i) {
                          bool isActive = i == activeLayerIndex;
                          return GestureDetector(
                            onTap: () => setState(() => activeLayerIndex = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: isActive ? orbs[i].color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: isActive ? orbs[i].color : Colors.transparent, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(radius: 6, backgroundColor: orbs[i].color),
                                  const SizedBox(width: 8),
                                  Text("Orb ${i + 1}", style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // --- THE ACTIVE ORB CARD ---
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("Editing Orb ${activeLayerIndex + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              const Spacer(),
                              IconButton(icon: const Icon(Icons.restore, size: 20, color: Colors.white54), onPressed: () => _resetLayer(activeLayerIndex)),
                              IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: orbs.length > 1 ? () => _deleteLayer(activeLayerIndex) : null),
                            ],
                          ),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("COLOR", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () => ColorPickerHelper.show(context: context, initialColor: activeOrb.color, onColorChanged: (c) { setState(() => activeOrb.color = c); _generateInstantPreview(); }),
                                    child: Container(width: 44, height: 44, decoration: BoxDecoration(color: activeOrb.color, shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2))),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Universal Editable Sliders
                          EditableSliderRow(label: "Position X", value: activeOrb.x, min: -200, max: 1280, onChanged: (v) => setState(() => activeOrb.x = v), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: "Position Y", value: activeOrb.y, min: -200, max: 2120, onChanged: (v) => setState(() => activeOrb.y = v), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: "Radius (Size)", value: activeOrb.radius, min: 100, max: 1500, onChanged: (v) => setState(() => activeOrb.radius = v), onChangeEnd: _generateInstantPreview),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- GLOBAL SETTINGS CARD ---
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Global Canvas Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          
                          EditableSliderRow(label: "Atmosphere Softness", value: globalBlur, min: 0, max: 500, onChanged: (v) => setState(() => globalBlur = v), onChangeEnd: _generateInstantPreview),
                          
                          const Divider(color: Colors.white10, height: 24),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Canvas Background", style: TextStyle(color: Colors.white, fontSize: 14)),
                              GestureDetector(
                                onTap: () => ColorPickerHelper.show(context: context, initialColor: bgColor, onColorChanged: (c) { setState(() => bgColor = c); _generateInstantPreview(); }),
                                child: Container(width: 36, height: 36, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24))),
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