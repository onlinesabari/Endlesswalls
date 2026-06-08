import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:path_provider/path_provider.dart';

import '../services/face_engine.dart';
import '../services/wallpaper_settings.dart';
import '../utils/wallpaper_actions.dart';
import '../utils/color_picker_helper.dart';
import 'full_screen_preview.dart';

class FaceStudio extends StatefulWidget {
  const FaceStudio({Key? key}) : super(key: key);

  @override
  State<FaceStudio> createState() => _FaceStudioState();
}

class _FaceStudioState extends State<FaceStudio> {
  List<FaceLayer> faces = [];
  bool isApplying = false;
  bool _isGenerating = false;
  double centerFaceSize = 350.0;
  File? currentImageFile;

  // --- PALETTE STATE ---
  Color canvasBgColor = const Color(0xFF0F2027);
  List<Color> activeFaceColors = [Colors.blueAccent, Colors.purpleAccent];
  List<Color> activeStrokeColors = [Colors.white, Colors.amber];
  String colorMode = 'single'; // This single mode now rules both palettes!

  // --- LAYOUT & STYLE STATE ---
  double rows = 12, columns = 6, baseSize = 150, rotation = 0, itemPadding = 20;
  String layoutStyle = 'grid', patternStyle = 'sequential', rotationStyle = 'fixed', sizeStyle = 'uniform';
  String faceBgShape = 'circle'; 
  bool enableStroke = false;
  double strokeThickness = 15.0;
  double spiralSpacing = 50.0;
  bool spiralScaleOutward = false;
  bool honeycombFisheye = false;
  double waveAmplitude = 150.0;
  double waveFrequency = 10.0;
  bool waveFlowRotation = true;
  int waveCount = 1;
  bool keepUpright = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _generateInstantPreview();
  }

  void _resetAll() {
    setState(() {
      faces.clear();
      canvasBgColor = const Color(0xFF0F2027);
      activeFaceColors = [Colors.blueAccent, Colors.purpleAccent];
      activeStrokeColors = [Colors.white, Colors.amber];
      colorMode = 'single';
      rows = 12; columns = 6; baseSize = 150; rotation = 0; itemPadding = 20;
      layoutStyle = 'rangoli'; patternStyle = 'sequential'; rotationStyle = 'fixed'; sizeStyle = 'uniform';
      faceBgShape = 'circle'; enableStroke = false; strokeThickness = 15.0; spiralSpacing = 50.0;
      currentImageFile = null;
    });
  }

  /* void _resetFaces() {
    setState(() {
      faces.clear();
      currentImageFile = null;
    });
    _generateInstantPreview();
  }*/

  void _resetLayout() {
    setState(() {
      layoutStyle = 'rangoli'; patternStyle = 'sequential'; 
      rotationStyle = 'fixed'; sizeStyle = 'uniform';
    });
    _generateInstantPreview();
  }

  void _resetColors() {
    setState(() {
      canvasBgColor = const Color(0xFF0F2027);
      activeFaceColors = [Colors.blueAccent, Colors.purpleAccent];
      activeStrokeColors = [Colors.white, Colors.amber];
      colorMode = 'single';
      faceBgShape = 'circle'; 
      enableStroke = false; 
      strokeThickness = 15.0;
    });
    _generateInstantPreview();
  }

  void _resetFineTuning() {
    setState(() {
      rows = 12; columns = 6; baseSize = 80; rotation = 0; itemPadding = 20;
      centerFaceSize = 350.0;
      spiralSpacing = 50.0; spiralScaleOutward = false;
      honeycombFisheye = false;
      waveAmplitude = 150.0; waveFrequency = 10.0; waveFlowRotation = true; waveCount = 1;
    });
    _generateInstantPreview();
  }
  

  Color _getRandomColor() {
    final r = Random();
    return Color.fromARGB(255, r.nextInt(256), r.nextInt(256), r.nextInt(256));
  }

  void _addPaletteColor() {
    if (activeFaceColors.length >= 8) return;
    setState(() => activeFaceColors.add(_getRandomColor()));
    _generateInstantPreview();
  }

  void _addStrokePaletteColor() {
    if (activeStrokeColors.length >= 8) return;
    setState(() => activeStrokeColors.add(_getRandomColor()));
    _generateInstantPreview();
  }

  Future<void> _generateInstantPreview() async {
    if (_isGenerating || !mounted) return;
    setState(() => _isGenerating = true);

    try {
      WallpaperSettings sharedSettings = WallpaperSettings(
        bgColor: canvasBgColor, rows: rows.toInt(), columns: columns.toInt(),
        baseSize: baseSize, baseRotation: rotation, layoutStyle: layoutStyle,
        patternStyle: patternStyle, rotationStyle: rotationStyle, sizeStyle: sizeStyle, padding: itemPadding,
      );

      final file = await FaceEngine.generate(
        faces: faces, 
        config: sharedSettings,
        faceBgShape: faceBgShape,
        colorMode: colorMode, // Engine now uses this for both shape AND stroke!
        palette: activeFaceColors,
        strokePalette: activeStrokeColors,
        enableStroke: enableStroke,
        strokeThickness: strokeThickness,
        centerFaceSize: centerFaceSize,
        spiralSpacing: spiralSpacing,
        spiralScaleOutward: spiralScaleOutward,
        honeycombFisheye: honeycombFisheye,
        waveAmplitude: waveAmplitude,
        waveFrequency: waveFrequency,
        waveFlowRotation: waveFlowRotation,
        waveCount: waveCount,
        keepUpright: keepUpright,
      );
      
      if (!mounted) return;
      setState(() => currentImageFile = file);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // --- IMAGE PROCESSING ---
  Future<void> _pickAndCropImage({int? replaceIndex}) async {
    if (faces.length >= 5 && replaceIndex == null) return;
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'Crop Face', toolbarColor: Colors.black, toolbarWidgetColor: Colors.white, initAspectRatio: CropAspectRatioPreset.square, lockAspectRatio: true),
      ],
    );

    if (croppedFile == null) return;
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI is removing background...'), duration: Duration(seconds: 2)));

    File finalImage = await _removeBackground(File(croppedFile.path));

    setState(() {
      if (replaceIndex != null) {
        // We are replacing an image! Free the old one from memory first.
        faces[replaceIndex].decodedImage?.dispose();
        // Keep the user's old stroke and shape colors for the new face
        faces[replaceIndex] = FaceLayer(
          imageFile: finalImage, 
          bgColor: faces[replaceIndex].bgColor, 
          strokeColor: faces[replaceIndex].strokeColor
        );
      } else {
        // We are adding a brand new image.
        faces.add(FaceLayer(imageFile: finalImage, bgColor: activeFaceColors.first, strokeColor: Colors.white));
      }
    });
    _generateInstantPreview();
  }

  void _showFaceEditOptions(int index) {
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
                  leading: const Icon(Icons.image_search, color: Colors.white),
                  title: const Text('Change Image', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndCropImage(replaceIndex: index); // Trigger replace!
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Delete Image', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    // Free memory, then remove and refresh
                    faces[index].decodedImage?.dispose();
                    setState(() => faces.removeAt(index));
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

  Future<File> _removeBackground(File inputImage) async {
    final options = SubjectSegmenterOptions(enableForegroundBitmap: true, enableForegroundConfidenceMask: false, 
      enableMultipleSubjects: SubjectResultOptions(enableConfidenceMask: false, enableSubjectBitmap: false));
    final segmenter = SubjectSegmenter(options: options);
    try {
      final input = InputImage.fromFile(inputImage);
      final result = await segmenter.processImage(input);
      if (result.foregroundBitmap != null) {
        final tempDir = await getTemporaryDirectory(); 
        final finalFile = File('${tempDir.path}/bg_removed_${DateTime.now().millisecondsSinceEpoch}.png');
        await finalFile.writeAsBytes(result.foregroundBitmap!);
        return finalFile;
      }
    } finally {
      segmenter.close();
    }
    return inputImage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Face Studio", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
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
                      onTap: isApplying || faces.isEmpty ? null : () => WallpaperActions.showApplyMenu(context: context, imageFile: currentImageFile, onLoading: (val) => setState(() => isApplying = val)),
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
                            ? Container(color: canvasBgColor, child: const Center(child: Icon(Icons.face, size: 50, color: Colors.white24)))
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
                    
                    // --- CARD 1: FACES ---
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Your Faces", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              if (faces.length < 5) 
                                GestureDetector(
                                  onTap: _pickAndCropImage,
                                  child: const CircleAvatar(radius: 14, backgroundColor: Colors.white12, child: Icon(Icons.add, color: Colors.white, size: 18)),
                                ),
                            ],
                          ),
                          if (faces.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12, runSpacing: 12,
                              children: faces.asMap().entries.map((entry) => Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2)),
                                    child: CircleAvatar(radius: 28, backgroundImage: FileImage(entry.value.imageFile), backgroundColor: Colors.grey[800]),
                                  ),
                                  Positioned(
                                    top: -5, right: -5, 
                                    child: GestureDetector(
                                      onTap: () => _showFaceEditOptions(entry.key), 
                                      child: const CircleAvatar(
                                        radius: 12, 
                                        backgroundColor: Colors.blueAccent, 
                                        child: Icon(Icons.edit, size: 12, color: Colors.white)
                                      )
                                    )
                                  ),
                                ],
                              )).toList(),
                            ),
                          ] else ...[
                            const Padding(
                              padding: EdgeInsets.only(top: 16.0),
                              child: Text("Add a face to start generating!", style: TextStyle(color: Colors.white54, fontSize: 13)),
                            )
                          ],
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
                              _buildModernDropdown("LAYOUT", layoutStyle, ['grid','rangoli', 'spiral', 'honeycomb', 'wave','staggered'], (v) { setState(() => layoutStyle = v!); _generateInstantPreview(); }),
                              const SizedBox(width: 16),
                              _buildModernDropdown("PATTERN", patternStyle, ['random', 'sequential'], (v) { setState(() => patternStyle = v!); _generateInstantPreview(); }),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              // SMART ROTATION DROPDOWN
                              ['rangoli', 'spiral', 'honeycomb', 'wave'].contains(layoutStyle)
                                  ? _buildDisabledDropdown("ROTATION", "AUTO (MATH)")
                                  : _buildModernDropdown("ROTATION", rotationStyle, ['fixed', 'random', 'alternating'], (v) { setState(() => rotationStyle = v!); _generateInstantPreview(); }),
                              
                              const SizedBox(width: 16),
                              
                              // SMART SIZE DROPDOWN
                              ['rangoli', 'spiral', 'honeycomb', 'wave'].contains(layoutStyle)
                                  ? _buildDisabledDropdown("SIZE", "AUTO (MATH)")
                                  : _buildModernDropdown("SIZE", sizeStyle, ['uniform', 'random'], (v) { setState(() => sizeStyle = v!); _generateInstantPreview(); }),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- CARD 3: IMAGE STYLING & COLORS ---
                    _buildModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Colors & Shapes", _resetColors),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildModernDropdown("BG SHAPE", faceBgShape, ['none', 'circle', 'square'], (v) { setState(() => faceBgShape = v!); _generateInstantPreview(); }),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("CANVAS BG", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () => ColorPickerHelper.show(context: context, initialColor: canvasBgColor, onColorChanged: (c) { setState(() => canvasBgColor = c); _generateInstantPreview(); }),
                                      child: Container(height: 48, decoration: BoxDecoration(color: canvasBgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24))),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Shape Palette
                          if (faceBgShape != 'none') ...[
                            _buildPaletteSection(
                              title: "Shape Color Palette", 
                              mode: colorMode, 
                              colors: activeFaceColors,
                              onModeChanged: (v) { setState(() => colorMode = v!); _generateInstantPreview(); }, // Controls both now!
                              onAdd: _addPaletteColor,
                              onColorEdit: (idx, c) => setState(() => activeFaceColors[idx] = c),
                              onDelete: (idx) => setState(() => activeFaceColors.removeAt(idx)),
                            ),
                            const Divider(color: Colors.white10, height: 32),
                          ],

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Enable Stroke", style: TextStyle(color: Colors.white, fontSize: 14)),
                              Switch(
                                activeThumbColor: Colors.tealAccent,
                                value: enableStroke,
                                onChanged: (v) { setState(() => enableStroke = v); _generateInstantPreview(); },
                              ),
                            ],
                          ),

                          // Stroke Settings (No mode dropdown anymore)
                          if (enableStroke) ...[
                            const SizedBox(height: 16),
                            const Text("Stroke Color Palette", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: activeStrokeColors.length + (colorMode != 'single' ? 1 : 0),
                                itemBuilder: (ctx, index) {
                                  if (index == activeStrokeColors.length) {
                                    return GestureDetector(onTap: _addStrokePaletteColor, child: const Padding(padding: EdgeInsets.only(right: 16, top: 5), child: CircleAvatar(radius: 25, backgroundColor: Colors.white10, child: Icon(Icons.add, color: Colors.white54))));
                                  }
                                  return _buildCircularSwatch(activeStrokeColors[index], () => ColorPickerHelper.show(context: context, initialColor: activeStrokeColors[index], onColorChanged: (c) { setState(() => activeStrokeColors[index] = c); _generateInstantPreview(); }), () { setState(() => activeStrokeColors.removeAt(index)); _generateInstantPreview(); }, activeStrokeColors.length > 1);
                                },
                              ),
                            ),
                            EditableSliderRow(label: "Stroke Thickness", value: strokeThickness, min: 1, max: 50, onChanged: (v) => setState(() => strokeThickness = v), onChangeEnd: _generateInstantPreview),
                          ],
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
                          // Display the Upright toggle for Math Layouts!
                          if (['rangoli', 'spiral', 'honeycomb', 'wave'].contains(layoutStyle))
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero, 
                              title: const Text("Keep Images Upright", style: TextStyle(color: Colors.white, fontSize: 14)), 
                              activeColor: Colors.tealAccent, 
                              value: keepUpright, 
                              onChanged: (v) { setState(() => keepUpright = v); _generateInstantPreview(); }
                            ),
                            
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
                            EditableSliderRow(label: "Center Face Size", value: centerFaceSize, min: 50, max: 800, onChanged: (v) => setState(() => centerFaceSize = v), onChangeEnd: _generateInstantPreview),

                          // Missing Advanced Sliders added here!
                          if (layoutStyle == 'spiral')
                            EditableSliderRow(label: "Spiral Tightness", value: spiralSpacing, min: 5, max: 100, onChanged: (v) => setState(() => spiralSpacing = v), onChangeEnd: _generateInstantPreview),

                          if (layoutStyle == 'wave') ...[
                            EditableSliderRow(label: "Number of Waves", value: waveCount.toDouble(), min: 1, max: 5, onChanged: (v) => setState(() => waveCount = v.toInt()), onChangeEnd: _generateInstantPreview),
                            EditableSliderRow(label: "Wave Width (Amplitude)", value: waveAmplitude, min: 10, max: 500, onChanged: (v) => setState(() => waveAmplitude = v), onChangeEnd: _generateInstantPreview),
                            EditableSliderRow(label: "Curve Amount (Frequency)", value: waveFrequency, min: 1, max: 50, onChanged: (v) => setState(() => waveFrequency = v), onChangeEnd: _generateInstantPreview),
                          ],

                          // Universal Base Size / Padding Sliders
                          EditableSliderRow(label: layoutStyle == 'rangoli' ? "Ripple Face Size" : "Base Size", value: baseSize, min: 20, max: 600, onChanged: (v) => setState(() => baseSize = v), onChangeEnd: _generateInstantPreview),
                          EditableSliderRow(label: layoutStyle == 'rangoli' ? "Ripple Gap" : "Item Padding", value: itemPadding, min: 0, max: 400, onChanged: (v) => setState(() => itemPadding = v), onChangeEnd: _generateInstantPreview),
                          
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

  Widget _buildPaletteSection({
    required String title, required String mode, required List<Color> colors,
    required Function(String?) onModeChanged, required VoidCallback onAdd,
    required Function(int, Color) onColorEdit, required Function(int) onDelete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Row(children: [ _buildModernDropdown("COLOR MODE", mode, ['single', 'multi_random', 'multi_alternating'], onModeChanged) ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: colors.length + (mode != 'single' ? 1 : 0),
            itemBuilder: (ctx, index) {
              if (index == colors.length) {
                return GestureDetector(onTap: onAdd, child: const Padding(padding: EdgeInsets.only(right: 16, top: 5), child: CircleAvatar(radius: 25, backgroundColor: Colors.white10, child: Icon(Icons.add, color: Colors.white54))));
              }
              return _buildCircularSwatch(colors[index], () => ColorPickerHelper.show(context: context, initialColor: colors[index], onColorChanged: (c) { onColorEdit(index, c); _generateInstantPreview(); }), () => onDelete(index), colors.length > 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCircularSwatch(Color color, VoidCallback onTap, VoidCallback onDelete, bool showDelete) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 5),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(width: 50, height: 50, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2)), child: const Icon(Icons.edit, color: Colors.white, size: 18)),
          ),
          if (showDelete)
            Positioned(top: -5, right: -5, child: GestureDetector(onTap: () { onDelete(); _generateInstantPreview(); }, child: const CircleAvatar(radius: 11, backgroundColor: Colors.redAccent, child: Icon(Icons.close, size: 12, color: Colors.white)))),
        ],
      ),
    );
  }

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