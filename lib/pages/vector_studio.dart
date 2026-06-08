import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

import '../services/icon_engine.dart';
import '../services/wallpaper_settings.dart';
import 'full_screen_preview.dart';
import '../widgets/icon_picker_menu.dart';
import '../utils/wallpaper_actions.dart';
import '../utils/color_picker_helper.dart';

class VectorStudio extends StatefulWidget {
  const VectorStudio({Key? key}) : super(key: key);

  @override
  State<VectorStudio> createState() => _VectorStudioState();
}

class _VectorStudioState extends State<VectorStudio> {
  List<IconData> selectedIcons = [];
  bool isApplying = false;
  bool _isGenerating = false;

  // Slider States
  double rows = 12, columns = 6, baseSize = 80, rotation = 0, itemPadding = 20;
  double centerItemSize = 150.0;

  double spiralSpacing = 30.0;
  bool spiralScaleOutward = false;
  bool honeycombFisheye = false;
  double waveAmplitude = 150.0;
  double waveFrequency = 10.0;
  bool waveFlowRotation = true;
  int waveCount = 1;

  // Dropdown States
  String layoutStyle = 'grid';
  String patternStyle = 'sequential';
  String rotationStyle = 'alternating';
  String sizeStyle = 'uniform';
  String iconFillStyle = 'solid';
  String shadowStyle = 'none';
  String colorMode = 'single';

  // Color States
  List<Color> activeIconColors = [];
  Color selectedBgColor = const Color(0xFF0F2027);

  File? currentImageFile;

  final List<IconData> _iconPool = [
    Icons.bolt,
    Icons.local_fire_department,
    Icons.star,
    Icons.favorite,
    Icons.water_drop,
    Icons.air,
    Icons.public,
    Icons.rocket_launch,
    Icons.extension,
    Icons.toys,
    Icons.ac_unit,
    Icons.spa,
    Icons.dark_mode,
    Icons.lightbulb,
    Icons.music_note,
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _resetAll();
    });
  }

  // --- TARGETED RESETS ---
  void _resetAll() {
    setState(() {
      selectedIcons = [Icons.bolt, Icons.local_fire_department];
      selectedBgColor = const Color(0xFF0F2027);
      activeIconColors = [const Color(0xFFE9C46A), const Color(0xFFFF007F)];
      rows = 12;
      columns = 6;
      baseSize = 80;
      rotation = 0;
      itemPadding = 20;
      centerItemSize = 150.0;
      spiralSpacing = 30.0;
      spiralScaleOutward = false;
      honeycombFisheye = false;
      waveAmplitude = 150.0;
      waveFrequency = 10.0;
      waveFlowRotation = true;
      waveCount = 1;
      layoutStyle = 'grid';
      patternStyle = 'sequential';
      rotationStyle = 'alternating';
      sizeStyle = 'uniform';
      iconFillStyle = 'solid';
      shadowStyle = 'none';
      colorMode = 'single';
    });
    _generateInstantPreview();
  }

  /* void _resetIcons() {
    setState(() => selectedIcons = [Icons.bolt, Icons.local_fire_department]);
    _generateInstantPreview();
  } */

  void _resetLayout() {
    setState(() {
      layoutStyle = 'grid';
      patternStyle = 'sequential';
      rotationStyle = 'alternating';
      sizeStyle = 'uniform';
      iconFillStyle = 'solid';
      shadowStyle = 'none';
    });
    _generateInstantPreview();
  }

  void _resetColors() {
    setState(() {
      selectedBgColor = const Color(0xFF0F2027);
      activeIconColors = [const Color(0xFFE9C46A), const Color(0xFFFF007F)];
      colorMode = 'single';
    });
    _generateInstantPreview();
  }

  void _resetFineTuning() {
    setState(() {
      rows = 12;
      columns = 6;
      baseSize = 80;
      rotation = 0;
      itemPadding = 20;
      centerItemSize = 150.0;
      spiralSpacing = 30.0;
      spiralScaleOutward = false;
      honeycombFisheye = false;
      waveAmplitude = 150.0;
      waveFrequency = 10.0;
      waveFlowRotation = true;
      waveCount = 1;
    });
    _generateInstantPreview();
  }

  void _generateRandomArt() {
    final r = Random();
    int count = r.nextInt(3) + 2;
    List<IconData> newIcons = [];
    List<IconData> poolCopy = List.from(_iconPool)..shuffle();
    for (int i = 0; i < count; i++) {
      newIcons.add(poolCopy[i]);
    }

    int colorCount = r.nextInt(3) + 2;
    List<Color> newColors = [];
    for (int i = 0; i < colorCount; i++) {
      newColors.add(
        Color.fromARGB(255, r.nextInt(256), r.nextInt(256), r.nextInt(256)),
      );
    }

    setState(() {
      selectedIcons = newIcons;
      activeIconColors = newColors;
      selectedBgColor = Color.fromARGB(
        255,
        r.nextInt(150),
        r.nextInt(150),
        r.nextInt(150),
      );
      layoutStyle = [
        'grid',
        'staggered',
        'rangoli',
        'spiral',
        'honeycomb',
        'wave',
      ][r.nextInt(6)];
      patternStyle = ['random', 'sequential'][r.nextInt(2)];
      rotationStyle = ['fixed', 'random', 'alternating'][r.nextInt(3)];
      sizeStyle = ['uniform', 'random'][r.nextInt(2)];
      iconFillStyle = ['solid', 'outline', 'mixed'][r.nextInt(3)];
      shadowStyle = [
        'none',
        'neon_glow',
        'drop_shadow',
        'retro_offset',
      ][r.nextInt(4)];
      colorMode = ['single', 'multi_random', 'multi_alternating'][r.nextInt(3)];
    });
    _generateInstantPreview();
  }

  void _addIconColor() {
    if (activeIconColors.length >= 8) return;
    final r = Random();
    Color randomColor = Color.fromARGB(
      255,
      r.nextInt(256),
      r.nextInt(256),
      r.nextInt(256),
    );
    setState(() => activeIconColors.add(randomColor));
    _generateInstantPreview();
  }

  void _showIconEditOptions(int index) {
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
                IconPickerMenu(
                  onIconSelected: (newIcon) {
                    Navigator.pop(context); 
                    setState(() => selectedIcons[index] = newIcon);
                    _generateInstantPreview();
                  },
                  child: const ListTile(
                    leading: Icon(Icons.edit, color: Colors.white),
                    title: Text('Change Icon', style: TextStyle(color: Colors.white)),
                  ),
                ),
                if (selectedIcons.length > 1) 
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    title: const Text('Delete Icon', style: TextStyle(color: Colors.redAccent)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => selectedIcons.removeAt(index));
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

  Future<void> _generateInstantPreview() async {
    if (_isGenerating || activeIconColors.isEmpty || !mounted) return;
    setState(() => _isGenerating = true);

    try {
      WallpaperSettings sharedSettings = WallpaperSettings(
        bgColor: selectedBgColor,
        rows: rows.toInt(),
        columns: columns.toInt(),
        baseSize: baseSize,
        baseRotation: rotation,
        layoutStyle: layoutStyle,
        patternStyle: patternStyle,
        rotationStyle: rotationStyle,
        sizeStyle: sizeStyle,
        padding: itemPadding,
      );

      File newFile = await IconEngine.generate(
        selectedIcons,
        activeIconColors,
        sharedSettings,
        iconFillStyle: iconFillStyle,
        shadowStyle: shadowStyle,
        colorMode: colorMode,
        centerItemSize: centerItemSize,
        spiralSpacing: spiralSpacing,
        spiralScaleOutward: spiralScaleOutward,
        honeycombFisheye: honeycombFisheye,
        waveAmplitude: waveAmplitude,
        waveFrequency: waveFrequency,
        waveFlowRotation: waveFlowRotation,
        waveCount: waveCount,
      );

      if (mounted) setState(() => currentImageFile = newFile);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Vector Studio',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: "Reset All",
            onPressed: _resetAll,
          ),
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
                          ? const SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.greenAccent,
                              ),
                            )
                          : const Icon(
                              Icons.check_circle,
                              color: Colors.greenAccent,
                              size: 26,
                            ),
                      onTap: isApplying || selectedIcons.isEmpty
                          ? null
                          : () => WallpaperActions.showApplyMenu(
                              context: context,
                              imageFile: currentImageFile,
                              onLoading: (val) =>
                                  setState(() => isApplying = val),
                            ),
                    ),
                  ),

                  Flexible(
                    child: AspectRatio(
                      aspectRatio: 1080 / 1920,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: currentImageFile == null
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : Image.file(
                                  currentImageFile!,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildGlassButton(
                      icon: Icons.fullscreen,
                      color: Colors.white,
                      onTap: () {
                        if (currentImageFile != null)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenPreview(
                                imageFile: currentImageFile!,
                              ),
                            ),
                          );
                      },
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
                      onTap: _generateRandomArt,
                    ),
                    const SizedBox(height: 28),

                    // --- CARD 1: ICONS ---
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // NEW: The EmojiStudio style header with the Add (+) and Refresh buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Selected Icons", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Row(
                                children: [
                                  // The circular + button wrapped in your IconPickerMenu!
                                  if (selectedIcons.length < 5)
                                    IconPickerMenu(
                                      onIconSelected: (icon) { setState(() => selectedIcons.add(icon)); _generateInstantPreview(); },
                                      child: const CircleAvatar(radius: 14, backgroundColor: Colors.white12, child: Icon(Icons.add, color: Colors.white, size: 18)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // NEW: Clean Wrap widget without the bulky Add button at the end
                          Wrap(
                            spacing: 12, runSpacing: 12,
                            children: selectedIcons.asMap().entries.map((entry) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(entry.value, color: activeIconColors.isNotEmpty ? activeIconColors.first : Colors.white, size: 22),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _showIconEditOptions(entry.key),
                                    child: const CircleAvatar(
                                      radius: 12, 
                                      backgroundColor: Colors.blueAccent, 
                                      child: Icon(Icons.edit, size: 12, color: Colors.white)
                                    )
                                  )
                                ],
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- CARD 2: LAYOUT & STYLING ---
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Layout & Details", _resetLayout),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildModernDropdown(
                                "LAYOUT",
                                layoutStyle,
                                [
                                  'grid',
                                  'staggered',
                                  'rangoli',
                                  'spiral',
                                  'honeycomb',
                                  'wave',
                                ],
                                (v) {
                                  setState(() => layoutStyle = v!);
                                  _generateInstantPreview();
                                },
                              ),
                              const SizedBox(width: 16),
                              _buildModernDropdown(
                                "PATTERN",
                                patternStyle,
                                ['random', 'sequential'],
                                (v) {
                                  setState(() => patternStyle = v!);
                                  _generateInstantPreview();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              // SMART ROTATION DROPDOWN
                              [
                                    'rangoli',
                                    'spiral',
                                    'honeycomb',
                                    'wave',
                                  ].contains(layoutStyle)
                                  ? _buildDisabledDropdown(
                                      "ROTATION",
                                      "AUTO (MATH)",
                                    )
                                  : _buildModernDropdown(
                                      "ROTATION",
                                      rotationStyle,
                                      ['fixed', 'random', 'alternating'],
                                      (v) {
                                        setState(() => rotationStyle = v!);
                                        _generateInstantPreview();
                                      },
                                    ),

                              const SizedBox(width: 16),

                              // SMART SIZE DROPDOWN
                              [
                                    'rangoli',
                                    'spiral',
                                    'honeycomb',
                                    'wave',
                                  ].contains(layoutStyle)
                                  ? _buildDisabledDropdown(
                                      "SIZE",
                                      "AUTO (MATH)",
                                    )
                                  : _buildModernDropdown(
                                      "SIZE",
                                      sizeStyle,
                                      ['uniform', 'random'],
                                      (v) {
                                        setState(() => sizeStyle = v!);
                                        _generateInstantPreview();
                                      },
                                    ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildModernDropdown(
                                "ICON FILL",
                                iconFillStyle,
                                ['solid', 'outline', 'mixed'],
                                (v) {
                                  setState(() => iconFillStyle = v!);
                                  _generateInstantPreview();
                                },
                              ),
                              const SizedBox(width: 16),
                              _buildModernDropdown(
                                "SHADOW",
                                shadowStyle,
                                [
                                  'none',
                                  'neon_glow',
                                  'drop_shadow',
                                  'retro_offset',
                                ],
                                (v) {
                                  setState(() => shadowStyle = v!);
                                  _generateInstantPreview();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- CARD 3: COLORS ---
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            "Colors & Palettes",
                            _resetColors,
                          ),
                          const SizedBox(height: 16),

                          _buildPaletteSection(
                            title: "Icon Palette",
                            mode: colorMode,
                            colors: activeIconColors,
                            onModeChanged: (v) {
                              setState(() => colorMode = v!);
                              _generateInstantPreview();
                            },
                            onAdd: _addIconColor,
                            onColorEdit: (idx, c) =>
                                setState(() => activeIconColors[idx] = c),
                            onDelete: (idx) =>
                                setState(() => activeIconColors.removeAt(idx)),
                          ),

                          const Divider(color: Colors.white10, height: 32),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Canvas Background",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => ColorPickerHelper.show(
                                  context: context,
                                  initialColor: selectedBgColor,
                                  onColorChanged: (c) {
                                    setState(() => selectedBgColor = c);
                                    _generateInstantPreview();
                                  },
                                ),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: selectedBgColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- CARD 4: GRID & SCALING SLIDERS ---
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Fine Tuning", _resetFineTuning),
                          const SizedBox(height: 8),

                          // Advanced Toggles
                          if (layoutStyle == 'spiral')
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                "Scale Outward (3D Effect)",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              activeColor: Colors.tealAccent,
                              value: spiralScaleOutward,
                              onChanged: (v) {
                                setState(() => spiralScaleOutward = v);
                                _generateInstantPreview();
                              },
                            ),
                          if (layoutStyle == 'honeycomb')
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                "Fisheye Lens Distortion",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              activeColor: Colors.tealAccent,
                              value: honeycombFisheye,
                              onChanged: (v) {
                                setState(() => honeycombFisheye = v);
                                _generateInstantPreview();
                              },
                            ),
                          if (layoutStyle == 'wave')
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                "Follow Wave Curve",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              activeColor: Colors.tealAccent,
                              value: waveFlowRotation,
                              onChanged: (v) {
                                setState(() => waveFlowRotation = v);
                                _generateInstantPreview();
                              },
                            ),

                          // Grid / Count Sliders (Hidden for Rangoli)
                          if (layoutStyle != 'rangoli') ...[
                            EditableSliderRow(
                              label:
                                  layoutStyle == 'spiral' ||
                                      layoutStyle == 'wave'
                                  ? "Item Count Density"
                                  : "Rows",
                              value: rows,
                              min: 1,
                              max: 30,
                              onChanged: (v) => setState(() => rows = v),
                              onChangeEnd: _generateInstantPreview,
                            ),
                            EditableSliderRow(
                              label:
                                  layoutStyle == 'spiral' ||
                                      layoutStyle == 'wave'
                                  ? "Item Count Multiplier"
                                  : "Columns",
                              value: columns,
                              min: 1,
                              max: 20,
                              onChanged: (v) => setState(() => columns = v),
                              onChangeEnd: _generateInstantPreview,
                            ),
                          ],

                          // Rangoli Center Size
                          if (layoutStyle == 'rangoli')
                            EditableSliderRow(
                              label: "Center Icon Size",
                              value: centerItemSize,
                              min: 50,
                              max: 800,
                              onChanged: (v) =>
                                  setState(() => centerItemSize = v),
                              onChangeEnd: _generateInstantPreview,
                            ),

                          // Missing Advanced Sliders added here!
                          if (layoutStyle == 'spiral')
                            EditableSliderRow(
                              label: "Spiral Tightness",
                              value: spiralSpacing,
                              min: 5,
                              max: 100,
                              onChanged: (v) =>
                                  setState(() => spiralSpacing = v),
                              onChangeEnd: _generateInstantPreview,
                            ),

                          if (layoutStyle == 'wave') ...[
                            EditableSliderRow(
                              label: "Number of Waves",
                              value: waveCount.toDouble(),
                              min: 1,
                              max: 5,
                              onChanged: (v) =>
                                  setState(() => waveCount = v.toInt()),
                              onChangeEnd: _generateInstantPreview,
                            ),
                            EditableSliderRow(
                              label: "Wave Width (Amplitude)",
                              value: waveAmplitude,
                              min: 10,
                              max: 500,
                              onChanged: (v) =>
                                  setState(() => waveAmplitude = v),
                              onChangeEnd: _generateInstantPreview,
                            ),
                            EditableSliderRow(
                              label: "Curve Amount (Frequency)",
                              value: waveFrequency,
                              min: 1,
                              max: 50,
                              onChanged: (v) =>
                                  setState(() => waveFrequency = v),
                              onChangeEnd: _generateInstantPreview,
                            ),
                          ],

                          // Universal Base Size / Padding Sliders
                          EditableSliderRow(
                            label: layoutStyle == 'rangoli'
                                ? "Ripple Icon Size"
                                : "Base Size",
                            value: baseSize,
                            min: 20,
                            max: 300,
                            onChanged: (v) => setState(() => baseSize = v),
                            onChangeEnd: _generateInstantPreview,
                          ),
                          EditableSliderRow(
                            label: layoutStyle == 'rangoli'
                                ? "Ripple Gap"
                                : "Item Padding",
                            value: itemPadding,
                            min: 0,
                            max: 200,
                            onChanged: (v) => setState(() => itemPadding = v),
                            onChangeEnd: _generateInstantPreview,
                          ),

                          // Rotation Slider
                          if (rotationStyle != 'random')
                            EditableSliderRow(
                              label: layoutStyle == 'rangoli'
                                  ? "Spin / Angle"
                                  : "Global Angle",
                              value: rotation,
                              min: -180,
                              max: 180,
                              onChanged: (v) => setState(() => rotation = v),
                              onChangeEnd: _generateInstantPreview,
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

  Widget _buildPaletteSection({
    required String title,
    required String mode,
    required List<Color> colors,
    required Function(String?) onModeChanged,
    required VoidCallback onAdd,
    required Function(int, Color) onColorEdit,
    required Function(int) onDelete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildModernDropdown("COLOR MODE", mode, [
              'single',
              'multi_random',
              'multi_alternating',
            ], onModeChanged),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: colors.length + (mode != 'single' ? 1 : 0),
            itemBuilder: (ctx, index) {
              if (index == colors.length) {
                return GestureDetector(
                  onTap: onAdd,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 16, top: 5),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.add, color: Colors.white54),
                    ),
                  ),
                );
              }
              return _buildCircularSwatch(
                colors[index],
                () => ColorPickerHelper.show(
                  context: context,
                  initialColor: colors[index],
                  onColorChanged: (c) {
                    onColorEdit(index, c);
                    _generateInstantPreview();
                  },
                ),
                () => onDelete(index),
                colors.length > 1,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCircularSwatch(
    Color color,
    VoidCallback onTap,
    VoidCallback onDelete,
    bool showDelete,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 5),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 18),
            ),
          ),
          if (showDelete)
            Positioned(
              top: -5,
              right: -5,
              child: GestureDetector(
                onTap: () {
                  onDelete();
                  _generateInstantPreview();
                },
                child: const CircleAvatar(
                  radius: 11,
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onReset) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        GestureDetector(
          onTap: onReset,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.refresh, color: Colors.white54, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton({
    IconData? icon,
    Widget? customWidget,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: customWidget ?? Icon(icon, color: color, size: 26),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE94057).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildModernDropdown(
    String title,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: const Color(0xFF2C2C2E),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white54,
                ),
                items: options
                    .map(
                      (opt) => DropdownMenuItem(
                        value: opt,
                        child: Text(
                          opt.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledDropdown(String title, String text) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white38,
                fontWeight: FontWeight.w600,
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
  final bool isDecimal;
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

  String _formatValue(double v) =>
      widget.isDecimal ? v.toStringAsFixed(2) : v.toInt().toString();

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
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              width: 50,
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
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
