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

// Segment hit-test record built during paint
class SegmentHit {
  final DiskNode node;
  final double innerR;
  final double outerR;
  final double startAngle;
  final double sweep;

  const SegmentHit({
    required this.node,
    required this.innerR,
    required this.outerR,
    required this.startAngle,
    required this.sweep,
  });

  bool contains(Offset point, Offset center) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    final r = sqrt(dx * dx + dy * dy);
    if (r < innerR || r > outerR) return false;
    var angle = atan2(dy, dx);
    // Normalise start so we can do a simple range check
    var start = startAngle;
    while (start > angle) { start -= 2 * pi; }
    while (start + 2 * pi < angle) { start += 2 * pi; }
    return angle >= start && angle <= start + sweep;
  }
}

class _LabelJob {
  final String text;
  final double midAngle;
  final double outerR;
  final Offset center;

  const _LabelJob({
    required this.text,
    required this.midAngle,
    required this.outerR,
    required this.center,
  });
}

class DiskUsagePainter extends CustomPainter {
  final DiskNode root;
  final DiskNode? hovered;
  final int maxDepth;
  final List<SegmentHit> hitList;

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

  DiskUsagePainter({
    required this.root,
    required this.hitList,
    this.hovered,
    this.maxDepth = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    hitList.clear();
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = min(size.width, size.height) / 2 - size.width * 0.20;
    final innerCircleR = maxR * 0.28;
    final ringW = (maxR - innerCircleR) / maxDepth;

    // Background circle
    canvas.drawCircle(center, innerCircleR, Paint()..color = Colors.grey.shade100);

    final labels = <_LabelJob>[];
    _drawRing(canvas, root, center, -pi / 2, 2 * pi, 0,
        innerCircleR, ringW, 0, labels);

    for (final job in labels) {
      _drawExternalLabel(canvas, job);
    }

    // Center: show root name + size
    _paintCenterText(canvas, center, innerCircleR);
  }

  void _paintCenterText(Canvas canvas, Offset center, double innerCircleR) {
    final name = root.name;
    final size = _fmtKb(root.totalKb);

    final nameTp = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: innerCircleR * 1.8);

    final sizeTp = TextPainter(
      text: TextSpan(
        text: size,
        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: innerCircleR * 1.8);

    final totalH = nameTp.height + 2 + sizeTp.height;
    nameTp.paint(canvas,
        center - Offset(nameTp.width / 2, totalH / 2));
    sizeTp.paint(canvas,
        center - Offset(sizeTp.width / 2, totalH / 2 - nameTp.height - 2));
  }

  void _drawRing(
    Canvas canvas,
    DiskNode node,
    Offset center,
    double startAngle,
    double sweep,
    int depth,
    double innerCircleR,
    double ringW,
    int colorOffset,
    List<_LabelJob> labels,
  ) {
    if (depth >= maxDepth || node.children.isEmpty) return;

    final innerR = innerCircleR + depth * ringW;
    final outerR = innerCircleR + (depth + 1) * ringW;
    final total = node.children.fold(0, (s, c) => s + c.totalKb);
    if (total == 0) return;

    double angle = startAngle;
    for (int i = 0; i < node.children.length; i++) {
      final child = node.children[i];
      final childSweep = sweep * child.totalKb / total;
      if (childSweep < 0.008) {
        angle += childSweep;
        continue;
      }

      final color = _palette[(colorOffset + i) % _palette.length];
      final isHovered = hovered == child;
      _drawSegment(canvas, center, innerR, outerR, angle, childSweep, color,
          isHovered);

      hitList.add(SegmentHit(
        node: child,
        innerR: innerR,
        outerR: outerR,
        startAngle: angle,
        sweep: childSweep,
      ));

      final midAngle = angle + childSweep / 2;
      final midR = (innerR + outerR) / 2;
      final arcLen = childSweep * midR;
      final label = child.name.length > 10
          ? '${child.name.substring(0, 9)}…'
          : child.name;

      if (arcLen >= 36 && childSweep >= 0.22) {
        final pos = Offset(
          center.dx + midR * cos(midAngle),
          center.dy + midR * sin(midAngle),
        );
        _drawInlineText(canvas, label, pos, 9);
      } else if (depth == 0) {
        labels.add(_LabelJob(
          text: label,
          midAngle: midAngle,
          outerR: outerR,
          center: center,
        ));
      }

      _drawRing(canvas, child, center, angle, childSweep, depth + 1,
          innerCircleR, ringW, (colorOffset + i * 4) % _palette.length, labels);
      angle += childSweep;
    }
  }

  void _drawSegment(Canvas canvas, Offset center, double innerR, double outerR,
      double startAngle, double sweep, Color color, bool highlight) {
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

    final fillColor = highlight ? color : color.withAlpha(210);
    canvas.drawPath(path, Paint()..color = fillColor);

    if (highlight) {
      // Bright border on hover
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  void _drawInlineText(Canvas canvas, String text, Offset center, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.black87,
          fontWeight: FontWeight.w700,
          shadows: const [Shadow(color: Colors.white70, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 80);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawExternalLabel(Canvas canvas, _LabelJob job) {
    const lineLen = 20.0;
    const gap = 4.0;

    final segPt = Offset(
      job.center.dx + (job.outerR + gap) * cos(job.midAngle),
      job.center.dy + (job.outerR + gap) * sin(job.midAngle),
    );
    final linePt = Offset(
      job.center.dx + (job.outerR + gap + lineLen) * cos(job.midAngle),
      job.center.dy + (job.outerR + gap + lineLen) * sin(job.midAngle),
    );

    canvas.drawLine(
      segPt,
      linePt,
      Paint()
        ..color = Colors.black54
        ..strokeWidth = 1.0,
    );
    canvas.drawCircle(segPt, 2.0, Paint()..color = Colors.black54);

    final onRight = cos(job.midAngle) >= 0;
    final tp = TextPainter(
      text: TextSpan(
        text: job.text,
        style: const TextStyle(
          fontSize: 9,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 80);

    final dx = onRight ? linePt.dx + 2 : linePt.dx - tp.width - 2;
    final dy = linePt.dy - tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  String _fmtKb(int kb) {
    if (kb < 1024) return '$kb KB';
    if (kb < 1024 * 1024) return '${(kb / 1024).toStringAsFixed(1)} MB';
    return '${(kb / (1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  bool shouldRepaint(DiskUsagePainter old) =>
      old.root != root || old.hovered != hovered;
}

class DiskUsageWidget extends StatefulWidget {
  final DiskNode root;
  final double size;

  const DiskUsageWidget({super.key, required this.root, this.size = 380});

  @override
  State<DiskUsageWidget> createState() => _DiskUsageWidgetState();
}

class _DiskUsageWidgetState extends State<DiskUsageWidget>
    with SingleTickerProviderStateMixin {
  final List<DiskNode> _navStack = [];
  DiskNode? _hovered;
  DiskNode? _hoveredTooltip;
  final List<SegmentHit> _hitList = [];
  late AnimationController _animCtrl;
  late Animation<double> _anim;
  DiskNode? _displayRoot;

  @override
  void initState() {
    super.initState();
    _displayRoot = widget.root;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  DiskNode get _currentRoot =>
      _navStack.isEmpty ? widget.root : _navStack.last;

  void _navigateTo(DiskNode node) {
    if (node.children.isEmpty) return;
    setState(() {
      _navStack.add(node);
      _displayRoot = node;
      _hovered = null;
      _hoveredTooltip = null;
    });
    _animCtrl.forward(from: 0);
  }

  void _navigateBack() {
    if (_navStack.isEmpty) return;
    setState(() {
      _navStack.removeLast();
      _displayRoot = _currentRoot;
      _hovered = null;
      _hoveredTooltip = null;
    });
    _animCtrl.forward(from: 0);
  }

  void _onTap(Offset localPos) {
    final center = Offset(widget.size / 2, widget.size / 2);
    // Check center circle — navigate back
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final maxR = min(widget.size, widget.size) / 2 - widget.size * 0.20;
    final innerCircleR = maxR * 0.28;
    if (sqrt(dx * dx + dy * dy) <= innerCircleR && _navStack.isNotEmpty) {
      _navigateBack();
      return;
    }
    for (final hit in _hitList) {
      if (hit.contains(localPos, center)) {
        _navigateTo(hit.node);
        return;
      }
    }
  }

  void _onHover(Offset localPos) {
    final center = Offset(widget.size / 2, widget.size / 2);
    DiskNode? found;
    for (final hit in _hitList) {
      if (hit.contains(localPos, center)) {
        found = hit.node;
        break;
      }
    }
    if (found != _hovered) {
      setState(() {
        _hovered = found;
        _hoveredTooltip = found;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final root = _displayRoot ?? widget.root;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBreadcrumb(),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _anim,
          builder: (context2, child2) => Opacity(
            opacity: _anim.value,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onHover: (e) => _onHover(e.localPosition),
              onExit: (_) => setState(() {
                _hovered = null;
                _hoveredTooltip = null;
              }),
              child: GestureDetector(
                onTapUp: (e) => _onTap(e.localPosition),
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: DiskUsagePainter(
                      root: root,
                      hovered: _hovered,
                      hitList: _hitList,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_hoveredTooltip != null) _buildTooltip(_hoveredTooltip!),
      ],
    );
  }

  Widget _buildBreadcrumb() {
    final crumbs = [widget.root, ..._navStack];
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < crumbs.length; i++) ...[
          if (i > 0)
            const Icon(Icons.chevron_right, size: 14, color: Colors.black45),
          GestureDetector(
            onTap: () {
              if (i == crumbs.length - 1) return;
              setState(() {
                _navStack.removeRange(i, _navStack.length);
                _displayRoot = _currentRoot;
                _hovered = null;
                _hoveredTooltip = null;
              });
              _animCtrl.forward(from: 0);
            },
            child: Text(
              crumbs[i].name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: i == crumbs.length - 1
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: i == crumbs.length - 1
                    ? Colors.black87
                    : Colors.blue.shade600,
                decoration: i < crumbs.length - 1
                    ? TextDecoration.underline
                    : null,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTooltip(DiskNode node) {
    final total = (_navStack.isEmpty ? widget.root : _navStack.last).totalKb;
    final pct = total > 0
        ? (node.totalKb / total * 100).toStringAsFixed(1)
        : '0.0';
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${node.name}  •  ${_fmtKb(node.totalKb)}  ($pct%)'
        '${node.children.isNotEmpty ? '  — clic per entrar' : ''}',
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }

  String _fmtKb(int kb) {
    if (kb < 1024) return '$kb KB';
    if (kb < 1024 * 1024) return '${(kb / 1024).toStringAsFixed(1)} MB';
    return '${(kb / (1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
