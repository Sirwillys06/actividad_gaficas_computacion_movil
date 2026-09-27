import 'dart:math' as math;

import 'package:charts_flutter_updated/charts_flutter_updated.dart' as charts;
import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';
import '../widgets/chart_tooltip.dart';
import '../widgets/team_badge.dart';
import 'chart_axes.dart';
import 'chart_models.dart';
import 'interactive_plot.dart';

/// Pie y donut con PieChart + ArcRendererConfig. Solo para composición
/// (partes de un total), nunca para comparar 20 equipos.
class PieChartView extends StatefulWidget {
  final PieChartData data;
  final ChartContext context;
  final bool donut;

  const PieChartView({
    super.key,
    required this.data,
    required this.context,
    this.donut = false,
  });

  @override
  State<PieChartView> createState() => _PieChartViewState();
}

class _PieChartViewState extends State<PieChartView> {
  int _option = 0;
  int? _hovered;
  Offset _pointer = Offset.zero;
  final Map<int, Widget> _charts = {};

  static const double _arcRatio = 0.4;

  PieOption get _current => widget.data.options[_option];

  @override
  void didUpdateWidget(covariant PieChartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _charts.clear();
      _option = 0;
      _hovered = null;
    }
  }

  Widget _chartFor(int option) {
    return _charts.putIfAbsent(option, () {
      final slices = widget.data.options[option].slices
          .where((s) => s.value > 0)
          .toList();
      return charts.PieChart<String>(
        [
          charts.Series<PieSlice, String>(
            id: widget.data.options[option].label,
            data: slices,
            domainFn: (s, _) => s.label,
            measureFn: (s, _) => s.value,
            colorFn: (s, _) => charts.ColorUtil.fromDartColor(s.color),
          ),
        ],
        animate: false,
        layoutConfig: zeroMarginLayout(),
        defaultRenderer: charts.ArcRendererConfig<String>(
          arcRatio: widget.donut ? _arcRatio : null,
          strokeWidthPx: 2,
        ),
      );
    });
  }

  /// Índice de la porción bajo el puntero, a partir del ángulo.
  int? _sliceAt(Offset p, double side) {
    final center = Offset(side / 2, side / 2);
    final delta = p - center;
    final radius = side / 2;
    final distance = delta.distance;
    final inner = widget.donut ? radius * (1 - _arcRatio) : 0.0;
    if (distance > radius || distance < inner) return null;

    // ArcRenderer empieza arriba (-π/2) y avanza en sentido horario.
    var angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    final target = angle / (2 * math.pi) * _current.total;

    var acc = 0.0;
    for (var i = 0; i < _current.slices.length; i++) {
      acc += _current.slices[i].value;
      if (_current.slices[i].value > 0 && target <= acc) return i;
    }
    return null;
  }

  String _percent(double value) => _current.total == 0
      ? '0%'
      : '${formatNumber(value * 100 / _current.total)}%';

  TooltipContent _tooltip(int index) {
    final slice = _current.slices[index];
    return TooltipContent(
      title: slice.label,
      subtitle: _current.teamId != null
          ? '${_current.label} · ${widget.context.leagueName}'
          : '${widget.context.leagueName} · Temporada ${widget.context.season}',
      rows: [
        TooltipRow(
          'Cantidad',
          formatWithUnit(slice.value, widget.data.unit),
          color: slice.color,
          emphasized: true,
        ),
        TooltipRow('Porcentaje', _percent(slice.value), emphasized: true),
      ],
    );
  }

  Widget _selector() {
    final options = widget.data.options;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: DashboardColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DashboardColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _option,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.expand_more_rounded, size: 18),
          style: const TextStyle(fontSize: 12, color: DashboardColors.ink),
          onChanged: (value) => setState(() {
            _option = value ?? 0;
            _hovered = null;
          }),
          items: [
            for (var i = 0; i < options.length; i++)
              DropdownMenuItem(
                value: i,
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${i + 1}º',
                        style: const TextStyle(
                          fontSize: 10,
                          color: DashboardColors.inkMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TeamLabel(
                        name: options[i].label,
                        badgeUrl: widget.context.badge(options[i].teamId),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legend() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _current.slices.length; i++)
          MouseRegion(
            onEnter: (_) => setState(() => _hovered = i),
            onExit: (_) => setState(() => _hovered = null),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _hovered == i
                    ? _current.slices[i].color.withValues(alpha: 0.12)
                    : DashboardColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _current.slices[i].color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _current.slices[i].label,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: DashboardColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    formatNumber(_current.slices[i].value),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: DashboardColors.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 42,
                    child: Text(
                      _percent(_current.slices[i].value),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        color: DashboardColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _pie() {
    return LayoutBuilder(
      builder: (context, box) {
        final side = math.min(box.maxWidth, box.maxHeight);
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: PlotPointerRegion(
              onPoint: (p) {
                setState(() {
                  _hovered = _sliceAt(p, side);
                  _pointer = p;
                });
              },
              onExit: () => setState(() => _hovered = null),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: _chartFor(_option)),
                  if (widget.donut)
                    Center(
                      child: IgnorePointer(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_current.teamId != null)
                              TeamBadge(
                                badgeUrl: widget.context.badge(_current.teamId),
                                name: _current.label,
                                size: side * 0.16,
                              ),
                            const SizedBox(height: 4),
                            Text(
                              _current.centerCaption,
                              style: TextStyle(
                                fontSize: math.max(11, side * 0.06),
                                fontWeight: FontWeight.w800,
                                color: DashboardColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_hovered != null)
                    TooltipOverlay(anchor: _pointer, content: _tooltip(_hovered!)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelector = widget.data.options.length > 1;
    return Column(
      children: [
        if (hasSelector) ...[_selector(), const SizedBox(height: 10)],
        if (!widget.donut)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _current.centerCaption,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: DashboardColors.inkMuted,
              ),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 380) {
                return Row(
                  children: [
                    Expanded(child: _pie()),
                    const SizedBox(width: 16),
                    SizedBox(width: 190, child: Center(child: _legend())),
                  ],
                );
              }
              return Column(
                children: [
                  Expanded(child: _pie()),
                  const SizedBox(height: 10),
                  _legend(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
