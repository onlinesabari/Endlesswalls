import 'dart:ui' as ui;
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CrystalEngine {
  static Future<File> generate({
    required List<Offset> points,
    required List<Color> colors,
    required Color lineColor,
    required double lineWidth,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const width = 1080.0;
    const height = 1920.0;
    final screenRect = const Rect.fromLTWH(0, 0, width, height);

    // 1. Calculate and Draw Cells
    for (int i = 0; i < points.length; i++) {
      Offset pi = points[i];
      Path cellPath = Path()..addRect(screenRect);

      for (int j = 0; j < points.length; j++) {
        if (i == j) continue;
        Offset pj = points[j];
        
        // Prevent crashes if points perfectly overlap
        if (pi.dx == pj.dx && pi.dy == pj.dy) continue; 

        Path halfPlane = _getHalfPlane(pi, pj);
        cellPath = Path.combine(PathOperation.intersect, cellPath, halfPlane);
      }

      // Fill the cell
      canvas.drawPath(
        cellPath,
        Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );

      // Draw the shattered lines
      if (lineWidth > 0) {
        canvas.drawPath(
          cellPath,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = lineWidth
            ..strokeJoin = StrokeJoin.miter
            ..isAntiAlias = true,
        );
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${(await getTemporaryDirectory()).path}/crystal_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());

    return file;
  }

  // MATHEMATICAL MAGIC: Creates a giant polygon covering the side of the bisector containing point A
  static Path _getHalfPlane(Offset a, Offset b) {
    Offset mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    double dx = b.dx - a.dx;
    double dy = b.dy - a.dy;
    double dist = sqrt(dx * dx + dy * dy);
    
    // Unit vectors
    double ux = dx / dist;
    double uy = dy / dist;
    // Perpendicular vectors
    double vx = -uy;
    double vy = ux;

    double size = 5000.0; // Large enough to cover the screen

    // Create a massive rectangle extending towards point A
    Offset c1 = Offset(mid.dx + size * vx, mid.dy + size * vy);
    Offset c2 = Offset(mid.dx - size * vx, mid.dy - size * vy);
    Offset c3 = Offset(c2.dx - size * ux, c2.dy - size * uy);
    Offset c4 = Offset(c1.dx - size * ux, c1.dy - size * uy);

    return Path()
      ..moveTo(c1.dx, c1.dy)
      ..lineTo(c2.dx, c2.dy)
      ..lineTo(c3.dx, c3.dy)
      ..lineTo(c4.dx, c4.dy)
      ..close();
  }
}