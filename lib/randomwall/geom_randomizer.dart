import 'dart:math';
import 'package:flutter/material.dart';
import '../services/geometry_engine.dart'; 

class GeomRandomState {
  final List<GeometryLayer> layers;
  final Color bgColor;
  final bool enableTransparency;

  GeomRandomState({
    required this.layers,
    required this.bgColor,
    required this.enableTransparency,
  });
}

class GeomRandomizer {
  static final Random _rnd = Random();

  // RULE 1: Hand-crafted, aesthetically pleasing color palettes
  static final List<Map<String, dynamic>> _designerPalettes = [
    { // Cyberpunk Neon
      'bg': const Color(0xFF0D0221), 
      'colors': [const Color(0xFF00F0FF), const Color(0xFFFF007F), const Color(0xFF7000FF), const Color(0xFFFEEA00)]
    },
    { // Retro Sunset / Vaporwave
      'bg': const Color(0xFF2A0845),
      'colors': [const Color(0xFFFF512F), const Color(0xFFDD2476), const Color(0xFFFF9A44), const Color(0xFFF6416C)]
    },
    { // Minimalist Bauhaus
      'bg': const Color(0xFFF4F4F4), // Off-white
      'colors': [const Color(0xFFE63946), const Color(0xFF1D3557), const Color(0xFFF4A261), const Color(0xFF2A9D8F), const Color(0xFF000000)]
    },
    { // Deep Ocean
      'bg': const Color(0xFF001524),
      'colors': [const Color(0xFF15616D), const Color(0xFFFFECD1), const Color(0xFFFF7D00), const Color(0xFF78290F)]
    },
    { // Muted Sage & Clay
      'bg': const Color(0xFF2F3E46),
      'colors': [const Color(0xFFCAD2C5), const Color(0xFF84A98C), const Color(0xFF52796F), const Color(0xFFE07A5F)]
    }
  ];

  static GeomRandomState generate() {
    // Pick one cohesive palette for this entire generation
    var activeTheme = _designerPalettes[_rnd.nextInt(_designerPalettes.length)];
    Color bgColor = activeTheme['bg'];
    List<Color> paletteColors = activeTheme['colors'];

    int numShapes = _rnd.nextInt(4) + 3; // 3 to 6 shapes is the sweet spot for balance
    List<GeometryLayer> generatedLayers = [];
    
    List<String> availableShapes = ['polygon', 'circle', 'ring', 'rectangle', 'star', 'cross'];
    List<double> funAngles = [90.0, 180.0, 270.0, 360.0]; 

    for (int i = 0; i < numShapes; i++) {
      String randomShape = availableShapes[_rnd.nextInt(availableShapes.length)];
      
      // RULE 2: Size Hierarchy
      double size;
      if (i == 0) {
        // First shape is always a massive background "Hero" element
        size = _rnd.nextDouble() * 400 + 800; 
      } else if (i == numShapes - 1) {
        // Last shape is always a tiny, floating accent element
        size = _rnd.nextDouble() * 150 + 50; 
      } else {
        // Middle shapes are medium sized
        size = _rnd.nextDouble() * 400 + 200; 
      }
      
      double randScaleX = _rnd.nextInt(10) > 3 ? 1.0 : (_rnd.nextDouble() * 2.0 + 0.5);
      double randScaleY = _rnd.nextInt(10) > 3 ? 1.0 : (_rnd.nextDouble() * 2.0 + 0.5);
      
      double randSkewX = _rnd.nextInt(10) > 7 ? (_rnd.nextDouble() * 1.6 - 0.8) : 0.0;
      double randSkewY = _rnd.nextInt(10) > 7 ? (_rnd.nextDouble() * 1.6 - 0.8) : 0.0;

      double randSweep = _rnd.nextBool() ? 360.0 : funAngles[_rnd.nextInt(funAngles.length)];
      bool randStroke = _rnd.nextDouble() < 0.20; // 20% chance for an outline

      // Pull a random color ONLY from our curated theme
      Color shapeColor = paletteColors[_rnd.nextInt(paletteColors.length)];

      generatedLayers.add(
        GeometryLayer(
          shapeType: randomShape,
          sides: _rnd.nextInt(8) + 3, // 3 to 10 sides
          color: shapeColor,
          size: size, 
          rotation: _rnd.nextDouble() * 360 - 180, 
          isStroke: randStroke, 
          // Keep shapes generally centered so they don't spawn off-screen
          x: _rnd.nextDouble() * 600 + 240, 
          y: _rnd.nextDouble() * 1000 + 460,
          scaleX: randScaleX,
          scaleY: randScaleY,
          skewX: randSkewX,
          skewY: randSkewY,
          sweepAngle: randSweep,
          innerRadiusRatio: _rnd.nextDouble() * 0.6 + 0.3, 
        )
      );
    }

    return GeomRandomState(
      layers: generatedLayers,
      bgColor: bgColor, // Use the theme's designated background color
      enableTransparency: _rnd.nextInt(10) > 2, 
    );
  }
}