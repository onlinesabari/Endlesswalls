import 'dart:ui' as ui;
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class FlowEngine {
  static Future<File> generate({
    required int particleCount,
    required double noiseScale,
    required int trailLength,
    required Color primaryColor,
    required Color secondaryColor,
    required Color bgColor,
    required double strokeWidth,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const width = 1080.0;
    const height = 1920.0;

    // 1. Draw Background
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, height),
      Paint()..color = bgColor,
    );

    final rand = Random();
    
    // Pseudo-noise function using trigonometry
    double getNoise(double x, double y) {
      return sin(x * noiseScale) + cos(y * noiseScale) + sin((x + y) * noiseScale * 0.5);
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Calculate paths for each particle
    for (int i = 0; i < particleCount; i++) {
      double x = rand.nextDouble() * width;
      double y = rand.nextDouble() * height;
      
      final path = Path();
      path.moveTo(x, y);

      for (int step = 0; step < trailLength; step++) {
        // Calculate angle based on "noise" field
        double angle = getNoise(x, y) * pi * 2;
        
        // Move particle
        x += cos(angle) * 2.0; // Step size
        y += sin(angle) * 2.0;

        path.lineTo(x, y);

        // Break if out of bounds
        if (x < 0 || x > width || y < 0 || y > height) break;
      }

      // Mix colors based on starting position
      double mixRatio = (i / particleCount);
      paint.color = Color.lerp(primaryColor, secondaryColor, mixRatio)!.withOpacity(0.6);

      canvas.drawPath(path, paint);
    }

    // 3. Save and return
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${(await getTemporaryDirectory()).path}/flow_particle_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());

    return file;
  }
}
