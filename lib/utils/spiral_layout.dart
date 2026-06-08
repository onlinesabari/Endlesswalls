import 'dart:math';
import 'package:flutter/material.dart';
import 'ripple_layout.dart'; 

class SpiralLayout {
  static List<RippleItem> generate({
    required double canvasWidth,
    required double canvasHeight,
    required int count,
    required double baseItemSize,
    required double spacingFactor, 
    required double padding, // <--- NEW: Padding parameter added
    required bool scaleOutward, 
    double baseRotationDegrees = 0,
  }) {
    List<RippleItem> items = [];
    Offset center = Offset(canvasWidth / 2, canvasHeight / 2);
    
    // The Golden Angle for perfect organic packing
    const double goldenAngle = 137.507764 * (pi / 180);

    // Integrate padding into the expansion rate of the spiral.
    // We multiply by 0.5 so the slider feels smooth and doesn't explode the spiral instantly.
    double actualSpacing = spacingFactor + (padding * 0.5);

    for (int i = 0; i < count; i++) {
      // Radius now grows based on the combined spacing and padding
      double r = actualSpacing * sqrt(i); 
      double theta = i * goldenAngle;

      double x = center.dx + r * cos(theta);
      double y = center.dy + r * sin(theta);

      double sizeMult = scaleOutward ? (0.5 + (i / count)) : 1.0;
      double finalSize = baseItemSize * sizeMult;

      double tangentAngle = theta + (pi / 2) + (baseRotationDegrees * pi / 180);

      items.add(RippleItem(
        position: Offset(x, y),
        size: finalSize,
        angleRadians: tangentAngle,
        isCenter: i == 0,
      ));
    }
    return items;
  }
}