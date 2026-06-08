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

class EmojiEngine {
  static Future<File> generate(
    List<String> emojis,
    WallpaperSettings config, {
    double centerItemSize = 150.0,
    double spiralSpacing = 30.0,
    bool spiralScaleOutward = false,
    bool honeycombFisheye = false,
    double waveAmplitude = 150.0,
    double waveFrequency = 10.0,
    bool waveFlowRotation = true,
    int waveCount = 1,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const width = 1080.0;
    const height = 1920.0;
    final random = Random();

    // 1. Paint Background
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, height),
      Paint()..color = config.bgColor,
    );

    List<String> safeEmojis = emojis.isNotEmpty ? emojis : ['❓'];

    // 2. Define Base Variables
    final int totalItems = config.rows * config.columns;
    final double cellWidth = width / config.columns;
    final double cellHeight = height / config.rows;

    // ==========================================
    // 3. GENERATE ADVANCED LAYOUT COORDINATES
    // ==========================================
    List<RippleItem> generatedPositions = [];
    final bool isAdvancedLayout = ['rangoli', 'spiral', 'honeycomb', 'wave'].contains(config.layoutStyle);

    if (config.layoutStyle == 'rangoli') {
      generatedPositions = RippleLayout.generate(
        canvasWidth: width, canvasHeight: height,
        centerSize: centerItemSize, itemSize: config.baseSize,
        gap: config.padding, baseRotationDegrees: config.baseRotation,
      );
    } else if (config.layoutStyle == 'spiral') {
      generatedPositions = SpiralLayout.generate(
        canvasWidth: width, canvasHeight: height,
        count: totalItems, baseItemSize: config.baseSize,
        spacingFactor: spiralSpacing, scaleOutward: spiralScaleOutward,
        baseRotationDegrees: config.baseRotation, padding: config.padding,
      );
    } else if (config.layoutStyle == 'honeycomb') {
      generatedPositions = HoneycombLayout.generate(
        canvasWidth: width, canvasHeight: height,
        rows: config.rows, columns: config.columns,
        itemSize: config.baseSize, padding: config.padding,
        applyFisheye: honeycombFisheye,
        globalRotationDegrees: config.baseRotation,
      );
    } else if (config.layoutStyle == 'wave') {
      generatedPositions = WaveLayout.generate(
        canvasWidth: width, canvasHeight: height,
        count: totalItems, itemSize: config.baseSize, padding: config.padding,
        amplitude: waveAmplitude, frequency: waveFrequency,
        flowRotation: waveFlowRotation, waveCount: waveCount,
        globalRotationDegrees: config.baseRotation,
      );
    }

    final int iterations = isAdvancedLayout ? generatedPositions.length : totalItems;

    // ==========================================
    // 4. MAIN POSITIONING & DRAWING LOOP
    // ==========================================
    int patternIndex = 0;
    
    for (int i = 0; i < iterations; i++) {
      
      // Pick Emoji (Center of Rangoli gets focus, others follow pattern)
      String currentEmoji;
      if (config.layoutStyle == 'rangoli' && isAdvancedLayout && generatedPositions[i].isCenter) {
        currentEmoji = safeEmojis.first;
      } else {
        currentEmoji = config.patternStyle == 'sequential' 
            ? safeEmojis[patternIndex % safeEmojis.length] 
            : safeEmojis[random.nextInt(safeEmojis.length)];
        patternIndex++; // Only increment for standard items to keep sequence perfect
      }

      // Calculate Size
      double size = config.baseSize;
      if (config.sizeStyle == 'random') {
        size = config.baseSize * (0.5 + random.nextDouble() * 0.8);
      }

      double effectiveSize = size;
      if (!isAdvancedLayout && config.layoutStyle != 'scatter') {
        effectiveSize = (size - config.padding).clamp(5.0, size); 
      }

      Offset pos;

      // Positioning Logic
      if (isAdvancedLayout) {
        pos = generatedPositions[i].position;
        effectiveSize = generatedPositions[i].size; 
      } 
      else {
        // GRID & STAGGERED
        int r = i ~/ config.columns; 
        int c = i % config.columns;  
        double x = (c * cellWidth) + (cellWidth / 2);
        double y = (r * cellHeight) + (cellHeight / 2);
        if (config.layoutStyle == 'staggered' && r % 2 != 0) x += cellWidth / 2;
        pos = Offset(x, y);
      }

      // Drawing Logic
        double angleRadians = 0;
        if (isAdvancedLayout) {
           angleRadians = generatedPositions[i].angleRadians; 
        } else if (config.rotationStyle == 'random') {
          angleRadians = random.nextDouble() * 2 * pi;
        } else if (config.rotationStyle == 'alternating') {
          angleRadians = ((i % config.columns) % 2 == 0 ? config.baseRotation : -config.baseRotation) * (pi / 180);
        } else {
          angleRadians = config.baseRotation * (pi / 180);
        }

        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(angleRadians);

        final textPainter = TextPainter(
          text: TextSpan(
            text: currentEmoji,
            style: TextStyle(fontSize: effectiveSize),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
        textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        canvas.restore();
      
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${(await getTemporaryDirectory()).path}/emoji_wall_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    img.dispose();
    picture.dispose();

    return file;
  }
}