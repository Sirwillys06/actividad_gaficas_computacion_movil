import 'package:flutter/material.dart';

import '../../../core/theme/chart_palette.dart';
import '../../../data/models/chart_point.dart';
import '../../../data/models/round_stats.dart';
import '../../../data/models/team_metric.dart';
import '../../../data/models/team_stats.dart';
import '../components/category_chart.dart';
import '../components/chart_kit.dart';
import '../components/xy_chart.dart';
import 'chart_definition.dart';

/// Utilidades compartidas por los archivos de cada categoría para declarar
/// gráficos sin repetir configuración.

/// Serie de una métrica de equipo.
SeriesSpec<TeamStats> metricSeries(
  List<TeamStats> teams,
  TeamMetric metric,
  SeriesKind kind, {
  Color? color,
  String? name,
  bool labels = false,
  bool negate = false,
}) => SeriesSpec<TeamStats>(
  name: name ?? metric.label,
  data: teams,
  kind: kind,
  color: color,
  x: (team) => team.name,
  y: (team) => negate ? -metric.value(team) : metric.value(team),
  label: (team) => metric.format(metric.value(team)),
  tooltip: (team) => '#${team.rank} ${team.name}\n${name ?? metric.label}: ${metric.format(metric.value(team))}',
  showLabels: labels,
);

/// Gráfico de varias métricas por equipo (agrupado, apilado o 100 %).
Widget teamMetricsChart(
  ChartContext context,
  List<(TeamMetric, Color)> metrics,
  SeriesKind kind, {
  required String yTitle,
  List<TeamStats>? teams,
  bool labels = false,
}) {
  final rows = teams ?? context.teams;
  return CategoryChart<TeamStats>(
    xTitle: 'Equipo',
    yTitle: yTitle,
    labelRotation: kind.isHorizontal ? null : -45,
    visibleCount: !kind.isHorizontal && rows.length > 12 ? 12 : null,
    series: [for (final (metric, color) in metrics) metricSeries(rows, metric, kind, color: color, labels: labels)],
  );
}

/// Serie simple de valores etiquetados.
SeriesSpec<LabeledValue> valueSeries(
  String name,
  List<LabeledValue> data,
  SeriesKind kind, {
  Color? color,
  bool labels = false,
  bool markers = true,
  String Function(double value)? format,
}) => SeriesSpec<LabeledValue>(
  name: name,
  data: data,
  kind: kind,
  color: color,
  x: (point) => point.label,
  y: (point) => point.value,
  label: format == null ? null : (point) => format(point.value),
  tooltip: (point) {
    final value = format?.call(point.value) ?? _plain(point.value);
    return point.detail == null ? '$name\n${point.label}: $value' : '${point.detail}\n$name: $value';
  },
  showLabels: labels,
  showMarkers: markers,
);

/// Serie por jornada.
SeriesSpec<RoundStats> roundSeries(
  String name,
  List<RoundStats> rounds,
  num Function(RoundStats round) y,
  SeriesKind kind, {
  Color? color,
  bool labels = false,
}) => SeriesSpec<RoundStats>(
  name: name,
  data: rounds,
  kind: kind,
  color: color,
  x: (round) => round.label,
  y: y,
  tooltip: (round) => '${round.label} · ${round.matches} partidos\n$name: ${_plain(y(round))}',
  showLabels: labels,
);

/// Serie por equipo de una lista de equipos comparados.
List<SeriesSpec<LabeledValue>> comparedSeries(
  List<TeamStats> teams,
  List<LabeledValue> Function(TeamStats team) mapper,
  SeriesKind kind,
) => [
  for (var i = 0; i < teams.length; i++) valueSeries(teams[i].name, mapper(teams[i]), kind, color: ChartPalette.at(i)),
];

/// Dispersión/burbujas de equipos a partir de dos (o tres) métricas.
Widget teamScatter(
  ChartContext context,
  TeamMetric x,
  TeamMetric y, {
  TeamMetric? size,
  bool trendline = false,
  bool averages = false,
  double? xReference,
  double? yReference,
}) {
  final teams = context.teams;
  final byName = {for (final team in teams) team.name: team};
  final points = [
    for (final team in teams)
      XYPoint(
        x: x.value(team),
        y: y.value(team),
        size: size == null ? 1 : size.value(team).abs() + 1,
        label: team.name,
      ),
  ];
  String tooltip(XYPoint point) {
    final team = byName[point.label]!;
    return '#${team.rank} ${team.name}\n${x.label}: ${x.format(x.value(team))}\n${y.label}: ${y.format(y.value(team))}'
        '${size == null ? '' : '\n${size.label}: ${size.format(size.value(team))}'}';
  }

  double mean(TeamMetric metric) => teams.isEmpty ? 0 : teams.map(metric.value).reduce((a, b) => a + b) / teams.length;
  return XYChart(
    points: points,
    xTitle: x.axisTitle,
    yTitle: y.axisTitle,
    bubble: size != null,
    trendline: trendline,
    highlightLabel: context.team?.name,
    tooltip: tooltip,
    plotBands: [
      if (averages) ChartKit.referenceLine(mean(y), 'Media'),
      if (yReference != null) ChartKit.referenceLine(yReference, y.format(yReference)),
    ],
    xPlotBands: [
      if (averages) ChartKit.referenceLine(mean(x), 'Media'),
      if (xReference != null) ChartKit.referenceLine(xReference, x.format(xReference)),
    ],
  );
}

String _plain(num value) => value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(2);
