import 'package:actividad_graficos/charts_flutter/charts/chart_catalog.dart';
import 'package:actividad_graficos/charts_flutter/charts/chart_models.dart';
import 'package:actividad_graficos/charts_flutter/models/multi_league_dashboard_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/league_fixture.dart';

void main() {
  final data = buildFixtureLeague();
  ChartData build(String id) =>
      ChartCatalog.all.firstWhere((d) => d.id == id).build(data);

  test('16 gráficos por liga: 8 básicos + 8 avanzados, 4 por sección', () {
    expect(ChartCatalog.all, hasLength(16));
    expect(ChartCatalog.all.where((d) => !d.advanced), hasLength(8));
    expect(ChartCatalog.all.where((d) => d.advanced), hasLength(8));
    for (final section in DashboardSection.values) {
      expect(ChartCatalog.forSection(section), hasLength(4), reason: section.name);
    }
    expect(ChartCatalog.all.map((d) => d.id).toSet(), hasLength(16));
    // 5 ligas × 16 = 80 gráficos.
    expect(fiveMajorEuropeanLeagues.length * ChartCatalog.all.length, 80);
  });

  test('variedad real: todas las familias de gráficos presentes', () {
    final kinds = ChartCatalog.all.map((d) => d.kind).toSet();
    expect(kinds, containsAll(ChartKind.values));
    // Ninguna familia domina: máximo 2 gráficos por tipo.
    for (final kind in ChartKind.values) {
      expect(
        ChartCatalog.all.where((d) => d.kind == kind).length,
        lessThanOrEqualTo(2),
        reason: kind.name,
      );
    }
  });

  test('los básicos solo usan la tabla (no piden eventos)', () {
    for (final d in ChartCatalog.all.where((d) => !d.advanced)) {
      expect(d.source, ChartDataSource.standings, reason: d.id);
    }
  });

  test('todos los gráficos se construyen con datos', () {
    for (final d in ChartCatalog.all) {
      expect(d.build(data).isEmpty, isFalse, reason: d.id);
    }
  });

  test('sin datos, los gráficos quedan vacíos sin lanzar errores', () {
    final empty = LeagueDashboardData(
      league: fiveMajorEuropeanLeagues.first,
      standings: const [],
      events: const [],
    );
    for (final d in ChartCatalog.all) {
      expect(d.build(empty).isEmpty, isTrue, reason: d.id);
    }
  });

  test('diferencia de goles conserva valores negativos', () {
    final gd = build('goal_difference') as CategoryChartData;
    final values = gd.series.single.values;
    expect(values.any((v) => v < 0), isTrue);
    expect(values.any((v) => v > 0), isTrue);
    expect(values, orderedEquals([...values]..sort((a, b) => b.compareTo(a))));
  });

  test('balance apilado suma los partidos jugados de cada equipo', () {
    final chart = build('wdl_stacked') as CategoryChartData;
    for (var i = 0; i < chart.categories.length; i++) {
      final team = data.teamById(chart.categories[i].teamId)!;
      final total = chart.series.fold(0.0, (s, series) => s + series.values[i]);
      expect(total, team.played);
    }
  });

  test('series temporales usan fechas reales y omiten partidos sin marcador', () {
    final ts = build('goals_by_date_ts') as TimeChartData;
    final dates = ts.dates;
    expect(dates.first, DateTime(2026, 8, 15));
    final finishedGoals = data.events
        .where((e) => e.hasScore)
        .fold<int>(0, (s, e) => s + e.totalGoals);
    final plotted = ts.series.single.points.fold<double>(0, (s, p) => s + p.value);
    expect(plotted, finishedGoals);

    final area = build('cumulative_goals_area') as TimeChartData;
    expect(area.series.single.points.last.value, finishedGoals);
  });

  test('puntos local + visitante coinciden con los puntos de la tabla', () {
    final chart = build('home_away_points') as CategoryChartData;
    expect(chart.categories, hasLength(20));
    for (var i = 0; i < chart.categories.length; i++) {
      final team = data.teamById(chart.categories[i].teamId)!;
      expect(chart.series[0].values[i] + chart.series[1].values[i], team.points);
    }
  });

  test('combo: goles y partidos por mes', () {
    final chart = build('goals_matches_combo') as CategoryChartData;
    expect(chart.series.where((s) => s.asLine), hasLength(1));
    final matches = chart.series.firstWhere((s) => s.asLine).values;
    expect(matches.fold<double>(0, (s, v) => s + v), 60);
  });

  test('pie de resultados y donut por equipo suman el total', () {
    final pie = build('results_pie') as PieChartData;
    expect(pie.options.single.total, 60);
    final donut = build('team_donut') as PieChartData;
    expect(donut.options, hasLength(20));
    expect(donut.options.first.teamId, data.standings.first.idTeam);
    expect(donut.options.first.total, data.standings.first.played);
  });

  test('carrera por el título termina en los puntos de la tabla', () {
    final race = build('title_race_ts') as TimeChartData;
    expect(race.series, hasLength(5));
    for (final line in race.series) {
      expect(line.points.last.value, data.teamById(line.teamId)!.points);
    }
  });

  test('distribución de goles por partido cubre todos los partidos', () {
    final chart = build('goals_per_match_distribution') as CategoryChartData;
    expect(chart.series.single.values.fold<double>(0, (s, v) => s + v), 60);
  });

  test('abreviaturas legibles para el eje de equipos', () {
    expect(teamAbbreviation('Arsenal'), 'ARS');
    expect(teamAbbreviation('Manchester City'), 'MCI');
    expect(teamAbbreviation('Manchester United'), 'MUN');
    expect(teamAbbreviation('Real Madrid'), 'RMA');
    expect(teamAbbreviation('Atlético Madrid'), 'AMA');
    expect(teamAbbreviation('AC Milan'), 'MIL');
    expect(teamAbbreviation('West Ham United'), 'WHU');
    expect(teamAbbreviation('Newcastle United'), 'NEW');
    expect(teamAbbreviation('Tottenham Hotspur'), 'TOT');
  });
}
