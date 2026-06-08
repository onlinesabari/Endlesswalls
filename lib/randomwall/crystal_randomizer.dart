import 'dart:math';
import 'package:flutter/material.dart';

class CrystalRandomState {
  final int rows;
  final int cols;
  final double jitter;
  final double lineWidth;
  final Color lineColor;
  final List<Color> palette;

  CrystalRandomState({
    required this.rows,
    required this.cols,
    required this.jitter,
    required this.lineWidth,
    required this.lineColor,
    required this.palette,
  });
}

class CrystalRandomizer {
  static final Random _rnd = Random();

  static Color _randomColor() {
    return Color.fromARGB(255, _rnd.nextInt(256), _rnd.nextInt(256), _rnd.nextInt(256));
  }

  static CrystalRandomState generate() {
    int r = _rnd.nextInt(6) + 4; // 4 to 9 rows
    int c = _rnd.nextInt(4) + 3; // 3 to 6 columns
    
    int numColors = _rnd.nextInt(4) + 3; 
    List<Color> randomPalette = List.generate(numColors, (_) => _randomColor());

    return CrystalRandomState(
      rows: r,
      cols: c,
      jitter: _rnd.nextDouble() * 0.8 + 0.2, // Between 20% and 100% chaotic
      lineWidth: _rnd.nextDouble() * 8 + 2,  // 2px to 10px lines
      lineColor: _rnd.nextBool() ? Colors.black : Colors.white, // Sharp contrast lines
      palette: randomPalette,
    );
  }
}