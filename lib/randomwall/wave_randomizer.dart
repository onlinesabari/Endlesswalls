import 'dart:math';
import 'package:flutter/material.dart';
import '../services/wave_engine.dart';

// A simple container to hold the random results
class WaveRandomState {
  final List<WaveLayer> layers;
  final Color bgColor;
  final bool enableTransparency;

  WaveRandomState({
    required this.layers,
    required this.bgColor,
    required this.enableTransparency,
  });
}

class WaveRandomizer {
  static final Random _rnd = Random();
  static final List<String> _types = ['Sine', 'Bezier', 'ZigZag'];

  // Generates a literally infinite combination of colors
  static Color _randomColor() {
    return Color.fromARGB(
      255,
      _rnd.nextInt(256), // Red
      _rnd.nextInt(256), // Green
      _rnd.nextInt(256), // Blue
    );
  }

  static WaveRandomState generate() {
    int numLayers = _rnd.nextInt(3) + 1; // Generates between 1 and 5 waves
    List<WaveLayer> generatedLayers = [];
    bool hasRotation = false;

    for (int i = 0; i < numLayers; i++) {
      // 50% chance this specific wave will be rotated
      bool applyRotation = _rnd.nextBool(); 
      double rot = applyRotation ? (_rnd.nextDouble() * 180 - 90) : 0.0; // Between -90° and 90°
      
      if (rot != 0) hasRotation = true;

      generatedLayers.add(
        WaveLayer(
          type: _types[_rnd.nextInt(_types.length)],
          color: _randomColor(),
          amplitude: _rnd.nextDouble() * 200 + 20, // Height between 20 and 220
          frequency: _rnd.nextDouble() * 12 + 1,   // Loops between 1 and 13
          verticalPosition: _rnd.nextDouble() * 1400 + 200, // Position between 200 and 1600
          rotation: rot,
        )
      );
    }

    // Sort the layers so the lowest ones on the screen draw first (looks much better)
    generatedLayers.sort((a, b) => b.verticalPosition.compareTo(a.verticalPosition));

    // The Transparency Rule: 5 out of 10 chance (50%) if rotations are present
    bool transparency = false;
    if (hasRotation) {
      transparency = _rnd.nextBool(); // 50% chance
    } else {
      transparency = _rnd.nextBool(); // Keeps it random for flat waves too
    }

    return WaveRandomState(
      layers: generatedLayers,
      bgColor: _randomColor(),
      enableTransparency: transparency,
    );
  }
}