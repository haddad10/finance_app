import 'package:flutter/material.dart';

class DotGridPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;
  final double dotSize;

  DotGridPainter({
    this.dotColor = const Color(0x33000000), // 20% black default
    this.spacing = 16.0,
    this.dotSize = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Diagonal Hatching Lines
    final hatchColor = dotColor.withAlpha((dotColor.alpha * 0.7).toInt());
    final hatchPaint = Paint()
      ..color = hatchColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw diagonal lines from top-right to bottom-left
    for (double i = -size.height; i < size.width; i += spacing * 1.2) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        hatchPaint,
      );
    }

    // 2. Draw Dots
    final dotColorEnhanced = dotColor.withAlpha((dotColor.alpha * 1.5).clamp(0, 255).toInt());
    final dotPaint = Paint()
      ..color = dotColorEnhanced
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotGridPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        oldDelegate.spacing != spacing ||
        oldDelegate.dotSize != dotSize;
  }
}
