import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class AuraOrb {
  double x;
  double y;
  double radius;
  Color color;

  AuraOrb({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
  });
}

class AuraEngine {
  static Future<File> generate({
    required List<AuraOrb> orbs,
    required Color bgColor,
    required double globalBlur,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const width = 1080.0;
    const height = 1920.0;

    // 1. Draw Solid Background
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, height), 
      Paint()..color = bgColor
    );

    // 2. Draw overlapping blurred orbs
    for (var orb in orbs) {
      final paint = Paint()
        ..color = orb.color
        ..style = PaintingStyle.fill
        // This extreme blur makes the orb look like a glowing aura cloud
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, globalBlur);

      canvas.drawCircle(Offset(orb.x, orb.y), orb.radius, paint);
    }

    // 3. Save and return
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${(await getTemporaryDirectory()).path}/aura_orb_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());

    return file;
  }
}