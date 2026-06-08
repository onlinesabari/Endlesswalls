import 'dart:ui' as ui;
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'wallpaper_settings.dart';
import '../utils/ripple_layout.dart';
import '../utils/spiral_layout.dart';
import '../utils/honeycomb_layout.dart';
import '../utils/wave_layout.dart';

class FaceLayer {
  final File imageFile;
  ui.Image? decodedImage;
  Color bgColor;      
  Color strokeColor;  

  FaceLayer({
    required this.imageFile, 
    this.decodedImage,
    required this.bgColor,
    required this.strokeColor,
  });
}

class FaceEngine {
  static Future<File> generate({
    required List<FaceLayer> faces,         
    required WallpaperSettings config,      
    required String faceBgShape,           
    required String colorMode,             
    required List<Color> palette,          
    required List<Color> strokePalette,    
    required bool enableStroke,            
    required double strokeThickness,       
    required double centerFaceSize,   
    double spiralSpacing = 50.0,
    bool spiralScaleOutward = false,
    bool honeycombFisheye = false,
    double waveAmplitude = 150.0,
    double waveFrequency = 10.0,
    bool waveFlowRotation = true,
    int waveCount = 1,
    bool keepUpright = false,     
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const width = 1080.0;
    const height = 1920.0;
    final random = Random();

    // 1. Draw Canvas Background
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), Paint()..color = config.bgColor);

    if (faces.isEmpty) return _saveCanvas(recorder, width, height);

    // 2. Decode Images
    for (var face in faces) {
      if (face.decodedImage == null) {
        final bytes = await face.imageFile.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        face.decodedImage = frame.image;
      }
    }

    // 3. Define Base Variables
    final int totalItems = config.rows * config.columns;
    List<RippleItem> positions = [];

    // ==========================================
    // 3. GENERATE LAYOUT COORDINATES
    // ==========================================

    if (config.layoutStyle == 'rangoli') {
      positions = RippleLayout.generate(
        canvasWidth: width, canvasHeight: height,
        centerSize: centerFaceSize, itemSize: config.baseSize,
        gap: config.padding, baseRotationDegrees: config.baseRotation,
      );
    } else if (config.layoutStyle == 'spiral') {
      positions = SpiralLayout.generate(
        canvasWidth: width, canvasHeight: height,
        count: totalItems, baseItemSize: config.baseSize,
        spacingFactor: spiralSpacing, scaleOutward: spiralScaleOutward,
        baseRotationDegrees: config.baseRotation, padding: config.padding,
      );
    } else if (config.layoutStyle == 'honeycomb') {
      positions = HoneycombLayout.generate(
        canvasWidth: width, canvasHeight: height,
        rows: config.rows, columns: config.columns,
        itemSize: config.baseSize, padding: config.padding,
        applyFisheye: honeycombFisheye, globalRotationDegrees: config.baseRotation,
      );
    } else if (config.layoutStyle == 'wave') {
      positions = WaveLayout.generate(
        canvasWidth: width, canvasHeight: height,
        count: totalItems, itemSize: config.baseSize, padding: config.padding,
        amplitude: waveAmplitude, frequency: waveFrequency,
        flowRotation: waveFlowRotation, waveCount: waveCount,
        globalRotationDegrees: config.baseRotation,
      );
    } else {
      final double itemSpacing = config.baseSize + config.padding;

      final double gridWidth = (config.columns * config.baseSize) + ((config.columns - 1) * config.padding);
      final double gridHeight = (config.rows * config.baseSize) + ((config.rows - 1) * config.padding);

      final double startX = (width - gridWidth) / 2 + (config.baseSize / 2);
      final double startY = (height - gridHeight) / 2 + (config.baseSize / 2);

      for (int i = 0; i < totalItems; i++) {
        double angle = config.rotationStyle == 'random' ? random.nextDouble() * 2 * pi : config.baseRotation * (pi / 180);
        double size = config.sizeStyle == 'random' ? config.baseSize * (0.5 + random.nextDouble() * 0.8) : config.baseSize;
          
          // Grid & Staggered Math
          int r = i ~/ config.columns; 
          int c = i % config.columns;  
          
          double x = startX + (c * itemSpacing);
          double y = startY + (r * itemSpacing);

          if (config.layoutStyle == 'staggered' && r % 2 != 0) {
             x += itemSpacing / 2;
          }
         positions.add(RippleItem(position: Offset(x, y), size: size, angleRadians: angle));
      }
    }

    // ==========================================
    // 4. DRAWING LOOP
    // ==========================================
    int itemCounter = 0;
    final bool isAdvancedLayout = ['rangoli', 'spiral', 'honeycomb', 'wave'].contains(config.layoutStyle);
    for (var item in positions) {
      FaceLayer currentFace = item.isCenter 
          ? faces[0] 
          : (config.patternStyle == 'sequential' ? faces[itemCounter % faces.length] : faces[random.nextInt(faces.length)]);

      Color activeBgColor = colorMode == 'single' ? palette.first 
          : (colorMode == 'multi_alternating' ? palette[itemCounter % palette.length] : palette[random.nextInt(palette.length)]);

      Color activeStrokeColor = colorMode == 'single' ? strokePalette.first 
          : (colorMode == 'multi_alternating' ? strokePalette[itemCounter % strokePalette.length] : strokePalette[random.nextInt(strokePalette.length)]);

          double finalAngle = (isAdvancedLayout && keepUpright) 
          ? (config.baseRotation * (pi / 180)) // Use global rotation slider instead of curve math
          : item.angleRadians;

      _stampImage(
        canvas, currentFace, item.position, item.size, finalAngle, // <-- Pass finalAngle here!
        faceBgShape, activeBgColor, activeStrokeColor, enableStroke, strokeThickness,
      );
      
      itemCounter++;
    }

    return _saveCanvas(recorder, width, height);
  }

  static void _stampImage(
    Canvas canvas, FaceLayer faceLayer, Offset center, double size, double rotationRadians,
    String faceBgShape, Color bgColor, Color strokeColor, bool enableStroke, double strokeThickness,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationRadians);

    Rect shapeRect = Rect.fromCenter(center: Offset.zero, width: size, height: size);

    if (faceBgShape != 'none') {
      Paint bgPaint = Paint()..color = bgColor..style = PaintingStyle.fill;
      if (faceBgShape == 'circle') canvas.drawCircle(Offset.zero, size / 2, bgPaint);
      else if (faceBgShape == 'square') canvas.drawRect(shapeRect, bgPaint);
    } 
    else if (enableStroke && strokeThickness > 0) {
      canvas.save();
      double targetSize = size + (strokeThickness * 2);
      double scale = max(targetSize / faceLayer.decodedImage!.width, targetSize / faceLayer.decodedImage!.height);
      canvas.scale(scale, scale);
      canvas.drawImage(faceLayer.decodedImage!, Offset(-faceLayer.decodedImage!.width / 2, -faceLayer.decodedImage!.height / 2), 
        Paint()..colorFilter = ColorFilter.mode(strokeColor, BlendMode.srcIn));
      canvas.restore();
    }

    canvas.save();
    if (faceBgShape == 'circle') canvas.clipPath(Path()..addOval(shapeRect));
    else if (faceBgShape == 'square') canvas.clipRect(shapeRect);

    double scale = max(size / faceLayer.decodedImage!.width, size / faceLayer.decodedImage!.height);
    canvas.scale(scale, scale);
    canvas.drawImage(faceLayer.decodedImage!, Offset(-faceLayer.decodedImage!.width / 2, -faceLayer.decodedImage!.height / 2), Paint()..isAntiAlias = true);
    canvas.restore();

    if (faceBgShape != 'none' && enableStroke && strokeThickness > 0) {
      Paint strokePaint = Paint()..color = strokeColor..style = PaintingStyle.stroke..strokeWidth = strokeThickness;
      if (faceBgShape == 'circle') canvas.drawCircle(Offset.zero, size / 2, strokePaint);
      else canvas.drawRect(shapeRect, strokePaint);
    }

    canvas.restore();
  }

  static Future<File> _saveCanvas(ui.PictureRecorder recorder, double width, double height) async {
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${(await getTemporaryDirectory()).path}/face_wall_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    img.dispose();
    picture.dispose();
    
    return file;
  }
}