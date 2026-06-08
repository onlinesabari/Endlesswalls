import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

import '../services/emoji_engine.dart';
import '../services/wallpaper_settings.dart';
import 'full_screen_preview.dart';
import '../utils/wallpaper_actions.dart';
import '../utils/color_picker_helper.dart';

class EmojiStudio extends StatefulWidget {
  const EmojiStudio({Key? key}) : super(key: key);

  @override
  State<EmojiStudio> createState() => _EmojiStudioState();
}

class _EmojiStudioState extends State<EmojiStudio> {
  // --- STATE VARIABLES ---
  List<String> selectedEmojis = [];
  bool isApplying = false; 
  bool _isGenerating = false;

  double rows = 12, columns = 6, baseSize = 80, rotation = 0, itemPadding = 20;
  double centerItemSize = 150.0;
  String layoutStyle = 'grid',
      patternStyle = 'sequential',
      rotationStyle = 'alternating',
      sizeStyle = 'uniform';

  // --- ADVANCED LAYOUT STATES ---
  double spiralSpacing = 30.0;
  bool spiralScaleOutward = false;
  bool honeycombFisheye = false;
  double waveAmplitude = 150.0;
  double waveFrequency = 10.0;
  bool waveFlowRotation = true;
  int waveCount = 1;

  File? currentImageFile;
  Color selectedBgColor = const Color(0xFF0F2027);

  final List<String> _emojiPool = ['😀', '😂', '🔥', '💀', '👽', '👻', '🍕', '🎉', '🌟', '🚀', '💖', '🌈', '🐱', '🐶', '😎', '👍', '👀', '✨', '🌍', '⚡'];

 @override
  void initState() {
    super.initState();
    // Move the delay here! This ensures the page opens smoothly.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _resetAll();
    });
  }

  // --- TARGETED RESETS ---
  void _resetAll() {
    setState(() {
      selectedEmojis = ['💀', '🔥'];
      selectedBgColor = const Color(0xFF0F2027);
      layoutStyle = 'grid'; patternStyle = 'sequential'; 
      rotationStyle = 'alternating'; sizeStyle = 'uniform';
      rows = 12; columns = 6; baseSize = 80; rotation = 0; itemPadding = 20;
      centerItemSize = 150.0; spiralSpacing = 30.0; spiralScaleOutward = false;
      honeycombFisheye = false; waveAmplitude = 150.0; waveFrequency = 10.0; 
      waveFlowRotation = true; waveCount = 1;
    });
    _generateInstantPreview();
  }

  /* void _resetEmojis() {
    setState(() => selectedEmojis = ['💀', '🔥']);
    _generateInstantPreview();
  } */

  void _resetLayout() {
    setState(() {
      layoutStyle = 'grid'; patternStyle = 'sequential'; 
      rotationStyle = 'alternating'; sizeStyle = 'uniform';
    });
    _generateInstantPreview();
  }

  void _resetColors() {
    setState(() => selectedBgColor = const Color(0xFF0F2027));
    _generateInstantPreview();
  }

  void _resetFineTuning() {
    setState(() {
      rows = 12; columns = 6; baseSize = 80; rotation = 0; itemPadding = 20;
      centerItemSize = 150.0;
      spiralSpacing = 30.0; spiralScaleOutward = false;
      honeycombFisheye = false;
      waveAmplitude = 150.0; waveFrequency = 10.0; waveFlowRotation = true; waveCount = 1;
    });
    _generateInstantPreview();
  }

  void _generateRandomArt() {
    final r = Random();
    int count = r.nextInt(3) + 2; 
    List<String> newEmojis = [];
    List<String> poolCopy = List.from(_emojiPool)..shuffle();
    for(int i = 0; i < count; i++) {
      newEmojis.add(poolCopy[i]);
    }

    setState(() {
      selectedEmojis = newEmojis;
      selectedBgColor = Color.fromARGB(255, r.nextInt(256), r.nextInt(256), r.nextInt(256));
      
      // FIX 3: Removed 'scatter' entirely, and changed nextInt(7) to nextInt(6) 
      // so the app doesn't crash from an Out Of Bounds array error!
      layoutStyle = ['grid', 'staggered', 'rangoli', 'spiral', 'honeycomb', 'wave'][r.nextInt(6)];
      patternStyle = ['random', 'sequential'][r.nextInt(2)];
      rotationStyle = ['fixed', 'random', 'alternating'][r.nextInt(3)];
      sizeStyle = ['uniform', 'random'][r.nextInt(2)];
    });
    _generateInstantPreview();
  }

  Future<void> _generateInstantPreview() async {
    if (_isGenerating || selectedEmojis.isEmpty || !mounted) return;
    setState(() => _isGenerating = true);

    try {
      WallpaperSettings sharedSettings = WallpaperSettings(
        bgColor: selectedBgColor,
        rows: rows.toInt(), columns: columns.toInt(),
        baseSize: baseSize, baseRotation: rotation, 
        layoutStyle: layoutStyle, patternStyle: patternStyle,
        rotationStyle: rotationStyle, sizeStyle: sizeStyle, padding: itemPadding,
      );

      File newFile = await EmojiEngine.generate(
        selectedEmojis, sharedSettings,
        centerItemSize: centerItemSize,
        spiralSpacing: spiralSpacing, spiralScaleOutward: spiralScaleOutward,
        honeycombFisheye: honeycombFisheye, waveAmplitude: waveAmplitude,
        waveFrequency: waveFrequency, waveFlowRotation: waveFlowRotation, waveCount: waveCount,
      );

      if (mounted) setState(() => currentImageFile = newFile);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showAddEmojiDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add an Emoji', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLength: 1, // Prevents typing long text
          style: const TextStyle(fontSize: 32),
          decoration: const InputDecoration(hintText: '😀', border: InputBorder.none, counterText: ""),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (controller.text.trim().isNotEmpty && selectedEmojis.length < 5) {
                setState(() => selectedEmojis.add(controller.text.trim()));
                _generateInstantPreview();
              }
              Navigator.pop(context);
            },
            child: const Text('ADD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEmojiEditOptions(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.white),
                  title: const Text('Change Emoji', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    _showEditEmojiDialog(index); // Open text dialog
                  },
                ),
                // Only show delete if they have more than 1 emoji!
                if (selectedEmojis.length > 1) 
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    title: const Text('Delete Emoji', style: TextStyle(color: Colors.redAccent)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => selectedEmojis.removeAt(index));
                      _generateInstantPreview();
                    },
                  ),
              ],
            ),
          ),
        );
      }
    );
  }

  void _showEditEmojiDialog(int index) {
    TextEditingController controller = TextEditingController(text: selectedEmojis[index]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Emoji', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLength: 1, // Prevents typing long text
          style: const TextStyle(fontSize: 32),
          decoration: const InputDecoration(border: InputBorder.none, counterText: ""),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => selectedEmojis[index] = controller.text.trim());
                _generateInstantPreview();
              }
              Navigator.pop(context);
            },
            child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdvancedMath = ['rangoli', 'spiral', 'honeycomb', 'wave'].contains(layoutStyle);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Emoji Studio', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
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

                    // --- CARD 1: EMOJI POOL ---
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Selected Emojis", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Row(
                                children: [
                                  if (selectedEmojis.length < 5)
                                    GestureDetector(
                                      onTap: _showAddEmojiDialog,
                                      child: const CircleAvatar(radius: 14, backgroundColor: Colors.white12, child: Icon(Icons.add, color: Colors.white, size: 18)),
                                    ),
                                  
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // THE UPDATED WRAP WITH PENCIL ICONS
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: selectedEmojis.asMap().entries.map((entry) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(entry.value, style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 8),
                                  // The new sleek Blue Pencil button
                                  GestureDetector(
                                    onTap: () => _showEmojiEditOptions(entry.key),
                                    child: const CircleAvatar(
                                      radius: 12, 
                                      backgroundColor: Colors.blueAccent, 
                                      child: Icon(Icons.edit, size: 12, color: Colors.white)
                                    ),
                                  )
                                ],
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- CARD 2: LAYOUT & PATTERN ---
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Layout & Styling", _resetLayout),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildModernDropdown("LAYOUT", layoutStyle, ['grid', 'staggered', 'rangoli', 'spiral', 'honeycomb', 'wave'], (v) { setState(() => layoutStyle = v!); _generateInstantPreview(); }),
                              const SizedBox(width: 16),
                              _buildModernDropdown("PATTERN", patternStyle, ['random', 'sequential'], (v) { setState(() => patternStyle = v!); _generateInstantPreview(); }),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              isAdvancedMath
                                  ? _buildDisabledDropdown("ROTATION", "AUTO (MATH)")
                                  : _buildModernDropdown("ROTATION", rotationStyle, ['fixed', 'random', 'alternating'], (v) { setState(() => rotationStyle = v!); _generateInstantPreview(); }),
                              const SizedBox(width: 16),
                              isAdvancedMath
                                  ? _buildDisabledDropdown("SIZE", "AUTO (MATH)")
                                  : _buildModernDropdown("SIZE", sizeStyle, ['uniform', 'random'], (v) { setState(() => sizeStyle = v!); _generateInstantPreview(); }),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- CARD 3: GLOBAL SETTINGS ---
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Colors & Background", _resetColors),
                          const SizedBox(height: 16),
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

                    const SizedBox(height: 24),

                    // --- CARD 4: FINE TUNING ---
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Fine Tuning", _resetFineTuning),
                          const SizedBox(height: 8),
                          
                          // Advanced Toggles
                          if (layoutStyle == 'spiral')
                            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text("Scale Outward (3D Effect)", style: TextStyle(color: Colors.white, fontSize: 14)), activeColor: Colors.tealAccent, value: spiralScaleOutward, onChanged: (v) { setState(() => spiralScaleOutward = v); _generateInstantPreview(); }),
                          if (layoutStyle == 'honeycomb')
                            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text("Fisheye Lens Distortion", style: TextStyle(color: Colors.white, fontSize: 14)), activeColor: Colors.tealAccent, value: honeycombFisheye, onChanged: (v) { setState(() => honeycombFisheye = v); _generateInstantPreview(); }),
                          if (layoutStyle == 'wave')
                            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text("Follow Wave Curve", style: TextStyle(color: Colors.white, fontSize: 14)), activeColor: Colors.tealAccent, value: waveFlowRotation, onChanged: (v) { setState(() => waveFlowRotation = v); _generateInstantPreview(); }),

                          // Grid / Count Sliders (Hidden for Rangoli)
                          if (layoutStyle != 'rangoli') ...[
                            EditableSliderRow(label: layoutStyle == 'spiral' || layoutStyle == 'wave' ? "Item Count Density" : "Rows", value: rows, min: 1, max: 30, onChanged: (v) => setState(() => rows = v), onChangeEnd: _generateInstantPreview),
                            EditableSliderRow(label: layoutStyle == 'spiral' || layoutStyle == 'wave' ? "Item Count Multiplier" : "Columns", value: columns, min: 1, max: 20, onChanged: (v) => setState(() => columns = v), onChangeEnd: _generateInstantPreview),
                          ],

                          // Rangoli Center Size
                          if (layoutStyle == 'rangoli')
                            EditableSliderRow(label: "Center Emoji Size", value: centerItemSize, min: 50, max: 800, onChanged: (v) => setState(() => centerItemSize = v), onChangeEnd: _generateInstantPreview),

                          // Advanced Sliders
                          if (layoutStyle == 'spiral')
                            EditableSliderRow(label: "Spiral Tightness", value: spiralSpacing, min: 5, max: 100, onChanged: (v) => setState(() => spiralSpacing = v), onChangeEnd: _generateInstantPreview),

                          if (layoutStyle == 'wave') ...[
                            EditableSliderRow(label: "Number of Waves", value: waveCount.toDouble(), min: 1, max: 5, onChanged: (v) => setState(() => waveCount = v.toInt()), onChangeEnd: _generateInstantPreview),
                            EditableSliderRow(label: "Wave Width (Amplitude)", value: waveAmplitude, min: 10, max: 500, onChanged: (v) => setState(() => waveAmplitude = v), onChangeEnd: _generateInstantPreview),
                            EditableSliderRow(label: "Curve Amount (Frequency)", value: waveFrequency, min: 1, max: 50, onChanged: (v) => setState(() => waveFrequency = v), onChangeEnd: _generateInstantPreview),
                          ],

                          // Universal Base Size / Padding Sliders
                          EditableSliderRow(label: layoutStyle == 'rangoli' ? "Ripple Emoji Size" : "Base Size", value: baseSize, min: 20, max: 300, onChanged: (v) => setState(() => baseSize = v), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: layoutStyle == 'rangoli' ? "Ripple Gap" : "Item Padding", value: itemPadding, min: 0, max: 200, onChanged: (v) => setState(() => itemPadding = v), onChangeEnd: _generateInstantPreview),
                          
                          // Rotation Slider
                          if (rotationStyle != 'random')
                            EditableSliderRow(label: layoutStyle == 'rangoli' ? "Spin / Angle" : "Global Angle", value: rotation, min: -180, max: 180, onChanged: (v) => setState(() => rotation = v), onChangeEnd: _generateInstantPreview),
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

  Widget _buildSectionHeader(String title, VoidCallback onReset) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        GestureDetector(
          onTap: onReset,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.refresh, color: Colors.white54, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDisabledDropdown(String title, String text) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
            child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white38, fontWeight: FontWeight.w600)),
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
    // The slider only cares about its own text field value
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
      widget.onChanged(clamped); // Updates Parent State
      widget.onChangeEnd();      // Triggers Parent Engine
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