import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class LiquidBlob {
  Offset position;
  double radius;
  Color color;
  LiquidBlob({required this.position, required this.radius, required this.color});
}

class LiquidEngine {
  static Future<File> generate({
    required List<LiquidBlob> blobs,
    required Color bgColor,
    required double gooeyness, // We will use this as the alpha multiplier
    required double viscosity, // We will use this as the blur radius
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const width = 1080.0;
    const height = 1920.0;

    // 1. Draw Background SEPARATELY (No filter)
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), Paint()..color = bgColor);

    // 2. THE MAGIC FILTER
    // We need a VERY high multiplier (gooeyness) and a huge negative offset
    final paint = Paint()
      ..colorFilter = ui.ColorFilter.matrix([
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, gooeyness, -(gooeyness * 50), // This creates the "snap"
      ])
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, viscosity);

    // 3. THE CRITICAL STEP: SaveLayer
    // This isolates the blobs so they only "melt" with each other, not the background.
    canvas.saveLayer(const Rect.fromLTWH(0, 0, width, height), paint);

    for (var blob in blobs) {
      // Use a simple paint for the circles; the layer itself handles the filter
      canvas.drawCircle(blob.position, blob.radius, Paint()..color = blob.color);
    }

    canvas.restore(); // Applies the filter to everything in the layer

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${(await getTemporaryDirectory()).path}/liquid_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());

    return file;
  }
}