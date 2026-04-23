import 'dart:math';
import 'package:flutter/material.dart';

class DiskNode {
  final String name;
  final int sizeKb;
  final List<DiskNode> children;

  const DiskNode({
    required this.name,
    required this.sizeKb,
    this.children = const [],
  });

  int get totalKb =>
      children.isEmpty ? sizeKb : children.fold(0, (s, c) => s + c.totalKb);
}

class DiskUsagePainter extends CustomPainter {
  final DiskNode root;
  final int maxDepth;

  static const _palette = [
    Color(0xFF4285F4),
    Color(0xFF34A853),
    Color(0xFFFBBC04),
    Color(0xFFEA4335),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF607D8B),
    Color(0xFF795548),
    Color(0xFF009688),
    Color(0xFF3F51B5),
    Color(0xFFE91E63),
  ];

  const DiskUsagePainter({required this.root, this.maxDepth = 4});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = min(size.width, size.height) / 2 - 4;
    final ringW = maxR / maxDepth;

    // Center circle
    canvas.drawCircle(
      center,
      ringW * 0.85,
      Paint()..color = Colors.grey.shade200,
    );

    _drawRing(canvas, root, center, -pi / 2, 2 * pi, 0, ringW, 0);

    // Center label
    _drawText(canvas, root.name, center, 9, Colors.black54,
        maxWidth: ringW * 1.6);
  }

  void _drawRing(
    Canvas canvas,
    DiskNode node,
    Offset center,
    double startAngle,
    double sweep,
    int depth,
    double ringW,
    int colorOffset,
  ) {
    if (depth >= maxDepth || node.children.isEmpty) return;

    final innerR = depth * ringW + ringW * 0.85;
    final outerR = (depth + 1) * ringW;
    final total = node.children.fold(0, (s, c) => s + c.totalKb);
    if (total == 0) return;

    double angle = startAngle;
    for (int i = 0; i < node.children.length; i++) {
      final child = node.children[i];
      final childSweep = sweep * child.totalKb / total;
      if (childSweep < 0.005) {
        angle += childSweep;
        continue;
      }

      final color = _palette[(colorOffset + i) % _palette.length];
      _drawSegment(canvas, center, innerR, outerR, angle, childSweep, color);

      if (childSweep > 0.18) {
        final mid = angle + childSweep / 2;
        final midR = (innerR + outerR) / 2;
        final pos =
            Offset(center.dx + midR * cos(mid), center.dy + midR * sin(mid));
        final label = child.name.length > 9
            ? '${child.name.substring(0, 8)}…'
            : child.name;
        _drawText(canvas, label, pos, 8, Colors.white);
      }

      _drawRing(canvas, child, center, angle, childSweep, depth + 1, ringW,
          (colorOffset + i * 4) % _palette.length);
      angle += childSweep;
    }
  }

  void _drawSegment(Canvas canvas, Offset center, double innerR, double outerR,
      double startAngle, double sweep, Color color) {
    final outerRect = Rect.fromCircle(center: center, radius: outerR);
    final innerRect = Rect.fromCircle(center: center, radius: innerR);

    final path = Path()
      ..moveTo(center.dx + innerR * cos(startAngle),
          center.dy + innerR * sin(startAngle))
      ..arcTo(outerRect, startAngle, sweep, false)
      ..lineTo(center.dx + innerR * cos(startAngle + sweep),
          center.dy + innerR * sin(startAngle + sweep))
      ..arcTo(innerRect, startAngle + sweep, -sweep, false)
      ..close();

    canvas.drawPath(path, Paint()..color = color.withAlpha(220));
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  void _drawText(Canvas canvas, String text, Offset center, double fontSize,
      Color color, {double? maxWidth}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text, style: TextStyle(fontSize: fontSize, color: color)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth ?? 200);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(DiskUsagePainter old) => old.root != root;
}

class DiskUsageWidget extends StatelessWidget {
  final DiskNode? root;
  final double size;

  const DiskUsageWidget({super.key, this.root, this.size = 320});

  @override
  Widget build(BuildContext context) {
    if (root == null) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(child: Text('Sense dades de disc')),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: DiskUsagePainter(root: root!)),
    );
  }
}
