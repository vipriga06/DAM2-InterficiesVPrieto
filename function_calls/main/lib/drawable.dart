import 'package:flutter/material.dart';
import 'dart:math' as math;

abstract class Drawable {
  final String id;

  Drawable({required this.id});

  void draw(Canvas canvas);
  bool hitTest(Offset point);
  Rect get bounds;
}

enum FillMode { none, solid, linear, radial }

class FillStyle {
  final FillMode mode;
  final Color colorA;
  final Color colorB;
  final double angleDegrees;

  const FillStyle({
    this.mode = FillMode.none,
    this.colorA = Colors.transparent,
    this.colorB = Colors.transparent,
    this.angleDegrees = 45,
  });

  FillStyle copyWith({
    FillMode? mode,
    Color? colorA,
    Color? colorB,
    double? angleDegrees,
  }) {
    return FillStyle(
      mode: mode ?? this.mode,
      colorA: colorA ?? this.colorA,
      colorB: colorB ?? this.colorB,
      angleDegrees: angleDegrees ?? this.angleDegrees,
    );
  }
}

class Line extends Drawable {
  Offset start;
  Offset end;
  Color strokeColor;
  double strokeWidth;

  Line({
    required super.id,
    required this.start,
    required this.end,
    this.strokeColor = Colors.black,
    this.strokeWidth = 2.0,
  });

  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth;
    canvas.drawLine(start, end, paint);
  }

  @override
  bool hitTest(Offset point) {
    final dist = _distancePointToSegment(point, start, end);
    return dist <= math.max(6, strokeWidth + 4);
  }

  @override
  Rect get bounds => Rect.fromPoints(start, end).inflate(strokeWidth + 4);
}

class Rectangle extends Drawable {
  Offset topLeft;
  Offset bottomRight;
  Color strokeColor;
  double strokeWidth;
  FillStyle fill;

  Rectangle({
    required super.id,
    required this.topLeft,
    required this.bottomRight,
    this.strokeColor = Colors.black,
    this.strokeWidth = 2.0,
    this.fill = const FillStyle(),
  });

  @override
  void draw(Canvas canvas) {
    final rect = Rect.fromPoints(topLeft, bottomRight);
    final fillPaint = _buildFillPaint(fill, rect);
    if (fillPaint != null) {
      canvas.drawRect(rect, fillPaint);
    }

    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, strokePaint);
  }

  @override
  bool hitTest(Offset point) =>
      Rect.fromPoints(topLeft, bottomRight).contains(point);

  @override
  Rect get bounds =>
      Rect.fromPoints(topLeft, bottomRight).inflate(strokeWidth + 4);
}

class Circle extends Drawable {
  Offset center;
  double radius;
  Color strokeColor;
  double strokeWidth;
  FillStyle fill;

  Circle({
    required super.id,
    required this.center,
    required this.radius,
    this.strokeColor = Colors.black,
    this.strokeWidth = 2.0,
    this.fill =
        const FillStyle(mode: FillMode.solid, colorA: Color(0xFFB3E5FC)),
  });

  @override
  void draw(Canvas canvas) {
    final circleRect = Rect.fromCircle(center: center, radius: radius);
    final fillPaint = _buildFillPaint(fill, circleRect);
    if (fillPaint != null) {
      canvas.drawCircle(center, radius, fillPaint);
    }

    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, strokePaint);
  }

  @override
  bool hitTest(Offset point) =>
      (point - center).distance <= radius + strokeWidth;

  @override
  Rect get bounds =>
      Rect.fromCircle(center: center, radius: radius + strokeWidth + 4);
}

class TextElement extends Drawable {
  String text;
  Offset position;
  Color color;
  double fontSize;
  String fontFamily;
  FontWeight fontWeight;
  FontStyle fontStyle;

  TextElement({
    required super.id,
    required this.text,
    required this.position,
    this.color = Colors.black,
    this.fontSize = 14.0,
    this.fontFamily = 'Roboto',
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
  });

  @override
  void draw(Canvas canvas) {
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
    );
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool hitTest(Offset point) => bounds.contains(point);

  @override
  Rect get bounds {
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
    );
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    return Rect.fromLTWH(
        position.dx, position.dy, textPainter.width, textPainter.height);
  }
}

Paint? _buildFillPaint(FillStyle fill, Rect rect) {
  if (fill.mode == FillMode.none) {
    return null;
  }

  if (fill.mode == FillMode.solid) {
    return Paint()
      ..style = PaintingStyle.fill
      ..color = fill.colorA;
  }

  if (fill.mode == FillMode.linear) {
    final angle = fill.angleDegrees * math.pi / 180.0;
    final vector = Offset(math.cos(angle), math.sin(angle));
    final start = rect.center - vector * (rect.longestSide / 2);
    final end = rect.center + vector * (rect.longestSide / 2);
    return Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [fill.colorA, fill.colorB],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromPoints(start, end));
  }

  return Paint()
    ..style = PaintingStyle.fill
    ..shader = RadialGradient(
      colors: [fill.colorA, fill.colorB],
      radius: 0.8,
    ).createShader(rect);
}

double _distancePointToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final ap = p - a;
  final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;
  if (ab2 == 0) {
    return (p - a).distance;
  }

  final t = ((ap.dx * ab.dx) + (ap.dy * ab.dy)) / ab2;
  final clampedT = t.clamp(0.0, 1.0);
  final projection = Offset(a.dx + ab.dx * clampedT, a.dy + ab.dy * clampedT);
  return (p - projection).distance;
}
