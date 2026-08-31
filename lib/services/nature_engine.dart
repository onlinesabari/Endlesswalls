import 'dart:ui' as ui;
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class NatureEngine {
  static Future<File> generate({
    required double density,
    required String symmetry,
    required String season,
    required int seed,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const width = 1080.0;
    const height = 1920.0;
    final random = Random(seed);

    // Background color based on season
    Color bgColor;
    switch (season) {
      case 'Autumn':
        bgColor = const Color(0xFF2C1914);
        break;
      case 'Spring':
        bgColor = const Color(0xFFFDF6E3);
        break;
      case 'Summer':
        bgColor = const Color(0xFFE8F5E9);
        break;
      case 'Winter':
        bgColor = const Color(0xFFE0F7FA);
        break;
      default:
        bgColor = const Color(0xFF1E1E1E);
    }
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), Paint()..color = bgColor);

    int maxDepth = (4 + (density * 5)).toInt();

    // Symmetry logic
    if (symmetry == 'Radial') {
      int branches = 4 + random.nextInt(5);
      canvas.translate(width / 2, height / 2);
      for (int i = 0; i < branches; i++) {
        canvas.save();
        canvas.rotate(i * 2 * pi / branches);
        drawTree(canvas, random, maxDepth, height * 0.25, -pi / 2, season);
        canvas.restore();
      }
    } else if (symmetry == 'Bilateral') {
      canvas.translate(width / 2, height);
      drawTree(canvas, random, maxDepth, height * 0.3, -pi / 2, season, bilateral: true);
    } else { // Chaos
      int numTrees = 1 + random.nextInt(3);
      for (int i = 0; i < numTrees; i++) {
        canvas.save();
        canvas.translate(random.nextDouble() * width, height * (0.8 + random.nextDouble() * 0.2));
        drawTree(canvas, random, maxDepth, height * (0.2 + random.nextDouble() * 0.15), -pi / 2, season);
        canvas.restore();
      }
    }

    // Render and Save
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${(await getTemporaryDirectory()).path}/nature_wall_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file;
  }

  static void drawTree(Canvas canvas, Random random, int depth, double length, double angle, String season, {bool bilateral = false}) {
    if (depth == 0) {
      drawLeaf(canvas, random, length, season);
      return;
    }

    final start = Offset.zero;
    final end = Offset(cos(angle) * length, sin(angle) * length);

    final Paint branchPaint = Paint()
      ..color = season == 'Winter' ? Colors.blueGrey.shade800 : Colors.brown.shade700
      ..strokeWidth = depth.toDouble() * 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, branchPaint);
    canvas.translate(end.dx, end.dy);

    int branches = 2 + random.nextInt(2);
    
    if (bilateral) {
      double angleOffset = 0.2 + random.nextDouble() * 0.3;
      canvas.save();
      drawTree(canvas, random, depth - 1, length * 0.7, angle - angleOffset, season, bilateral: true);
      canvas.restore();
      canvas.save();
      drawTree(canvas, random, depth - 1, length * 0.7, angle + angleOffset, season, bilateral: true);
      canvas.restore();
    } else {
      for (int i = 0; i < branches; i++) {
        canvas.save();
        double angleOffset = (random.nextDouble() - 0.5) * pi / 2;
        double newLength = length * (0.6 + random.nextDouble() * 0.3);
        drawTree(canvas, random, depth - 1, newLength, angle + angleOffset, season);
        canvas.restore();
      }
    }
  }

  static void drawLeaf(Canvas canvas, Random random, double size, String season) {
    List<Color> leafColors;
    switch (season) {
      case 'Autumn':
        leafColors = [Colors.red, Colors.orange, Colors.amber, Colors.deepOrange];
        break;
      case 'Spring':
        leafColors = [Colors.pinkAccent, Colors.lightGreen, Colors.greenAccent];
        break;
      case 'Summer':
        leafColors = [Colors.green, Colors.lightGreen, Colors.teal];
        break;
      case 'Winter':
        leafColors = [Colors.white, Colors.cyan.shade100, Colors.lightBlue.shade100];
        break;
      default:
        leafColors = [Colors.green];
    }

    final Paint leafPaint = Paint()
      ..color = leafColors[random.nextInt(leafColors.length)].withOpacity(0.7)
      ..style = PaintingStyle.fill;

    double radius = 5.0 + random.nextDouble() * size * 0.5;
    
    if (season == 'Winter') {
      canvas.drawCircle(Offset.zero, radius * 0.5, leafPaint); // Simple circles for snow/ice berries
    } else if (season == 'Spring') {
      for (int i = 0; i < 5; i++) {
        canvas.drawOval(Rect.fromCenter(center: Offset(cos(i * 2 * pi / 5) * radius * 0.5, sin(i * 2 * pi / 5) * radius * 0.5), width: radius, height: radius * 0.5), leafPaint);
      } // Simple flower petals
    } else {
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: radius, height: radius * 1.5), leafPaint);
    }
  }
}
