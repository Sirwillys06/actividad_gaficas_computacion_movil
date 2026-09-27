import 'dart:math' as math;

import 'package:charts_flutter_updated/charts_flutter_updated.dart' as charts;
import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';
import '../widgets/chart_tooltip.dart';
import '../widgets/team_badge.dart';
import 'chart_axes.dart';
import 'chart_models.dart';
import 'interactive_plot.dart';

/// Dispersión con ScatterPlotChart. Cada punto es un equipo; el escudo se
/// superpone al punto para identificarlo sin etiquetas dentro del lienzo.
class ScatterChartView extends StatefulWidget {
  final ScatterChartData data;
  final ChartContext context;

  const ScatterChartView({super.key, required this.data, required this.context});

  @override
  State<ScatterChartView> createState() => _ScatterChartViewState();
}

class _ScatterChartViewState extends State<ScatterChartView> {
  int? _hovered;
  Widget? _chart;
  String? _chartKey;

  static const double _yLabelWidth = 32;

  Widget _buildChart(AxisScale x, AxisScale y) {
    return charts.ScatterPlotChart(
      [
        charts.Series<ScatterPoint, num>(
          id: widget.data.yLabel,
          data: widget.data.points,
          domainFn: (p, _) => p.x,
          measureFn: (p, _) => p.y,
          colorFn: (_, _) => charts.ColorUtil.fromDartColor(widget.data.color),
          radiusPxFn: (_, _) => 5,
        ),
      ],
      animate: false,
      layoutConfig: zeroMarginLayout(),
      domainAxis: x.hiddenAxisSpec(),
      primaryMeasureAxis: y.hiddenAxisSpec(),
      behaviors: [
        charts.SelectNearest<num>(eventTrigger: charts.SelectionTrigger.tap),
      ],
    );
  }

  Offset _position(ScatterPoint p, AxisScale x, AxisScale y, Size size) =>
      Offset(size.width * x.fraction(p.x), size.height * (1 - y.fraction(p.y)));

  void _onPoint(Offset pointer, AxisScale x, AxisScale y, Size size) {
    int? best;
    var bestDistance = 28.0;
    final points = widget.data.points;
    for (var i = 0; i < points.length; i++) {
      final d = (_position(points[i], x, y, size) - pointer).distance;
      if (d < bestDistance) {
        bestDistance = d;
        best = i;
      }
    }
    if (best != _hovered) setState(() => _hovered = best);
  }

  String _fx(double v) => widget.data.signedX ? formatSigned(v) : formatNumber(v);

  TooltipContent _tooltip(ScatterPoint p) {
    return TooltipContent(
      title: p.label,
      showBadge: p.teamId != null,
      badgeUrl: widget.context.badge(p.teamId),
      subtitle: '${widget.context.leagueName} · Temporada ${widget.context.season}',
      rows: [
        TooltipRow(widget.data.xLabel, _fx(p.x), emphasized: true),
        TooltipRow(widget.data.yLabel, formatNumber(p.y), emphasized: true),
      ],
      notes: p.details,
    );
  }

  @override
  Widget build(BuildContext context) {
    final xs = widget.data.points.map((p) => p.x);
    final ys = widget.data.points.map((p) => p.y);

    return LayoutBuilder(
      builder: (context, constraints) {
        final plotWidth = math.max(100.0, constraints.maxWidth - _yLabelWidth);
        final x = AxisScale.nice(xs, includeZero: false, pixelLength: plotWidth);
        final y = AxisScale.nice(
          ys,
          includeZero: false,
          pixelLength: constraints.maxHeight - 40,
        );
        final key = '${x.min}|${x.max}|${y.min}|${y.max}';
        if (_chart == null || _chartKey != key) {
          _chart = _buildChart(x, y);
          _chartKey = key;
        }
        final showBadges = plotWidth >= 260;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: _yLabelWidth, bottom: 6),
              child: _AxisTitle(widget.data.yLabel, icon: Icons.north_rounded),
            ),
            Expanded(
              child: Row(
                children: [
                  NumericAxisLabels(scale: y, axis: Axis.vertical, width: _yLabelWidth),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final size = Size(box.maxWidth, box.maxHeight);
                        final hovered =
                            _hovered == null ? null : widget.data.points[_hovered!];
                        final hoveredPos =
                            hovered == null ? null : _position(hovered, x, y, size);
                        return PlotPointerRegion(
                          onPoint: (p) => _onPoint(p, x, y, size),
                          onExit: () => setState(() => _hovered = null),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: GridPainter(
                                    fractions: y.ticks.map(y.fraction).toList(),
                                    zeroFraction: y.min < 0 ? y.fraction(0) : null,
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: GridPainter(
                                    axis: Axis.horizontal,
                                    fractions: x.ticks.map(x.fraction).toList(),
                                    zeroFraction: x.min < 0 ? x.fraction(0) : null,
                                  ),
                                ),
                              ),
                              if (hoveredPos != null)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _CrosshairPainter(hoveredPos),
                                    ),
                                  ),
                                ),
                              Positioned.fill(child: _chart!),
                              if (showBadges)
                                for (var i = 0; i < widget.data.points.length; i++)
                                  if (widget.data.points[i].teamId != null)
                                    _badgeMarker(
                                      widget.data.points[i],
                                      _position(widget.data.points[i], x, y, size),
                                      i == _hovered,
                                    ),
                              if (hovered != null)
                                TooltipOverlay(
                                  anchor: hoveredPos!,
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
                Expanded(child: NumericAxisLabels(scale: x, format: _fx)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Align(
                alignment: Alignment.centerRight,
                child: _AxisTitle(widget.data.xLabel, icon: Icons.east_rounded, trailing: true),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _badgeMarker(ScatterPoint p, Offset at, bool active) {
    final size = active ? 24.0 : 17.0;
    return Positioned(
      left: at.dx - size / 2,
      top: at.dy - size / 2,
      width: size,
      height: size,
      child: IgnorePointer(
        child: TeamBadge(
          badgeUrl: widget.context.badge(p.teamId),
          name: p.label,
          size: size,
        ),
      ),
    );
  }
}

class _AxisTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool trailing;

  const _AxisTitle(this.text, {required this.icon, this.trailing = false});

  @override
  Widget build(BuildContext context) {
    final arrow = Icon(icon, size: 11, color: DashboardColors.inkMuted);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!trailing) ...[arrow, const SizedBox(width: 3)],
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: DashboardColors.inkMuted,
          ),
        ),
        if (trailing) ...[const SizedBox(width: 3), arrow],
      ],
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  final Offset at;

  const _CrosshairPainter(this.at);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DashboardColors.pitch.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    const dash = 4.0;
    for (var x = 0.0; x < at.dx; x += dash * 2) {
      canvas.drawLine(Offset(x, at.dy), Offset(math.min(x + dash, at.dx), at.dy), paint);
    }
    for (var y = at.dy; y < size.height; y += dash * 2) {
      canvas.drawLine(Offset(at.dx, y), Offset(at.dx, math.min(y + dash, size.height)), paint);
    }
    canvas.drawCircle(
      at,
      14,
      Paint()
        ..color = DashboardColors.pitch
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter old) => old.at != at;
}
