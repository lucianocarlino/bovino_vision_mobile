import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum SeriesTone { brand, earth }

class ChartSeries {
  const ChartSeries({required this.name, required this.values, this.tone = SeriesTone.brand});

  final String name;

  /// One value per label; null leaves a gap.
  final List<double?> values;
  final SeriesTone tone;
}

Color _strokeFor(SeriesTone tone) => tone == SeriesTone.brand ? AppColors.green500 : AppColors.brown400;

/// Smoothed line chart with a horizontal grid and a dark tooltip on tap, ported from the
/// web app's `LineChart.tsx`.
class LineChartView extends StatefulWidget {
  const LineChartView({
    super.key,
    required this.labels,
    required this.series,
    required this.formatValue,
    this.formatAxis,
    this.height = 220,
    this.emptyMessage = 'Todavía no hay suficientes datos para graficar.',
  });

  final List<String> labels;
  final List<ChartSeries> series;
  final String Function(double value) formatValue;
  final String Function(double value)? formatAxis;
  final double height;
  final String emptyMessage;

  @override
  State<LineChartView> createState() => _LineChartViewState();
}

class _LineChartViewState extends State<LineChartView> {
  int? _active;

  bool get _hasData => widget.series.any((s) => s.values.whereType<double>().length >= 2);

  @override
  Widget build(BuildContext context) {
    if (!_hasData) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(widget.emptyMessage, style: const TextStyle(fontSize: 13, color: AppColors.neutral500)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, widget.height);
        final painter = _ChartPainter(
          labels: widget.labels,
          series: widget.series,
          formatAxis: widget.formatAxis ?? widget.formatValue,
          active: _active,
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => setState(() => _active = painter.indexAt(details.localPosition.dx, size.width)),
          onHorizontalDragUpdate: (details) =>
              setState(() => _active = painter.indexAt(details.localPosition.dx, size.width)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(size: size, painter: painter),
              if (_active != null) _tooltip(painter, size),
            ],
          ),
        );
      },
    );
  }

  Widget _tooltip(_ChartPainter painter, Size size) {
    final index = _active!;
    final x = painter.xFor(index, size.width);
    final lines = [
      for (final s in widget.series)
        if (index < s.values.length && s.values[index] != null) (s, s.values[index]!),
    ];
    const tooltipWidth = 140.0;
    final left = (x - tooltipWidth / 2).clamp(0.0, math.max(0.0, size.width - tooltipWidth)).toDouble();
    return Positioned(
      left: left,
      top: 0,
      width: tooltipWidth,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.neutral900,
            borderRadius: BorderRadius.circular(8),
            boxShadow: AppShadows.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.labels[index], style: const TextStyle(fontSize: 11, color: AppColors.neutral300)),
              for (final (s, value) in lines)
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(color: _strokeFor(s.tone), shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: Text(
                        widget.series.length > 1 ? '${s.name}: ${widget.formatValue(value)}' : widget.formatValue(value),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Legend items for multi-series charts ("Real" / "Objetivo").
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.items});

  final List<(String name, SeriesTone tone)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: [
        for (final (name, tone) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: _strokeFor(tone), borderRadius: BorderRadius.circular(3)),
              ),
              Text(name, style: const TextStyle(fontSize: 12, color: AppColors.neutral600)),
            ],
          ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.labels, required this.series, required this.formatAxis, required this.active});

  final List<String> labels;
  final List<ChartSeries> series;
  final String Function(double value) formatAxis;
  final int? active;

  static const _padTop = 16.0, _padRight = 16.0, _padBottom = 32.0, _padLeft = 56.0;
  static const _smoothing = 0.18;

  late final List<double> _ticks = _axisTicks();

  List<double> _axisTicks() {
    final values = series.expand((s) => s.values).whereType<double>();
    final low = values.reduce(math.min), high = values.reduce(math.max);
    final span = (high - low) == 0 ? (high.abs() == 0 ? 1.0 : high.abs()) : high - low;
    final raw = span / 3;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final fraction = raw / magnitude;
    final step = (fraction <= 1 ? 1 : fraction <= 2 ? 2 : fraction <= 5 ? 5 : 10) * magnitude;
    final start = (low / step).floor() * step, end = (high / step).ceil() * step;
    final ticks = <double>[for (var t = start; t <= end + step / 2; t += step) double.parse(t.toStringAsFixed(6))];
    return ticks.length > 1 ? ticks : [start, start + step];
  }

  double xFor(int index, double width) {
    final plotWidth = width - _padLeft - _padRight;
    return labels.length <= 1 ? _padLeft + plotWidth / 2 : _padLeft + plotWidth * index / (labels.length - 1);
  }

  double _yFor(double value, double height) {
    final plotHeight = height - _padTop - _padBottom;
    final low = _ticks.first, high = _ticks.last;
    return _padTop + plotHeight * (1 - (value - low) / (high - low));
  }

  int indexAt(double dx, double width) {
    if (labels.length <= 1) return 0;
    final plotWidth = width - _padLeft - _padRight;
    return (((dx - _padLeft) / plotWidth) * (labels.length - 1)).round().clamp(0, labels.length - 1);
  }

  TextPainter _text(String text, Color color) => TextPainter(
        text: TextSpan(text: text, style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 10, color: color)),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.neutral200
      ..strokeWidth = 1;
    for (final tick in _ticks) {
      final y = _yFor(tick, size.height);
      canvas.drawLine(Offset(_padLeft, y), Offset(size.width - _padRight, y), grid);
      final label = _text(formatAxis(tick), AppColors.neutral500);
      label.paint(canvas, Offset(_padLeft - 8 - label.width, y - label.height / 2));
    }

    for (final index in _visibleLabelIndexes()) {
      final label = _text(labels[index], AppColors.neutral500);
      final x = (xFor(index, size.width) - label.width / 2).clamp(0.0, size.width - label.width);
      label.paint(canvas, Offset(x, size.height - _padBottom + 10));
    }

    if (active != null) {
      final x = xFor(active!, size.width);
      final cursor = Paint()
        ..color = AppColors.neutral400
        ..strokeWidth = 1;
      for (var y = _padTop; y < size.height - _padBottom; y += 6) {
        canvas.drawLine(Offset(x, y), Offset(x, math.min(y + 3, size.height - _padBottom)), cursor);
      }
    }

    for (final s in series) {
      final stroke = Paint()
        ..color = _strokeFor(s.tone)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (final run in _segments(s.values, size)) {
        canvas.drawPath(_smoothPath(run), stroke);
      }
      if (active != null && active! < s.values.length && s.values[active!] != null) {
        final point = Offset(xFor(active!, size.width), _yFor(s.values[active!]!, size.height));
        canvas.drawCircle(point, 5, Paint()..color = AppColors.white);
        canvas.drawCircle(point, 5, stroke..strokeWidth = 2);
      }
    }
  }

  Iterable<int> _visibleLabelIndexes() {
    final count = labels.length;
    if (count <= 6) return List.generate(count, (i) => i);
    return {for (var k = 0; k <= 4; k++) (k * (count - 1) / 4).round()};
  }

  List<List<Offset>> _segments(List<double?> values, Size size) {
    final runs = <List<Offset>>[];
    var current = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null) {
        if (current.isNotEmpty) runs.add(current);
        current = [];
        continue;
      }
      current.add(Offset(xFor(i, size.width), _yFor(value, size.height)));
    }
    if (current.isNotEmpty) runs.add(current);
    return runs;
  }

  /// Smooth cubic path through the points, using neighbor slopes as control handles.
  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final p0 = points[math.max(i - 2, 0)], p1 = points[i - 1], p2 = points[i];
      final p3 = i + 1 < points.length ? points[i + 1] : p2;
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) * _smoothing,
        p1.dy + (p2.dy - p0.dy) * _smoothing,
        p2.dx - (p3.dx - p1.dx) * _smoothing,
        p2.dy - (p3.dy - p1.dy) * _smoothing,
        p2.dx,
        p2.dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.active != active || oldDelegate.series != series || oldDelegate.labels != labels;
}
