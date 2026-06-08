import 'package:flutter/material.dart';

// This holds all the shared layout rules so we don't have to 
// pass 10 different variables into our engines every time.
class WallpaperSettings {
  final Color bgColor;
  final int rows;
  final int columns;
  final double baseSize;
  final double baseRotation;
  final String layoutStyle;   // 'grid', 'staggered', 'scatter'
  final String patternStyle;  // 'random', 'linear', 'alternating'
  final String rotationStyle; // 'fixed', 'random', 'alternating'
  final String sizeStyle;     // 'uniform', 'random'
  final double padding;

  WallpaperSettings({
    required this.bgColor,
    required this.rows,
    required this.columns,
    required this.baseSize,
    required this.baseRotation,
    required this.layoutStyle,
    required this.patternStyle,
    required this.rotationStyle,
    required this.sizeStyle,
    required this.padding,
  });
}