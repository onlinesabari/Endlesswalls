import 'dart:math';
import 'package:flutter/material.dart';

class RippleItem {
  final Offset position;
  final double size;
  final double angleRadians;
  final bool isCenter;

  RippleItem({
    required this.position,
    required this.size,
    required this.angleRadians,
    this.isCenter = false,
  });
}

class RippleLayout {
  /// Generates a list of coordinates for a perfectly packed concentric ripple pattern.
  static List<RippleItem> generate({
    required double canvasWidth,
    required double canvasHeight,
    required double centerSize,
    required double itemSize,
    required double gap,
    required double baseRotationDegrees,
  }) {
    List<RippleItem> items = [];
    Offset center = Offset(canvasWidth / 2, canvasHeight / 2);
    double baseRotationRad = baseRotationDegrees * (pi / 180);

    // 1. Add the Hero Item in the dead center
    items.add(RippleItem(
      position: center,
      size: centerSize,
      angleRadians: baseRotationRad,
      isCenter: true,
    ));

    // Calculate how far the ripples need to expand to cover the screen corners
    double maxRadius = sqrt(pow(canvasWidth / 2, 2) + pow(canvasHeight / 2, 2)) + itemSize;

    // 2. Calculate expanding rings
    double currentRadius = (centerSize / 2) + gap + (itemSize / 2);
    int ringNumber = 1;

    while (currentRadius < maxRadius) {
      double itemTotalSize = itemSize + gap;
      int itemsInThisRing;
      
      if (currentRadius < itemTotalSize / 2) {
        itemsInThisRing = 1;
      } else {
        // Trigonometry to perfectly pack items without overlapping
        double theta = 2 * asin((itemTotalSize / 2) / currentRadius);
        itemsInThisRing = ((2 * pi) / theta).floor(); 
      }

      if (itemsInThisRing < 1) itemsInThisRing = 1;

      double angleStep = (2 * pi) / itemsInThisRing;
      double ringOffset = (ringNumber % 2 == 0) ? (angleStep / 2) : 0; // Interlocking stagger

      for (int j = 0; j < itemsInThisRing; j++) {
        double angle = (j * angleStep) + ringOffset + baseRotationRad;
        Offset ringPos = Offset(
          center.dx + currentRadius * cos(angle), 
          center.dy + currentRadius * sin(angle)
        );

        items.add(RippleItem(
          position: ringPos,
          size: itemSize,
          angleRadians: angle,
        ));
      }
      
      // Expand radius for the next ripple ring
      currentRadius += itemSize + gap;
      ringNumber++;
    }

    return items;
  }
}