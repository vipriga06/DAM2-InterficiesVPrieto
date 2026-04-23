import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  final bool active;
  final double size;

  const StatusIndicator({super.key, required this.active, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _StatusPainter(active: active),
    );
  }
}

class _StatusPainter extends CustomPainter {
  final bool active;
  const _StatusPainter({required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final color = active ? Colors.green : Colors.red;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer glow
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withAlpha(60)
        ..style = PaintingStyle.fill,
    );

    // Solid circle
    canvas.drawCircle(
      center,
      radius * 0.75,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_StatusPainter old) => old.active != active;
}
