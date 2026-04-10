import 'package:flutter/rendering.dart';

import 'drawable.dart';

class CanvasPainter extends CustomPainter {
  final List<Drawable> drawables;
  final String? selectedId;

  CanvasPainter({required this.drawables, required this.selectedId});

  @override
  void paint(Canvas canvas, Size size) {
    for (var drawable in drawables) {
      drawable.draw(canvas);
      if (selectedId != null && drawable.id == selectedId) {
        final highlight = Paint()
          ..color = const Color(0x992196F3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawRect(drawable.bounds.inflate(4), highlight);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
