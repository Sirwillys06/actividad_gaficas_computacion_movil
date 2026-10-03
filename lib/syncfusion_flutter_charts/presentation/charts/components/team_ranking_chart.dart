import 'package:flutter/material.dart';

import '../../../core/theme/chart_palette.dart';
import '../../../core/utils/stats_utils.dart';
import '../../../data/models/team_metric.dart';
import '../../../data/models/team_stats.dart';
import 'category_chart.dart';
import 'chart_kit.dart';

/// Ranking de equipos por una métrica. Barras horizontales por defecto para
/// que los nombres de todos los equipos se lean completos.
class TeamRankingChart extends StatelessWidget {
  const TeamRankingChart({
    super.key,
    required this.teams,
    required this.metric,
    this.kind = SeriesKind.bar,
    this.ascending = false,
    this.signedColors = false,
    this.showAverage = true,
    this.highlightKey,
    this.color,
    this.maximum,
    this.minimum,
    this.referenceValue,
    this.referenceLabel,
  });

  final List<TeamStats> teams;
  final TeamMetric metric;
  final SeriesKind kind;
  final bool ascending;
  final bool signedColors;
  final bool showAverage;
  final String? highlightKey;
  final Color? color;
  final double? maximum;
  final double? minimum;
  final double? referenceValue;
  final String? referenceLabel;

  @override
  Widget build(BuildContext context) {
    final sorted = [...teams]
      ..sort(
        (a, b) => ascending ? metric.value(a).compareTo(metric.value(b)) : metric.value(b).compareTo(metric.value(a)),
      );
    final average = StatsUtils.mean(sorted.map(metric.value));
    final base = color ?? ChartPalette.primary;
    final horizontal = kind.isHorizontal;
    return CategoryChart<TeamStats>(
      xTitle: 'Equipo',
      yTitle: metric.axisTitle,
      yMaximum: maximum,
      yMinimum: minimum,
      labelRotation: horizontal ? null : -45,
      visibleCount: !horizontal && sorted.length > 12 ? 12 : null,
      plotBands: [
        if (showAverage && sorted.length > 1) ChartKit.referenceLine(average, 'Media ${metric.format(average)}'),
        if (referenceValue != null)
          ChartKit.referenceLine(referenceValue!, referenceLabel ?? '', color: ChartPalette.neutral),
      ],
      series: [
        SeriesSpec<TeamStats>(
          name: metric.label,
          data: sorted,
          kind: kind,
          x: (team) => team.name,
          y: metric.value,
          color: base,
          pointColor: (team) => team.key == highlightKey
              ? ChartPalette.highlight
              : signedColors
              ? ChartPalette.signed(metric.value(team))
              : base,
          label: (team) => metric.format(metric.value(team)),
          tooltip: (team) =>
              '#${team.rank} ${team.name}\n${metric.label}: ${metric.format(metric.value(team))}\nPJ ${team.played} · Pts ${team.points}',
          showLabels: true,
        ),
      ],
    );
  }
}
