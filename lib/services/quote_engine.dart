import 'dart:ui' as ui;
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

enum QuoteStyle { matrix, scattered, grid }

class QuoteEngine {
  static Future<File> generate({
    required List<String> texts,
    required Color bgColor,
    required Color primaryColor,
    required Color accentColor,
    required QuoteStyle style,
    required double fontSize,
    required double density,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const width = 1080.0;
    const height = 1920.0;
    final r = Random();

    // 1. Draw Background
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, height),
      Paint()..color = bgColor,
    );

    if (texts.isEmpty) texts = ["DESIGN", "CREATE", "INSPIRE", "ART", "FLOW"];

    // 2. Render Based on Style
    switch (style) {
      case QuoteStyle.matrix:
        _drawMatrixRain(canvas, width, height, texts, primaryColor, accentColor, fontSize, density, r);
        break;
      case QuoteStyle.scattered:
        _drawScattered(canvas, width, height, texts, primaryColor, accentColor, fontSize, density, r);
        break;
      case QuoteStyle.grid:
        _drawGrid(canvas, width, height, texts, primaryColor, accentColor, fontSize, density, r);
        break;
    }

    // 3. Save and return
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${(await getTemporaryDirectory()).path}/quote_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());

    return file;
  }

  static void _drawMatrixRain(Canvas canvas, double width, double height, List<String> texts, Color primary, Color accent, double baseFontSize, double density, Random r) {
    int columns = (width / (baseFontSize * 1.5)).floor();
    int count = (columns * density / 50).floor().clamp(10, 100);

    for (int i = 0; i < count; i++) {
      double x = r.nextDouble() * width;
      double y = r.nextDouble() * height - (height / 2);
      int length = r.nextInt(15) + 5;
      
      for (int j = 0; j < length; j++) {
        String char = texts[r.nextInt(texts.length)];
        // Use a single character for Matrix effect
        if (char.length > 1) {
          char = char[r.nextInt(char.length)];
        }

        double alpha = 1.0 - (j / length);
        Color color = r.nextBool() ? primary : accent;
        color = color.withOpacity(alpha);

        final span = TextSpan(
          text: char,
          style: TextStyle(
            color: color,
            fontSize: baseFontSize * (0.8 + r.nextDouble() * 0.4),
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        );

        final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(x, y + j * (baseFontSize * 1.2)));
      }
    }
  }

  static void _drawScattered(Canvas canvas, double width, double height, List<String> texts, Color primary, Color accent, double baseFontSize, double density, Random r) {
    int count = (density).toInt();
    
    for (int i = 0; i < count; i++) {
      String text = texts[r.nextInt(texts.length)];
      double x = r.nextDouble() * width - (width * 0.2);
      double y = r.nextDouble() * height - (height * 0.2);
      double rotation = (r.nextDouble() * 2 * pi) - pi;
      
      Color color = (r.nextDouble() > 0.7 ? accent : primary).withOpacity(0.3 + r.nextDouble() * 0.7);
      
      final span = TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: baseFontSize * (0.5 + r.nextDouble() * 2.5), // highly varied sizes
          fontWeight: FontWeight.w900,
          letterSpacing: r.nextDouble() * 10,
        ),
      );

      final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();

      canvas.save();
      canvas.translate(x + tp.width / 2, y + tp.height / 2);
      canvas.rotate(rotation);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  static void _drawGrid(Canvas canvas, double width, double height, List<String> texts, Color primary, Color accent, double baseFontSize, double density, Random r) {
    int rows = (density / 10).clamp(5, 30).toInt();
    int cols = 3;
    
    double stepY = height / rows;
    double stepX = width / cols;

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        // Skip some grid cells randomly for a more dynamic look
        if (r.nextDouble() > 0.8) continue;

        String text = texts[r.nextInt(texts.length)];
        Color color = r.nextBool() ? primary : accent;
        color = color.withOpacity(0.4 + r.nextDouble() * 0.6);

        final span = TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: baseFontSize,
            fontWeight: FontWeight.w700,
          ),
        );

        final tp = TextPainter(text: span, textDirection: TextDirection.ltr, textAlign: TextAlign.center);
        tp.layout(maxWidth: stepX);

        double x = (j * stepX) + (stepX - tp.width) / 2;
        double y = (i * stepY) + (stepY - tp.height) / 2;
        
        // Slight random offset
        x += (r.nextDouble() - 0.5) * 20;
        y += (r.nextDouble() - 0.5) * 20;

        tp.paint(canvas, Offset(x, y));
      }
    }
  }
}
