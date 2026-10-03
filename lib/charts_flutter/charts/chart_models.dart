import 'package:flutter/material.dart';

import '../models/multi_league_dashboard_models.dart';

/// Tipos de gráfico realmente soportados por charts_flutter_updated 0.16.0
/// (BarChart, LineChart, TimeSeriesChart, ScatterPlotChart, PieChart,
/// OrdinalComboChart) más la barra por equipo con escudos del proyecto.
enum ChartKind {
  horizontalBar('Barras horizontales', Icons.align_horizontal_left_rounded),
  divergingBar('Barras divergentes', Icons.swap_horiz_rounded),
  column('Columnas', Icons.bar_chart_rounded),
  grouped('Barras agrupadas', Icons.stacked_bar_chart_rounded),
  stacked('Barras apiladas', Icons.view_agenda_outlined),
  pie('Pie', Icons.pie_chart_rounded),
  donut('Donut', Icons.donut_large_rounded),
  scatter('Dispersión', Icons.scatter_plot_rounded),
  line('Líneas', Icons.show_chart_rounded),
  area('Área temporal', Icons.area_chart_rounded),
  timeSeries('Serie temporal', Icons.timeline_rounded),
  combo('Combo barras + línea', Icons.insights_rounded);

  final String label;
  final IconData icon;

  const ChartKind(this.label, this.icon);
}

enum DashboardSection {
  rendimiento(
    'Rendimiento',
    Icons.emoji_events_outlined,
    'Puntos, victorias y balance de resultados de la tabla.',
  ),
  goles(
    'Goles',
    Icons.sports_soccer_rounded,
    'Producción ofensiva, solidez defensiva y diferencia de goles.',
  ),
  partidos(
    'Partidos',
    Icons.event_note_rounded,
    'Calendario real: goles por fecha, meses y resultados.',
  ),
  avanzado(
    'Análisis avanzado',
    Icons.analytics_outlined,
    'Relaciones entre métricas, localía y carrera por el título.',
  );

  final String label;
  final IconData icon;
  final String description;

  const DashboardSection(this.label, this.icon, this.description);
}

/// Qué bloques de TheSportsDB necesita un gráfico. Evita pedir eventos para
/// gráficos que solo usan la tabla, y viceversa.
enum ChartDataSource {
  standings,
  events,
  both;

  bool get needsStandings => this != ChartDataSource.events;
  bool get needsEvents => this != ChartDataSource.standings;
}

/// Base de los datos que consume cada vista de gráfico.
sealed class ChartData {
  const ChartData();

  bool get isEmpty;
}

/// Un elemento de un eje por categorías (normalmente un equipo).
class CategoryItem {
  final String label;
  final String shortLabel;

  /// idTeam cuando la categoría es un equipo. Se usa para el escudo.
  final String? teamId;

  /// Líneas adicionales para el tooltip (p. ej. "PJ 6 · 4V 1E 1D").
  final List<String> details;

  const CategoryItem({
    required this.label,
    String? shortLabel,
    this.teamId,
    this.details = const [],
  }) : shortLabel = shortLabel ?? label;
}

class CategorySeries {
  final String name;
  final Color color;
  final List<double> values;

  /// En un combo, se dibuja como línea sobre las barras.
  final bool asLine;

  const CategorySeries({
    required this.name,
    required this.color,
    required this.values,
    this.asLine = false,
  });
}

/// Barras, columnas, agrupadas, apiladas, combo y líneas por posición.
class CategoryChartData extends ChartData {
  final List<CategoryItem> categories;
  final List<CategorySeries> series;
  final String unit;

  /// Etiqueta de la métrica para tooltips con una sola serie.
  final String metric;

  const CategoryChartData({
    required this.categories,
    required this.series,
    required this.metric,
    this.unit = '',
  });

  @override
  bool get isEmpty =>
      categories.isEmpty ||
      series.isEmpty ||
      series.every((s) => s.values.every((v) => v == 0));

  double valueAt(int series, int index) => this.series[series].values[index];
}

class ScatterPoint {
  final double x;
  final double y;
  final String label;
  final String? teamId;
  final List<String> details;

  const ScatterPoint({
    required this.x,
    required this.y,
    required this.label,
    this.teamId,
    this.details = const [],
  });
}

class ScatterChartData extends ChartData {
  final List<ScatterPoint> points;
  final String xLabel;
  final String yLabel;
  final Color color;
  final bool signedX;

  const ScatterChartData({
    required this.points,
    required this.xLabel,
    required this.yLabel,
    required this.color,
    this.signedX = false,
  });

  @override
  bool get isEmpty => points.isEmpty;
}

class TimePoint {
  final DateTime date;
  final double value;

  const TimePoint(this.date, this.value);
}

class TimeSeriesLine {
  final String name;
  final Color color;
  final List<TimePoint> points;
  final String? teamId;

  const TimeSeriesLine({
    required this.name,
    required this.color,
    required this.points,
    this.teamId,
  });

  /// Último valor conocido en [date] (útil para series acumuladas).
  double? valueAtOrBefore(DateTime date) {
    double? value;
    for (final point in points) {
      if (point.date.isAfter(date)) break;
      value = point.value;
    }
    return value;
  }

  double? valueOn(DateTime date) {
    for (final point in points) {
      if (point.date == date) return point.value;
    }
    return null;
  }
}

class TimeChartData extends ChartData {
  final List<TimeSeriesLine> series;
  final String metric;
  final String unit;

  /// true: el tooltip usa el último valor conocido (series acumuladas).
  final bool cumulative;

  /// Notas por fecha para el tooltip (p. ej. el partido con más goles).
  final Map<DateTime, List<String>> notes;

  const TimeChartData({
    required this.series,
    required this.metric,
    this.unit = '',
    this.cumulative = false,
    this.notes = const {},
  });

  List<DateTime> get dates {
    final set = <DateTime>{
      for (final line in series)
        for (final point in line.points) point.date,
    };
    return set.toList()..sort();
  }

  @override
  bool get isEmpty => series.every((line) => line.points.isEmpty);
}

class PieSlice {
  final String label;
  final double value;
  final Color color;

  const PieSlice(this.label, this.value, this.color);
}

/// Una composición seleccionable (p. ej. un equipo concreto).
class PieOption {
  final String label;
  final String? teamId;
  final List<PieSlice> slices;
  final String centerCaption;

  const PieOption({
    required this.label,
    required this.slices,
    required this.centerCaption,
    this.teamId,
  });

  double get total => slices.fold(0.0, (sum, slice) => sum + slice.value);
}

class PieChartData extends ChartData {
  final List<PieOption> options;
  final String unit;

  /// Texto del selector cuando hay varias opciones (p. ej. "Equipo").
  final String? selectorLabel;

  const PieChartData({
    required this.options,
    required this.unit,
    this.selectorLabel,
  });

  @override
  bool get isEmpty => options.isEmpty || options.every((o) => o.total == 0);
}

/// Definición estática de un gráfico del catálogo.
class ChartDefinition {
  final String id;
  final DashboardSection section;
  final ChartKind kind;
  final String title;
  final String description;

  /// Qué representa cada eje, en lenguaje llano.
  final String axisHint;
  final ChartDataSource source;

  /// Básico (tabla) o avanzado (eventos / métricas derivadas).
  final bool advanced;
  final String emptyMessage;
  final ChartData Function(LeagueDashboardData data) build;

  const ChartDefinition({
    required this.id,
    required this.section,
    required this.kind,
    required this.title,
    required this.description,
    required this.axisHint,
    required this.source,
    required this.advanced,
    required this.build,
    this.emptyMessage = 'No hay datos disponibles para este gráfico.',
  });
}

/// Contexto común que necesitan las vistas (escudos, liga, temporada).
class ChartContext {
  final LeagueDashboardData data;
  final String season;

  const ChartContext({required this.data, required this.season});

  String get leagueName => data.league.name;

  TeamStandingData? team(String? idTeam) => data.teamById(idTeam);

  String? badge(String? idTeam) => team(idTeam)?.badge;
}
