import 'dart:math';
import 'package:flutter/material.dart';
import '../services/nature_engine.dart';
class NatureRandomizer extends CustomPainter {
  final double density; // Growth density
  final String symmetry; // 'Radial', 'Bilateral', 'Chaos'
  final String season; // 'Spring', 'Summer', 'Autumn', 'Winter'
  final int seed;

  NatureRandomizer({
    required this.density,
    required this.symmetry,
    required this.season,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
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
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = bgColor);

    int maxDepth = (4 + (density * 5)).toInt();

    // Symmetry logic
    if (symmetry == 'Radial') {
      int branches = 4 + random.nextInt(5);
      canvas.translate(size.width / 2, size.height / 2);
      for (int i = 0; i < branches; i++) {
        canvas.save();
        canvas.rotate(i * 2 * pi / branches);
        NatureEngine.drawTree(canvas, random, maxDepth, size.height * 0.25, -pi / 2, season);
        canvas.restore();
      }
    } else if (symmetry == 'Bilateral') {
      canvas.translate(size.width / 2, size.height);
      NatureEngine.drawTree(canvas, random, maxDepth, size.height * 0.3, -pi / 2, season, bilateral: true);
    } else { // Chaos
      int numTrees = 1 + random.nextInt(3);
      for (int i = 0; i < numTrees; i++) {
        canvas.save();
        canvas.translate(random.nextDouble() * size.width, size.height * (0.8 + random.nextDouble() * 0.2));
        NatureEngine.drawTree(canvas, random, maxDepth, size.height * (0.2 + random.nextDouble() * 0.15), -pi / 2, season);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant NatureRandomizer oldDelegate) {
    return density != oldDelegate.density ||
           symmetry != oldDelegate.symmetry ||
           season != oldDelegate.season ||
           seed != oldDelegate.seed;
  }
}
