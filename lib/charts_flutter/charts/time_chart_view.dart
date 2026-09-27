import 'dart:math' as math;

import 'package:charts_flutter_updated/charts_flutter_updated.dart' as charts;
import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';
import '../widgets/chart_tooltip.dart';
import 'chart_axes.dart';
import 'chart_models.dart';
import 'interactive_plot.dart';

/// Series temporales con TimeSeriesChart y eje DateTime real.
///
/// [area] activa LineRendererConfig.includeArea para el gráfico de área.
class TimeChartView extends StatefulWidget {
  final TimeChartData data;
  final ChartContext context;
  final bool area;

  const TimeChartView({
    super.key,
    required this.data,
    required this.context,
    this.area = false,
  });

  @override
  State<TimeChartView> createState() => _TimeChartViewState();
}

class _TimeChartViewState extends State<TimeChartView> {
  DateTime? _hovered;
  Widget? _chart;
  String? _chartKey;

  static const double _yLabelWidth = 32;

  Widget _buildChart(TimeScale t, AxisScale y) {
    final manyPoints = widget.data.series.any((s) => s.points.length > 45);
    return charts.TimeSeriesChart(
      [
        for (final line in widget.data.series)
          charts.Series<TimePoint, DateTime>(
            id: line.name,
            data: line.points,
            domainFn: (p, _) => p.date,
            measureFn: (p, _) => p.value,
            colorFn: (_, _) => charts.ColorUtil.fromDartColor(line.color),
          ),
      ],
      animate: false,
      layoutConfig: zeroMarginLayout(),
      domainAxis: t.hiddenAxisSpec(),
      primaryMeasureAxis: y.hiddenAxisSpec(),
      defaultRenderer: charts.LineRendererConfig<DateTime>(
        includeArea: widget.area,
        areaOpacity: 0.22,
        includePoints: !manyPoints,
        radiusPx: 3,
        strokeWidthPx: 2.2,
      ),
      behaviors: [
        charts.SelectNearest<DateTime>(
          eventTrigger: charts.SelectionTrigger.tap,
        ),
        charts.LinePointHighlighter<DateTime>(),
      ],
    );
  }

  double? _valueFor(TimeSeriesLine line, DateTime date) => widget.data.cumulative
      ? line.valueAtOrBefore(date)
      : line.valueOn(date);

  void _onPoint(Offset pointer, TimeScale t, Size size, List<DateTime> dates) {
    if (dates.isEmpty) return;
    DateTime? best;
    var bestDistance = double.infinity;
    for (final date in dates) {
      final d = (size.width * t.fraction(date) - pointer.dx).abs();
      if (d < bestDistance) {
        bestDistance = d;
        best = date;
      }
    }
    if (best != _hovered) setState(() => _hovered = best);
  }

  TooltipContent _tooltip(DateTime date) {
    final unit = widget.data.unit;
    final rows = <TooltipRow>[];
    final entries = [
      for (final line in widget.data.series)
        if (_valueFor(line, date) != null) (line, _valueFor(line, date)!),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    for (final (line, value) in entries) {
      rows.add(
        TooltipRow(
          widget.data.series.length == 1 ? widget.data.metric : line.name,
          unit.isEmpty ? formatNumber(value) : '${formatNumber(value)} $unit',
          color: line.color,
          emphasized: widget.data.series.length == 1,
        ),
      );
    }
    return TooltipContent(
      title: formatFullDate(date),
      subtitle: '${widget.context.leagueName} · Temporada ${widget.context.season}',
      rows: rows,
      notes: widget.data.notes[date] ?? const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dates = widget.data.dates;
    final values = widget.data.series.expand((s) => s.points.map((p) => p.value));

    return LayoutBuilder(
      builder: (context, constraints) {
        final plotWidth = math.max(100.0, constraints.maxWidth - _yLabelWidth);
        final t = TimeScale.fromDates(dates, pixelLength: plotWidth);
        final y = AxisScale.nice(values, pixelLength: constraints.maxHeight - 30);
        final key = '${t.start}|${t.end}|${y.min}|${y.max}';
        if (_chart == null || _chartKey != key) {
          _chart = _buildChart(t, y);
          _chartKey = key;
        }

        return Column(
          children: [
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  NumericAxisLabels(scale: y, axis: Axis.vertical, width: _yLabelWidth),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final size = Size(box.maxWidth, box.maxHeight);
                        final hovered = _hovered;
                        final hx = hovered == null ? 0.0 : size.width * t.fraction(hovered);
                        return PlotPointerRegion(
                          onPoint: (p) => _onPoint(p, t, size, dates),
                          onExit: () => setState(() => _hovered = null),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: GridPainter(
                                    fractions: y.ticks.map(y.fraction).toList(),
                                    zeroFraction: y.fraction(0),
                                  ),
                                ),
                              ),
                              Positioned.fill(child: _chart!),
                              if (hovered != null)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _GuidePainter(
                                        x: hx,
                                        dots: [
                                          for (final line in widget.data.series)
                                            if (_valueFor(line, hovered) != null)
                                              (
                                                size.height *
                                                    (1 - y.fraction(_valueFor(line, hovered)!)),
                                                line.color,
                                              ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (hovered != null)
                                TooltipOverlay(
                                  anchor: Offset(hx, size.height * 0.35),
                                  content: _tooltip(hovered),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const SizedBox(width: _yLabelWidth),
                Expanded(child: DateAxisLabels(scale: t)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _GuidePainter extends CustomPainter {
  final double x;
  final List<(double, Color)> dots;

  const _GuidePainter({required this.x, required this.dots});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = DashboardColors.pitch.withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );
    for (final (y, color) in dots) {
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), 4.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _GuidePainter old) =>
      old.x != x || old.dots.length != dots.length;
}
