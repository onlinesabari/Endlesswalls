import 'dart:math';
import 'package:flutter/material.dart';
import 'ripple_layout.dart';

class WaveLayout {
  static List<RippleItem> generate({
    required double canvasWidth,
    required double canvasHeight,
    required int count,
    required double itemSize,
    required double padding,
    required double amplitude, 
    required double frequency, 
    required bool flowRotation, 
    required int waveCount, // NEW: Support up to 5 waves
    required double globalRotationDegrees, // NEW: Rotates the entire wave structure
  }) {
    List<RippleItem> items = [];
    
    double cx = canvasWidth / 2;
    double cy = canvasHeight / 2;
    double globalTheta = globalRotationDegrees * (pi / 180);

    // Calculate items per wave to distribute them evenly
    int itemsPerWave = (count / waveCount).ceil();
    if (itemsPerWave == 0) itemsPerWave = 1;

    // Horizontally space out the parallel waves
    double waveSpacing = canvasWidth / (waveCount + 1);
    
    double spacing = itemSize + padding;
    double totalHeight = (itemsPerWave - 1) * spacing;
    double startY = cy - (totalHeight / 2);

    int added = 0;

    for (int w = 0; w < waveCount; w++) {
      double currentCenterX = waveSpacing * (w + 1);

      for (int i = 0; i < itemsPerWave; i++) {
        if (added >= count) break; // Don't exceed total user item count

        double y = startY + (i * spacing);
        double scaledY = y * 0.01;
        double x = currentCenterX + amplitude * sin(frequency * scaledY);

        // Calculus Derivative for icon Rotation
        double itemAngle = 0;
        if (flowRotation) {
          double derivative = amplitude * frequency * 0.01 * cos(frequency * scaledY);
          itemAngle = atan2(derivative, 1.0); 
        }

        // Apply Global 2D Rotation around the exact center of the screen
        double dx = x - cx;
        double dy = y - cy;

        double rotX = cx + (dx * cos(globalTheta)) - (dy * sin(globalTheta));
        double rotY = cy + (dx * sin(globalTheta)) + (dy * cos(globalTheta));

        // Point the icon along the curve, factoring in the global canvas spin
        double finalAngle = itemAngle + globalTheta;

        items.add(RippleItem(
          position: Offset(rotX, rotY),
          size: itemSize,
          angleRadians: finalAngle,
        ));
        added++;
      }
    }
    return items;
  }
}