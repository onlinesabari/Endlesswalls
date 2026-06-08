import 'dart:math';
import 'package:flutter/material.dart';
import 'ripple_layout.dart';

class HoneycombLayout {
  static List<RippleItem> generate({
    required double canvasWidth,
    required double canvasHeight,
    required int rows,
    required int columns,
    required double itemSize,
    required double padding,
    required bool applyFisheye, 
    required double globalRotationDegrees, // <--- NEW: Added rotation parameter
  }) {
    List<RippleItem> items = [];
    
    double hSpacing = itemSize + padding;
    double vSpacing = (itemSize + padding) * 0.866025; // sin(60°)

    double totalWidth = (columns - 1) * hSpacing + (hSpacing / 2);
    double totalHeight = (rows - 1) * vSpacing;

    double startX = (canvasWidth - totalWidth) / 2 + (itemSize / 2);
    double startY = (canvasHeight - totalHeight) / 2 + (itemSize / 2);
    
    Offset screenCenter = Offset(canvasWidth / 2, canvasHeight / 2);
    double maxDist = sqrt(pow(canvasWidth / 2, 2) + pow(canvasHeight / 2, 2));
    
    // Convert degrees to radians for math
    double theta = globalRotationDegrees * (pi / 180);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        double x = startX + (c * hSpacing);
        if (r % 2 != 0) x += hSpacing / 2; 
        
        double y = startY + (r * vSpacing);
        Offset basePos = Offset(x, y);

        double finalSize = itemSize;
        if (applyFisheye) {
          double dist = (basePos - screenCenter).distance;
          double scale = 1.5 - (0.8 * (dist / maxDist));
          finalSize = itemSize * scale.clamp(0.5, 2.0);
        }

        // --- NEW: 2D Rotation Matrix ---
        // Rotates the entire grid around the exact center of the canvas
        double dx = basePos.dx - screenCenter.dx;
        double dy = basePos.dy - screenCenter.dy;

        double rotX = screenCenter.dx + (dx * cos(theta)) - (dy * sin(theta));
        double rotY = screenCenter.dy + (dx * sin(theta)) + (dy * cos(theta));

        items.add(RippleItem(
          position: Offset(rotX, rotY),
          size: finalSize,
          angleRadians: theta, // Rotates the individual items to match the grid
        ));
      }
    }
    return items;
  }
}