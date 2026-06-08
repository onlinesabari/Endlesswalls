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

class IconEngine {
  static Future<File> generate(
    List<IconData> icons, 
    List<Color> iconColors, // Accepts a list of colors now
    WallpaperSettings config, 
    {
      String iconFillStyle = 'solid',
      String shadowStyle = 'none',
      String colorMode = 'single',
      double centerItemSize = 150.0,
      double spiralSpacing = 30.0,
      bool spiralScaleOutward = false,
      bool honeycombFisheye = false,
      double waveAmplitude = 150.0,
      double waveFrequency = 10.0,
      bool waveFlowRotation = true,
      int waveCount = 1,
    } 
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const width = 1080.0;
    const height = 1920.0;
    final random = Random();
    
    // Draw Background
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), Paint()..color = config.bgColor);

    // Safety checks
    List<IconData> safeIcons = icons.isNotEmpty ? icons : [Icons.bolt];
    List<Color> safeColors = iconColors.isNotEmpty ? iconColors : [Colors.white];

    // 1. Define base variables first
    final int totalItems = config.rows * config.columns;
    final double cellWidth = width / config.columns;
    final double cellHeight = height / config.rows;


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
        applyFisheye: honeycombFisheye, globalRotationDegrees: config.baseRotation,
      );
    } else if (config.layoutStyle == 'wave') {
      generatedPositions = WaveLayout.generate(
        canvasWidth: width, canvasHeight: height,
        count: totalItems, itemSize: config.baseSize, padding: config.padding,
        amplitude: waveAmplitude, frequency: waveFrequency,
        flowRotation: waveFlowRotation, waveCount: waveCount, globalRotationDegrees: config.baseRotation,
      );
    }

    // Set the iteration count based on whether we used an advanced layout generator
    final int iterations = isAdvancedLayout ? generatedPositions.length : totalItems;


    // 3. MAIN LOOP
    for (int i = 0; i < iterations; i++) {
      
      // Pick Icon
      IconData currentIcon;
      if (config.layoutStyle == 'rangoli' && isAdvancedLayout && generatedPositions[i].isCenter) {
        currentIcon = safeIcons.first; // Force center to be the first icon
      } else {
        currentIcon = config.patternStyle == 'sequential' 
            ? safeIcons[i % safeIcons.length] 
            : safeIcons[random.nextInt(safeIcons.length)];
      }

      // Pick Color
      Color currentIconColor;
      if (colorMode == 'single') {
        currentIconColor = safeColors.first;
      } else if (colorMode == 'multi_random') {
        currentIconColor = safeColors[random.nextInt(safeColors.length)];
      } else { // multi_alternating
        currentIconColor = safeColors[i % safeColors.length];
      }

      // Calculate Size
      double size = config.baseSize;
      if (config.sizeStyle == 'random') {
        size = config.baseSize * (0.5 + random.nextDouble() * 0.8);
      }

      // Apply Padding
      double effectiveSize = size;
      if (config.layoutStyle != 'scatter') {
        effectiveSize = size - config.padding; 
        if (effectiveSize < 5) effectiveSize = 5; 
      }

      Offset pos;

      if (isAdvancedLayout) {
        pos = generatedPositions[i].position;
        effectiveSize = generatedPositions[i].size; // The generators now handle sizing/scaling!
      } else {
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
           angleRadians = generatedPositions[i].angleRadians; // The generators handle math rotations
        } else
        if (config.rotationStyle == 'random') {
          angleRadians = random.nextDouble() * 360 * (pi / 180);
        } else if (config.rotationStyle == 'alternating') {
          angleRadians = ((i % config.columns) % 2 == 0 ? config.baseRotation : -config.baseRotation) * (pi / 180);
        } else {
          angleRadians = config.baseRotation * (pi / 180);
        }

        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(angleRadians);

        // Outline Logic
        bool drawOutline = false;
        if (iconFillStyle == 'outline') {
          drawOutline = true;
        } else if (iconFillStyle == 'mixed') {
          drawOutline = random.nextBool();
        }

        // Shadow Logic
        List<Shadow>? iconShadows;
        if (shadowStyle == 'neon_glow') {
          iconShadows = [
            Shadow(color: currentIconColor.withOpacity(0.8), blurRadius: effectiveSize * 0.2, offset: Offset.zero),
            Shadow(color: currentIconColor.withOpacity(0.4), blurRadius: effectiveSize * 0.5, offset: Offset.zero),
          ];
        } else if (shadowStyle == 'drop_shadow') {
          iconShadows = [
            Shadow(color: Colors.black54, blurRadius: effectiveSize * 0.1, offset: Offset(0, effectiveSize * 0.08)),
          ];
        } else if (shadowStyle == 'retro_offset') {
          iconShadows = [
            Shadow(color: Colors.black, blurRadius: 0, offset: Offset(effectiveSize * 0.08, effectiveSize * 0.08)),
          ];
        }

        // Text Style Logic
        TextStyle iconStyle;
        if (drawOutline) {
          iconStyle = TextStyle(
            fontSize: effectiveSize,
            fontFamily: currentIcon.fontFamily, 
            package: currentIcon.fontPackage,
            shadows: iconShadows,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = max(2.0, effectiveSize * 0.06) 
              ..color = currentIconColor, 
          );
        } else {
          iconStyle = TextStyle(
            fontSize: effectiveSize,
            color: currentIconColor, 
            fontFamily: currentIcon.fontFamily, 
            package: currentIcon.fontPackage,
            shadows: iconShadows,
          );
        }

        final textPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(currentIcon.codePoint),
            style: iconStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
        textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        canvas.restore();
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${(await getTemporaryDirectory()).path}/icon_wall_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    img.dispose();
    picture.dispose();

    return file;
  }
}