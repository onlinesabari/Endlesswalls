import 'dart:ui' as ui;
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class WaveLayer {
  String type;
  Color color;
  double amplitude;
  double frequency;
  double verticalPosition;
  double rotation;

  WaveLayer({
    required this.type,
    required this.color,
    required this.amplitude,
    required this.frequency,
    required this.verticalPosition,
    required this.rotation,
  });
}

class WaveEngine {
  static Future<File> generate({
    required List<WaveLayer> layers, 
    required Color bgColor,
    required bool enableTransparency,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const width = 1080.0;
    const height = 1920.0;
    
    // 1. Paint Solid Background
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), Paint()..color = bgColor);

    // To prevent corners showing when a wave is rotated, we draw way off the screen
    const double drawStartX = -width * 2;
    const double drawEndX = width * 3;
    const double drawWidth = drawEndX - drawStartX;

    // 2. Draw Layers BACK to FRONT
    for (int i = layers.length - 1; i >= 0; i--) {
      WaveLayer layer = layers[i];
      
      // We identify the wave furthest in the back!
      bool isBackmostWave = (i == layers.length - 1);
      double baseY = layer.verticalPosition;

      final paint = Paint()..style = PaintingStyle.fill;

      // MAGIC: Block the background, but create a glassy gradient for overlaps!
      if (enableTransparency && !isBackmostWave) {
        paint.shader = ui.Gradient.linear(
          Offset(0, baseY - layer.amplitude), // Start vibrant at the wave's peak
          Offset(0, baseY + (height / 2)),    // Fade out as it goes down the screen
          [
            layer.color.withOpacity(0.95),    // 95% solid at the top edge
            layer.color.withOpacity(0.20),    // Glassy and transparent at the bottom
          ],
        );
      } else {
        // The back-most wave (or all waves if toggle is off) is 100% solid to block the background!
        paint.color = layer.color;
      }

      Path path = Path();
      
      // MAGIC: Save canvas, rotate specifically around this wave's center, then we draw!
      canvas.save();
      canvas.translate(width / 2, baseY);
      canvas.rotate(layer.rotation * (pi / 180));
      canvas.translate(-width / 2, -baseY);

      path.moveTo(drawStartX, baseY);
      if (layer.type == 'ZigZag') {
        int steps = layer.frequency.toInt() * 8; 
        double stepX = drawWidth / steps;
        for (int j = 1; j <= steps; j++) {
          double nextX = drawStartX + (j * stepX);
          double nextY = baseY + (j % 2 == 0 ? layer.amplitude : -layer.amplitude);
          path.lineTo(nextX, nextY);
        }
      } 
      else if (layer.type == 'Sine') {
        for (double x = drawStartX; x <= drawEndX; x += 5) {
          double y = baseY + sin((x / width) * pi * layer.frequency) * layer.amplitude;
          path.lineTo(x, y);
        }
      } 
      else if (layer.type == 'Bezier') {
        int steps = layer.frequency.toInt() * 4;
        double stepX = drawWidth / steps;
        for (int j = 0; j < steps; j++) {
          double startX = drawStartX + (j * stepX);
          double endX = startX + stepX;
          double controlX = startX + (stepX / 2);
          double controlY = baseY + (j % 2 == 0 ? layer.amplitude * 1.5 : -layer.amplitude * 1.5);
          path.quadraticBezierTo(controlX, controlY, endX, baseY);
        }
      }

      // Close the path DEEP below the screen so rotation doesn't expose the bottom
      path.lineTo(drawEndX, height * 3); 
      path.lineTo(drawStartX, height * 3);    
      path.close();                     

      canvas.drawPath(path, paint);
      // MAGIC: Restore the canvas perfectly flat before the next wave draws
      canvas.restore();
    }

    // 3. Render and Save
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${(await getTemporaryDirectory()).path}/wave_wall_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file;
  }
}