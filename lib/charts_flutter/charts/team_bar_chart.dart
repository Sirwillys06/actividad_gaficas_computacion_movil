import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';
import '../widgets/chart_tooltip.dart';
import '../widgets/team_badge.dart';
import 'chart_axes.dart';
import 'chart_models.dart';
import 'interactive_plot.dart';

/// Barra horizontal por equipo: [ESCUDO] [NOMBRE] [BARRA] [VALOR].
///
/// Solución personalizada del proyecto (se conserva): muestra valores
/// directos, escudos, hover con tooltip y soporta valores negativos
/// creciendo desde el cero en ambas direcciones.
class TeamBarChart extends StatefulWidget {
  final CategoryChartData data;
  final ChartContext context;

  /// Colorea por signo (verde +, rojo −) y muestra el valor con signo.
  final bool diverging;

  const TeamBarChart({
    super.key,
    required this.data,
    required this.context,
    this.diverging = false,
  });

  @override
  State<TeamBarChart> createState() => _TeamBarChartState();
}

class _TeamBarChartState extends State<TeamBarChart> {
  int? _hovered;

  Color _colorFor(double value) {
    if (!widget.diverging) return widget.data.series.first.color;
    if (value > 0) return DashboardColors.win;
    if (value < 0) return DashboardColors.loss;
    return DashboardColors.draw;
  }

  String _format(double value) =>
      widget.diverging ? formatSigned(value) : formatNumber(value);

  TooltipContent _tooltip(int index) {
    final item = widget.data.categories[index];
    final value = widget.data.series.first.values[index];
    final unit = widget.data.unit;
    return TooltipContent(
      title: item.label,
      showBadge: item.teamId != null,
      badgeUrl: widget.context.badge(item.teamId),
      subtitle: '${widget.context.leagueName} · Temporada ${widget.context.season}',
      rows: [
        TooltipRow(
          widget.data.metric,
          unit.isEmpty ? _format(value) : '${_format(value)} $unit',
          color: _colorFor(value),
          emphasized: true,
        ),
      ],
      notes: item.details,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.data.categories;
    final values = widget.data.series.first.values;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final labelWidth = width < 430 ? 112.0 : (width < 760 ? 150.0 : 176.0);
        const valueWidth = 38.0;
        final barAreaWidth = math.max(80.0, width - labelWidth - valueWidth - 16);
        final scale = AxisScale.nice(values, pixelLength: barAreaWidth);
        final zero = scale.fraction(0);

        return Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final rowHeight = box.maxHeight / math.max(1, items.length);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: labelWidth + 8,
                        right: valueWidth + 8,
                        top: 0,
                        bottom: 0,
                        child: CustomPaint(
                          painter: GridPainter(
                            axis: Axis.horizontal,
                            fractions: scale.ticks.map(scale.fraction).toList(),
                            zeroFraction: scale.min < 0 ? zero : null,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          for (var i = 0; i < items.length; i++)
                            TeamBarRow(
                              item: items[i],
                              badgeUrl: widget.context.badge(items[i].teamId),
                              valueText: _format(values[i]),
                              barLeftFraction: values[i] >= 0
                                  ? zero
                                  : scale.fraction(values[i]),
                              barWidthFraction: values[i].abs() / scale.range,
                              height: rowHeight,
                              labelWidth: labelWidth,
                              valueWidth: valueWidth,
                              barColor: _colorFor(values[i]),
                              highlighted: _hovered == i,
                              dimmed: _hovered != null && _hovered != i,
                              onEnter: () => setState(() => _hovered = i),
                              onExit: () => setState(() => _hovered = null),
                            ),
                        ],
                      ),
                      if (_hovered != null && _hovered! < items.length)
                        TooltipOverlay(
                          anchor: Offset(
                            labelWidth +
                                8 +
                                barAreaWidth *
                                    scale.fraction(
                                      math.max(values[_hovered!], 0),
                                    ),
                            rowHeight * (_hovered! + 0.5),
                          ),
                          content: _tooltip(_hovered!),
                        ),
                    ],
                  );
                },
              ),
            ),
            Row(
              children: [
                SizedBox(width: labelWidth + 8),
                Expanded(child: NumericAxisLabels(scale: scale, format: _format)),
                const SizedBox(width: valueWidth + 8),
              ],
            ),
          ],
        );
      },
    );
  }
}

class TeamBarRow extends StatelessWidget {
  final CategoryItem item;
  final String? badgeUrl;
  final String valueText;
  final double barLeftFraction;
  final double barWidthFraction;
  final double height;
  final double labelWidth;
  final double valueWidth;
  final Color barColor;
  final bool highlighted;
  final bool dimmed;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  const TeamBarRow({
    super.key,
    required this.item,
    required this.badgeUrl,
    required this.valueText,
    required this.barLeftFraction,
    required this.barWidthFraction,
    required this.height,
    required this.labelWidth,
    required this.valueWidth,
    required this.barColor,
    required this.highlighted,
    required this.dimmed,
    required this.onEnter,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final barHeight = (height * 0.62).clamp(6.0, 16.0).toDouble();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onEnter(),
      onExit: (_) => onExit(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onEnter,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              SizedBox(
                width: labelWidth,
                child: TeamLabel(
                  name: item.label,
                  badgeUrl: badgeUrl,
                  showBadge: item.teamId != null,
                  highlighted: highlighted,
                  fontSize: height < 16 ? 9 : 10,
                  badgeSize: math.min(18, height - 2).clamp(8, 18).toDouble(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Center(
                  child: SizedBox(
                    height: barHeight,
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final left =
                            barLeftFraction.clamp(0.0, 1.0) * c.maxWidth;
                        final barWidth = math.max(
                          2.0,
                          barWidthFraction.clamp(0.0, 1.0) * c.maxWidth,
                        );
                        return Stack(
                          children: [
                            Positioned(
                              left: left,
                              top: 0,
                              bottom: 0,
                              width: barWidth,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                curve: Curves.easeOut,
                                decoration: BoxDecoration(
                                  color: barColor.withValues(
                                    alpha: dimmed ? 0.45 : (highlighted ? 1 : 0.85),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: valueWidth,
                child: Text(
                  valueText,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: highlighted ? FontWeight.w900 : FontWeight.w700,
                    color: DashboardColors.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
