import 'dart:ui' as ui;
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class GeometryLayer {
  int sides;
  Color color;
  double size;
  double rotation;
  bool isStroke;
  double x;
  double y;
  
  String shapeType; 
  double skewX;
  double skewY;
  double sweepAngle;       // 0 to 360 degrees (for Circle and Ring)
  double innerRadiusRatio;
  double scaleX; // Breadth (Width multiplier)
  double scaleY; // Length (Height multiplier)

  GeometryLayer({
    required this.sides,
    required this.color,
    this.size = 300,
    this.rotation = 0,
    this.isStroke = false,
    this.x = 540,
    this.y = 960,
    this.shapeType = 'polygon',
    this.skewX = 0.0,
    this.skewY = 0.0,
    this.sweepAngle = 360.0,
    this.innerRadiusRatio = 0.5,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
  });
}

class GeometryEngine {
  static Future<File> generate(
    List<GeometryLayer> layers, 
    Color bgColor, 
    bool enableTransparency
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const width = 1080.0;
    const height = 1920.0;
    final rect = const Rect.fromLTWH(0, 0, width, height);
    
    // 1. Paint SOLID Background first
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(rect, bgPaint);

    // 2. ISOLATE SHAPES: This prevents them from blending with the background
    if (enableTransparency) {
      // Creates an off-screen transparent buffer just for the shapes
      canvas.saveLayer(rect, Paint());
    }

    // 3. Draw Geometry Layers
    for (int i = 0; i < layers.length; i++) {
      var layer = layers[i];
      final shapePaint = Paint()
        ..style = layer.isStroke ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = 5.0
        ..isAntiAlias = true;

      // Force the shape to be 100% solid so the background cannot bleed through
      shapePaint.color = layer.color.withOpacity(1.0);

      // Blend Mode
      if (enableTransparency && i > 0) {
        // Exclusion creates stunning, high-contrast abstract intersections
        shapePaint.blendMode = BlendMode.exclusion; 
      }

      // --- CANVAS TRANSFORMS ---
      canvas.save();
      
      canvas.translate(layer.x, layer.y);
      canvas.rotate(layer.rotation * (pi / 180));
      // NEW: Scale transform stretches the shape to create rectangles, ovals, etc!
      canvas.scale(layer.scaleX, layer.scaleY);
      
      if (layer.skewX != 0 || layer.skewY != 0) {
        Float64List skewMatrix = Float64List.fromList([
          1.0, layer.skewY, 0.0, 0.0,
          layer.skewX, 1.0, 0.0, 0.0,
          0.0, 0.0, 1.0, 0.0,
          0.0, 0.0, 0.0, 1.0,
        ]);
        canvas.transform(skewMatrix);
      }

      // --- DRAW SHAPES ---
      double radius = layer.size / 2;
      double sweepRad = layer.sweepAngle * (pi / 180);

      switch (layer.shapeType) {
        case 'circle':
          // Drawing an arc starting from the top (-pi/2)
          final arcRect = Rect.fromCircle(center: Offset.zero, radius: radius);
          canvas.drawArc(arcRect, -pi / 2, sweepRad, true, shapePaint);
          break;
         
        case 'ring':
          _drawRing(canvas, radius, layer.innerRadiusRatio, layer.sweepAngle, shapePaint);
          break;
          
        case 'rectangle':
         // Starts as a square, but layer.scaleX and scaleY make it a rectangle!
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: layer.size, height: layer.size), shapePaint);
          break;
          
        case 'star':
          _drawStar(canvas, layer.sides, radius, layer.innerRadiusRatio, shapePaint);
          break;
          
        case 'cross':
          _drawCross(canvas, layer.size, layer.innerRadiusRatio, shapePaint);
          break;
          
        case 'polygon':
        default:
          _drawPolygon(canvas, Offset.zero, layer.sides, radius, 0, shapePaint);
          break;
      }
      
      canvas.restore();
    }

    // 4. FLATTEN: Stamp the isolated, blended shapes onto the solid background
    if (enableTransparency) {
      canvas.restore();
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${(await getTemporaryDirectory()).path}/geom_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());
    return file;
  }

  static void _drawPolygon(Canvas canvas, Offset center, int sides, double radius, double rotation, Paint paint) {
    final path = Path();
    double angle = (2 * pi) / sides;
// Offset by -pi/2 so polygons (like triangles) point straight up
    for (int i = 0; i <= sides; i++) {
      double x = center.dx + radius * cos(angle * i - (pi / 2) + rotation);
      double y = center.dy + radius * sin(angle * i - (pi / 2) + rotation);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
  
  static void _drawRing(Canvas canvas, double outerRadius, double innerRatio, double sweepAngleDeg, Paint paint) {
    final path = Path();
    double innerRadius = outerRadius * innerRatio;
    double sweepAngle = sweepAngleDeg * (pi / 180);
    double startAngle = -pi / 2; // Start at the top

    Rect outerRect = Rect.fromCircle(center: Offset.zero, radius: outerRadius);
    Rect innerRect = Rect.fromCircle(center: Offset.zero, radius: innerRadius);

    if (sweepAngleDeg >= 360) {
      // Full Donut
      path.addOval(outerRect);
      path.addOval(innerRect);
      path.fillType = PathFillType.evenOdd;
    } else {
      // Sweepable Arc Donut
      path.arcTo(outerRect, startAngle, sweepAngle, false);
      path.arcTo(innerRect, startAngle + sweepAngle, -sweepAngle, false);
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  static void _drawStar(Canvas canvas, int points, double outerRadius, double innerRatio, Paint paint) {
    final path = Path();
    double innerRadius = outerRadius * innerRatio;
    double angleStep = pi / points;
    double currentAngle = -pi / 2; // Start at top

    for (int i = 0; i < points * 2; i++) {
      double r = (i % 2 == 0) ? outerRadius : innerRadius;
      double x = r * cos(currentAngle);
      double y = r * sin(currentAngle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      currentAngle += angleStep;
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  static void _drawCross(Canvas canvas, double size, double thicknessRatio, Paint paint) {
    final path = Path();
    double halfSize = size / 2;
    double halfThick = (size * thicknessRatio) / 2;

    path.moveTo(-halfThick, -halfSize);
    path.lineTo(halfThick, -halfSize);
    path.lineTo(halfThick, -halfThick);
    path.lineTo(halfSize, -halfThick);
    path.lineTo(halfSize, halfThick);
    path.lineTo(halfThick, halfThick);
    path.lineTo(halfThick, halfSize);
    path.lineTo(-halfThick, halfSize);
    path.lineTo(-halfThick, halfThick);
    path.lineTo(-halfSize, halfThick);
    path.lineTo(-halfSize, -halfThick);
    path.lineTo(-halfThick, -halfThick);
    path.close();
    
    canvas.drawPath(path, paint);
  }
}