import 'dart:math';
import 'package:flutter/material.dart';
import '../services/quote_engine.dart';

class QuoteState {
  final Color bgColor;
  final Color primaryColor;
  final Color accentColor;
  final QuoteStyle style;
  final double fontSize;
  final double density;
  final List<String> texts;

  QuoteState({
    required this.bgColor,
    required this.primaryColor,
    required this.accentColor,
    required this.style,
    required this.fontSize,
    required this.density,
    required this.texts,
  });
}

class QuoteRandomizer {
  static final Random _r = Random();

  static final List<List<String>> _wordSets = [
    ["DESIGN", "CREATE", "INSPIRE", "ART", "FLOW"],
    ["CHAOS", "ORDER", "SYSTEM", "VOID", "NULL"],
    ["HACK", "CODE", "DATA", "CYBER", "PUNK"],
    ["BREATHE", "CALM", "PEACE", "ZEN", "AURA"],
    ["0", "1", "10", "11", "01"],
  ];

  static final List<Color> _bgColors = [
    const Color(0xFF0F0F0F),
    const Color(0xFF1A1A2E),
    const Color(0xFF222831),
    const Color(0xFF121212),
    const Color(0xFF000000),
  ];

  static final List<Color> _vibrantColors = [
    const Color(0xFFFF007F), // Neon Pink
    const Color(0xFF00F0FF), // Cyan
    const Color(0xFFFFD700), // Gold
    const Color(0xFF39FF14), // Neon Green
    const Color(0xFFFF3131), // Neon Red
    const Color(0xFFB026FF), // Neon Purple
    const Color(0xFFFFFFFF), // White
  ];

  static QuoteState generate() {
    Color bg = _bgColors[_r.nextInt(_bgColors.length)];
    Color p1 = _vibrantColors[_r.nextInt(_vibrantColors.length)];
    Color p2 = _vibrantColors[_r.nextInt(_vibrantColors.length)];
    
    // Ensure primary and accent are not exactly the same visually (rough check)
    if (p1 == p2) p2 = Colors.white;

    QuoteStyle randStyle = QuoteStyle.values[_r.nextInt(QuoteStyle.values.length)];
    
    double fSize = 40.0 + _r.nextDouble() * 60.0;
    double den = 50.0 + _r.nextDouble() * 100.0;
    
    List<String> selectedWords = _wordSets[_r.nextInt(_wordSets.length)];

    return QuoteState(
      bgColor: bg,
      primaryColor: p1,
      accentColor: p2,
      style: randStyle,
      fontSize: fSize,
      density: den,
      texts: selectedWords,
    );
  }
}
