import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

import '../services/geometry_engine.dart';
import '../utils/wallpaper_actions.dart';
import 'full_screen_preview.dart';
import '../randomwall/geom_randomizer.dart';
import '../utils/color_picker_helper.dart';

class GeometryStudio extends StatefulWidget {
  const GeometryStudio({Key? key}) : super(key: key);

  @override
  State<GeometryStudio> createState() => _GeometryStudioState();
}

class _GeometryStudioState extends State<GeometryStudio> {
  // --- STATE ---
  List<GeometryLayer> layers = [];
  bool isApplying = false;
  bool _isGenerating = false;
  bool enableTransparency = false;
  Color selectedBgColor = const Color(0xFF0F0F0F);
  File? currentImageFile;
  
  int activeLayerIndex = 0;

  final List<String> shapeTypes = ['polygon', 'circle', 'ring', 'rectangle', 'star', 'cross'];

  @override
  void initState() {
    super.initState();
    _resetAll();
  }

  void _resetAll() {
    setState(() {
      selectedBgColor = const Color(0xFF0F0F0F);
      enableTransparency = false;
      layers = [
        GeometryLayer(sides: 3, color: const Color(0xFFE76F51), size: 600, x: 540, y: 750, shapeType: 'polygon'),
        GeometryLayer(sides: 6, color: const Color(0xFF00F0FF), size: 400, x: 540, y: 1100, isStroke: true, shapeType: 'circle', sweepAngle: 180.0, skewX: -0.2),
      ];
      activeLayerIndex = 0;
    });
    _generateInstantPreview();
  }

  void _generateRandomArt() {
    final randomState = GeomRandomizer.generate();
    setState(() {
      layers = randomState.layers;
      selectedBgColor = randomState.bgColor;
      enableTransparency = randomState.enableTransparency;
      activeLayerIndex = 0;
    });
    _generateInstantPreview();
  }

  void _resetLayer(int index) {
    setState(() {
      layers[index] = GeometryLayer(
        sides: 4, 
        color: layers[index].color, 
        size: 300, 
        x: 540, 
        y: 960, 
        shapeType: 'polygon'
      );
    });
    _generateInstantPreview();
  }

  void _addNewLayer() {
    if (layers.length >= 8) return;
    final r = Random();
    Color randomColor = Color.fromARGB(255, r.nextInt(256), r.nextInt(256), r.nextInt(256));
    
    setState(() {
      layers.add(GeometryLayer(sides: 4, color: randomColor, size: 300, x: 540, y: 960, shapeType: 'polygon'));
      activeLayerIndex = layers.length - 1; 
    });
    _generateInstantPreview();
  }

  void _deleteLayer(int index) {
    if (layers.length <= 1) return;
    setState(() {
      layers.removeAt(index);
      if (activeLayerIndex >= layers.length) activeLayerIndex = layers.length - 1;
    });
    _generateInstantPreview();
  }

  Future<void> _generateInstantPreview() async {
    if (_isGenerating || layers.isEmpty || !mounted) return;
    setState(() => _isGenerating = true);

    try {
      final file = await GeometryEngine.generate(layers, selectedBgColor, enableTransparency);
      if (mounted) setState(() => currentImageFile = file);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (activeLayerIndex >= layers.length) activeLayerIndex = layers.length - 1;
    GeometryLayer activeLayer = layers[activeLayerIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Geometry Canvas", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
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
                      text: "SURPRISE ME", 
                      icon: Icons.auto_awesome, 
                      onTap: _generateRandomArt
                    ),
                    const SizedBox(height: 28),

                    // --- LAYER TABS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Shape Layers", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        if (layers.length < 8) 
                          GestureDetector(
                            onTap: _addNewLayer,
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
                        itemCount: layers.length,
                        itemBuilder: (ctx, i) {
                          bool isActive = i == activeLayerIndex;
                          return GestureDetector(
                            onTap: () => setState(() => activeLayerIndex = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: isActive ? layers[i].color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: isActive ? layers[i].color : Colors.transparent, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(radius: 6, backgroundColor: layers[i].color),
                                  const SizedBox(width: 8),
                                  Text("Shape ${i + 1}", style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // --- THE ACTIVE LAYER CARD ---
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("Editing Shape ${activeLayerIndex + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              const Spacer(),
                              IconButton(icon: const Icon(Icons.restore, size: 20, color: Colors.white54), onPressed: () => _resetLayer(activeLayerIndex)),
                              IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: layers.length > 1 ? () => _deleteLayer(activeLayerIndex) : null),
                            ],
                          ),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              _buildModernDropdown("SHAPE TYPE", activeLayer.shapeType, shapeTypes, (val) { setState(() => activeLayer.shapeType = val!); _generateInstantPreview(); }),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("COLOR", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () => ColorPickerHelper.show(context: context, initialColor: activeLayer.color, onColorChanged: (c) { setState(() => activeLayer.color = c); _generateInstantPreview(); }),
                                    child: Container(width: 44, height: 44, decoration: BoxDecoration(color: activeLayer.color, shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2))),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Outline Only (Stroke)", style: TextStyle(color: Colors.white, fontSize: 14)),
                              Switch(activeColor: Colors.tealAccent, value: activeLayer.isStroke, onChanged: (v) { setState(() => activeLayer.isStroke = v); _generateInstantPreview(); }),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Universal Sliders (Handling decimals now!)
                          EditableSliderRow(label: "Position X", value: activeLayer.x, min: 0, max: 1080, onChanged: (v) => setState(() => activeLayer.x = v), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: "Position Y", value: activeLayer.y, min: 0, max: 1920, onChanged: (v) => setState(() => activeLayer.y = v), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: "Base Size", value: activeLayer.size, min: 50, max: 1200, onChanged: (v) => setState(() => activeLayer.size = v), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: "Stretch Width", value: activeLayer.scaleX, min: 0.1, max: 5.0, isDecimal: true, onChanged: (v) => setState(() => activeLayer.scaleX = v), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: "Stretch Height", value: activeLayer.scaleY, min: 0.1, max: 5.0, isDecimal: true, onChanged: (v) => setState(() => activeLayer.scaleY = v), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: "Rotation", value: activeLayer.rotation, min: -180, max: 180, onChanged: (v) => setState(() => activeLayer.rotation = v), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: "Skew X (Shear)", value: activeLayer.skewX, min: -1.5, max: 1.5, isDecimal: true, onChanged: (v) => setState(() => activeLayer.skewX = v), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: "Skew Y (Shear)", value: activeLayer.skewY, min: -1.5, max: 1.5, isDecimal: true, onChanged: (v) => setState(() => activeLayer.skewY = v), onChangeEnd: _generateInstantPreview),

                          if (activeLayer.shapeType == 'polygon' || activeLayer.shapeType == 'star')
                            EditableSliderRow(label: "Points / Sides", value: activeLayer.sides.toDouble(), min: 3, max: 12, onChanged: (v) => setState(() => activeLayer.sides = v.toInt()), onChangeEnd: _generateInstantPreview),

                          if (activeLayer.shapeType == 'circle' || activeLayer.shapeType == 'ring')
                            EditableSliderRow(label: "Sweep Angle (Degrees)", value: activeLayer.sweepAngle, min: 10, max: 360, onChanged: (v) => setState(() => activeLayer.sweepAngle = v), onChangeEnd: _generateInstantPreview),

                          if (activeLayer.shapeType == 'ring' || activeLayer.shapeType == 'star' || activeLayer.shapeType == 'cross')
                            EditableSliderRow(label: "Thickness / Inner Depth", value: activeLayer.innerRadiusRatio, min: 0.1, max: 0.9, isDecimal: true, onChanged: (v) => setState(() => activeLayer.innerRadiusRatio = v), onChangeEnd: _generateInstantPreview),
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
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Glassy Overlap", style: TextStyle(color: Colors.white, fontSize: 14)),
                              Switch(
                                activeColor: Colors.tealAccent,
                                value: enableTransparency,
                                onChanged: (v) { setState(() => enableTransparency = v); _generateInstantPreview(); },
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white10, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Canvas Background", style: TextStyle(color: Colors.white, fontSize: 14)),
                              GestureDetector(
                                onTap: () => ColorPickerHelper.show(context: context, initialColor: selectedBgColor, onColorChanged: (c) { setState(() => selectedBgColor = c); _generateInstantPreview(); }),
                                child: Container(width: 36, height: 36, decoration: BoxDecoration(color: selectedBgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24))),
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

  Widget _buildModernDropdown(String title, String value, List<String> options, Function(String?) onChanged) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value, isExpanded: true, dropdownColor: const Color(0xFF2C2C2E), icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// EDITABLE SLIDER COMPONENT (Upgraded for Decimals)
// ==========================================
class EditableSliderRow extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final bool isDecimal; // NEW: Supports precise geometry controls
  final ValueChanged<double> onChanged;
  final VoidCallback onChangeEnd;

  const EditableSliderRow({
    Key? key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.isDecimal = false,
    required this.onChanged,
    required this.onChangeEnd,
  }) : super(key: key);

  @override
  State<EditableSliderRow> createState() => _EditableSliderRowState();
}

class _EditableSliderRowState extends State<EditableSliderRow> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  String _formatValue(double v) => widget.isDecimal ? v.toStringAsFixed(2) : v.toInt().toString();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _controller.text = _formatValue(widget.value); 
      }
    });
  }

  @override
  void didUpdateWidget(EditableSliderRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = _formatValue(widget.value);
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
      _controller.text = _formatValue(clamped);
      widget.onChanged(clamped);
      widget.onChangeEnd(); 
    } else {
      _controller.text = _formatValue(widget.value);
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
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
              _controller.text = _formatValue(v); 
              widget.onChanged(v);
            },
            onChangeEnd: (_) => widget.onChangeEnd(),
          ),
        ),
      ],
    );
  }
}