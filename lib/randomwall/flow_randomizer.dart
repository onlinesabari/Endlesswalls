import 'dart:math';
import 'package:flutter/material.dart';

class FlowRandomizerState {
  final int particleCount;
  final double noiseScale;
  final int trailLength;
  final double strokeWidth;
  final Color primaryColor;
  final Color secondaryColor;
  final Color bgColor;

  FlowRandomizerState({
    required this.particleCount,
    required this.noiseScale,
    required this.trailLength,
    required this.strokeWidth,
    required this.primaryColor,
    required this.secondaryColor,
    required this.bgColor,
  });
}

class FlowRandomizer {
  static FlowRandomizerState generate() {
    final rand = Random();

    // Vibrant colors
    Color randomColor() => Color.fromARGB(
      255, 
      rand.nextInt(256), 
      rand.nextInt(256), 
      rand.nextInt(256)
    );

    // Dark backgrounds for better contrast with bright particles
    Color randomBg() {
      final palettes = [
        const Color(0xFF0F0F0F),
        const Color(0xFF1A1A2E),
        const Color(0xFF001220),
        const Color(0xFF1B0018),
      ];
      return palettes[rand.nextInt(palettes.length)];
    }

    return FlowRandomizerState(
      particleCount: rand.nextInt(3000) + 1000, // 1000 to 4000
      noiseScale: (rand.nextDouble() * 0.005) + 0.001, // 0.001 to 0.006
      trailLength: rand.nextInt(150) + 50, // 50 to 200
      strokeWidth: (rand.nextDouble() * 3.0) + 0.5, // 0.5 to 3.5
      primaryColor: randomColor(),
      secondaryColor: randomColor(),
      bgColor: randomBg(),
    );
  }
}
