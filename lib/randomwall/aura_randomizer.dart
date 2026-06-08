import 'dart:math';
import 'package:flutter/material.dart';
import '../services/aura_engine.dart';

class AuraRandomState {
  final List<AuraOrb> orbs;
  final Color bgColor;
  final double blurRadius;

  AuraRandomState({
    required this.orbs, 
    required this.bgColor, 
    required this.blurRadius
  });
}

class AuraRandomizer {
  static final Random _rnd = Random();

  static Color _randomColor() {
    return Color.fromARGB(
      255, _rnd.nextInt(256), _rnd.nextInt(256), _rnd.nextInt(256)
    );
  }

  static AuraRandomState generate() {
    // Generate between 3 and 6 glowing orbs
    int numOrbs = _rnd.nextInt(4) + 3; 
    List<AuraOrb> generatedOrbs = [];

    for (int i = 0; i < numOrbs; i++) {
      generatedOrbs.add(
        AuraOrb(
          x: _rnd.nextDouble() * 1080,         // Anywhere horizontally
          y: _rnd.nextDouble() * 1920,         // Anywhere vertically
          radius: _rnd.nextDouble() * 500 + 300, // Massive sizes (300 to 800)
          color: _randomColor(),
        )
      );
    }

    return AuraRandomState(
      orbs: generatedOrbs,
      // Usually looks best with a dark background to make colors pop
      bgColor: const Color(0xFF0F0F0F), 
      // High blur to melt them together
      blurRadius: _rnd.nextDouble() * 200 + 150, // Between 150 and 350
    );
  }
}