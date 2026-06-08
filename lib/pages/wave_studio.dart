import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

import '../services/wave_engine.dart';
import 'full_screen_preview.dart';
import '../randomwall/wave_randomizer.dart';
import '../utils/wallpaper_actions.dart';
import '../utils/color_picker_helper.dart';

class WaveStudio extends StatefulWidget {
  const WaveStudio({Key? key}) : super(key: key);

  @override
  State<WaveStudio> createState() => _WaveStudioState();
}

class _WaveStudioState extends State<WaveStudio> {
  List<WaveLayer> waveLayers = [];
  File? currentImageFile;
  bool isApplying = false;    
  bool _isGenerating = false; 
  bool enableTransparency = false;

  late Color selectedBgColor;
  final List<String> availableLineTypes = ['Sine', 'Bezier', 'ZigZag'];
  
  int activeLayerIndex = 0;

  @override
  void initState() {
    super.initState();
    _resetAll();
  }

  void _resetAll() {
    setState(() {
      selectedBgColor = const Color(0xFF0F2027);
      waveLayers = [
        WaveLayer(type: 'Sine', color: const Color(0xFFE9C46A), amplitude: 80, frequency: 4, verticalPosition: 1600, rotation: 0)
      ];
      activeLayerIndex = 0;
    });
    _generateInstantPreview();
  }

  void _generateRandomArt() {
    WaveRandomState randomState = WaveRandomizer.generate();
    setState(() {
      waveLayers = randomState.layers;
      selectedBgColor = randomState.bgColor;
      enableTransparency = randomState.enableTransparency;
      activeLayerIndex = 0; 
    });
    _generateInstantPreview();
  }

  void _resetLayer(int index) {
    setState(() {
      double defaultY = 1200.0 - (index * 250.0);
      waveLayers[index].type = 'Sine';
      waveLayers[index].amplitude = 50; 
      waveLayers[index].frequency = 4;  
      waveLayers[index].rotation = 0;   
      waveLayers[index].verticalPosition = defaultY < 200 ? 200 : defaultY; 
    });
    _generateInstantPreview();
  }

  void _addNewLayer() {
    if (waveLayers.length >= 5) return;
    
    final r = Random();
    Color randomColor = Color.fromARGB(255, r.nextInt(256), r.nextInt(256), r.nextInt(256));

    setState(() {
      double newY = waveLayers.last.verticalPosition - 300;
      waveLayers.add(WaveLayer(type: 'Sine', color: randomColor, amplitude: 50, frequency: 4, verticalPosition: newY.clamp(200, 1700), rotation: 0));
      activeLayerIndex = waveLayers.length - 1; 
    });
    _generateInstantPreview();
  }

  void _deleteLayer(int index) {
    if (waveLayers.length <= 1) return;
    setState(() {
      waveLayers.removeAt(index);
      if (activeLayerIndex >= waveLayers.length) activeLayerIndex = waveLayers.length - 1;
    });
    _generateInstantPreview();
  }

  Future<void> _generateInstantPreview() async {
    if (_isGenerating || waveLayers.isEmpty || !mounted) return;
    setState(() => _isGenerating = true);

    try {
      File newFile = await WaveEngine.generate(layers: waveLayers, bgColor: selectedBgColor, enableTransparency: enableTransparency);
      if (!mounted) return;
      setState(() => currentImageFile = newFile);
    } catch (e) {
      debugPrint("Engine Error: $e");
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (activeLayerIndex >= waveLayers.length) activeLayerIndex = waveLayers.length - 1;
    WaveLayer activeLayer = waveLayers[activeLayerIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Wave Studio', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), tooltip: "Reset All", onPressed: _resetAll),
        ],
      ),
      body: Column(
        children: [
          // --- 1. PREVIEW SECTION (Fixed max-height with edge buttons) ---
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
                  
                  // Image Canvas (Flexible allows it to hit max height)
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
                            : Image.file(currentImageFile!, fit: BoxFit.cover, alignment: Alignment.bottomCenter),
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
                    _buildGradientButton(
                      text: "SURPRISE ME", 
                      icon: Icons.auto_awesome, 
                      onTap: _generateRandomArt
                    ),
                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Wave Layers", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        if (waveLayers.length < 5) 
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
                        itemCount: waveLayers.length,
                        itemBuilder: (ctx, i) {
                          bool isActive = i == activeLayerIndex;
                          return GestureDetector(
                            onTap: () => setState(() => activeLayerIndex = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: isActive ? waveLayers[i].color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: isActive ? waveLayers[i].color : Colors.transparent, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(radius: 6, backgroundColor: waveLayers[i].color),
                                  const SizedBox(width: 8),
                                  Text("Layer ${i + 1}", style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
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
                              Text("Editing Layer ${activeLayerIndex + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              const Spacer(),
                              IconButton(icon: const Icon(Icons.restore, size: 20, color: Colors.white54), onPressed: () => _resetLayer(activeLayerIndex)),
                              IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: waveLayers.length > 1 ? () => _deleteLayer(activeLayerIndex) : null),
                            ],
                          ),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              _buildModernDropdown("TYPE", activeLayer.type, availableLineTypes, (val) { setState(() => activeLayer.type = val!); _generateInstantPreview(); }),
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
                          
                          const SizedBox(height: 20),
                          
                          // NEW: Editable white sliders!
                          EditableSliderRow(label: "Vertical Position", value: activeLayer.verticalPosition, min: 0, max: 1920, onChanged: (v) => setState(() => activeLayer.verticalPosition = v), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: "Amplitude (Height)", value: activeLayer.amplitude, min: 0, max: 300, onChanged: (v) => setState(() => activeLayer.amplitude = v), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: "Frequency", value: activeLayer.frequency, min: 1, max: 20, onChanged: (v) => setState(() => activeLayer.frequency = v), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: "Rotation Angle", value: activeLayer.rotation, min: -180, max: 180, onChanged: (v) => setState(() => activeLayer.rotation = v), onChangeEnd: _generateInstantPreview),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- GLOBAL SETTINGS CARD ---
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Global Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Layer Transparency", style: TextStyle(color: Colors.white, fontSize: 14)),
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
// NEW: EDITABLE SLIDER COMPONENT
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
        _controller.text = widget.value.toInt().toString(); // Reset if left empty
      }
    });
  }

  @override
  void didUpdateWidget(EditableSliderRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync text field when slider is dragged, but not while typing
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
      widget.onChangeEnd(); // Trigger image regeneration
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
            
            // Editable Number Input
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
            activeTrackColor: Colors.white, // FORCED WHITE
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
              _controller.text = v.toInt().toString(); // Live update text field
              widget.onChanged(v);
            },
            onChangeEnd: (_) => widget.onChangeEnd(),
          ),
        ),
      ],
    );
  }
}