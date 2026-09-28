import 'package:flutter/material.dart';

import '../../../core/theme/chart_palette.dart';
import '../../../data/models/match_result.dart';
import '../../../data/models/round_stats.dart';
import '../../../data/models/team_metric.dart';
import '../components/breakdown_chart.dart';
import '../components/category_chart.dart';
import '../components/team_ranking_chart.dart';
import 'catalog_helpers.dart';
import 'chart_definition.dart';

List<SeriesSpec<RoundStats>> _outcomeSeries(List<RoundStats> rounds, SeriesKind kind) => [
  roundSeries('Victorias locales', rounds, (r) => r.homeWins, kind, color: ChartPalette.home),
  roundSeries('Empates', rounds, (r) => r.draws, kind, color: ChartPalette.draw),
  roundSeries('Victorias visitantes', rounds, (r) => r.awayWins, kind, color: ChartPalette.away),
];

final List<ChartDefinition> homeAwayCharts = [
  ChartDefinition(
    id: 'home-away-goals-by-round',
    category: ChartCategory.homeAway,
    title: 'Goles locales y visitantes por jornada',
    description: 'Goles marcados por los equipos locales y visitantes en cada jornada, apilados.',
    chartType: 'Stacked Area',
    builder: (c) => CategoryChart<RoundStats>(
      xTitle: c.analytics.roundUnit,
      yTitle: 'Goles',
      enableTrackball: true,
      enableZoom: true,
      series: [
        roundSeries(
          'Goles locales',
          c.analytics.rounds,
          (r) => r.homeGoals,
          SeriesKind.stackedArea,
          color: ChartPalette.home,
        ),
        roundSeries(
          'Goles visitantes',
          c.analytics.rounds,
          (r) => r.awayGoals,
          SeriesKind.stackedArea,
          color: ChartPalette.away,
        ),
      ],
    ),
  ),
  ChartDefinition(
    id: 'outcomes-by-round-percent',
    category: ChartCategory.homeAway,
    title: 'Reparto de resultados por jornada',
    description: 'Proporción de victorias locales, empates y victorias visitantes en cada jornada.',
    chartType: '100% Stacked Column',
    builder: (c) => CategoryChart<RoundStats>(
      xTitle: c.analytics.roundUnit,
      yTitle: '% de partidos',
      visibleCount: c.analytics.rounds.length > 20 ? 20 : null,
      series: _outcomeSeries(c.analytics.rounds, SeriesKind.stackedColumn100),
    ),
  ),
  ChartDefinition(
    id: 'home-advantage',
    category: ChartCategory.homeAway,
    title: 'Ventaja de localía por equipo',
    description: 'Puntos por partido como local menos puntos por partido como visitante.',
    chartType: 'Bar divergente',
    scope: ChartScope.ranking,
    height: ChartSizing.teamRows,
    builder: (c) => TeamRankingChart(
      teams: c.teams,
      metric: TeamMetric.homeAdvantage,
      signedColors: true,
      showAverage: true,
      referenceValue: 0,
      highlightKey: c.team?.key,
    ),
  ),
  ChartDefinition(
    id: 'home-vs-away-goals-scatter',
    category: ChartCategory.homeAway,
    title: 'Goles locales vs goles visitantes',
    description: 'Cada punto es un equipo: goles marcados en casa (X) frente a goles marcados fuera (Y).',
    chartType: 'Scatter',
    scope: ChartScope.ranking,
    builder: (c) => teamScatter(c, TeamMetric.homeGoalsFor, TeamMetric.awayGoalsFor, averages: true),
  ),
  ChartDefinition(
    id: 'goals-against-home-away',
    category: ChartCategory.homeAway,
    title: 'Goles encajados en casa y fuera',
    description: 'Solidez defensiva de cada equipo según la condición de local o visitante.',
    chartType: 'Bar agrupado',
    scope: ChartScope.ranking,
    height: (c) => ChartSizing.teamRows(c, perRow: 36),
    builder: (c) => teamMetricsChart(
      c,
      [(TeamMetric.homeGoalsAgainst, ChartPalette.home), (TeamMetric.awayGoalsAgainst, ChartPalette.away)],
      SeriesKind.bar,
      yTitle: 'Goles en contra',
    ),
  ),
  ChartDefinition(
    id: 'league-goals-share',
    category: ChartCategory.homeAway,
    title: 'Reparto de goles de la liga',
    description: 'Qué parte de los goles de la temporada marcaron los equipos locales y los visitantes.',
    chartType: 'Pie',
    builder: (c) => BreakdownChart(
      kind: BreakdownKind.pie,
      colors: const [ChartPalette.home, ChartPalette.away],
      data: [
        MatchResult('Goles locales', c.analytics.homeGoals.toDouble()),
        MatchResult('Goles visitantes', c.analytics.awayGoals.toDouble()),
      ],
    ),
  ),
  ChartDefinition(
    id: 'cumulative-outcomes',
    category: ChartCategory.homeAway,
    title: 'Victorias locales vs visitantes acumuladas',
    description: 'Evolución acumulada de victorias locales, empates y victorias visitantes a lo largo de la temporada.',
    chartType: 'Spline',
    builder: (c) {
      var home = 0, draw = 0, away = 0;
      final rows = [
        for (final round in c.analytics.rounds)
          (round.label, home += round.homeWins, draw += round.draws, away += round.awayWins),
      ];
      SeriesSpec<(String, int, int, int)> spec(String name, int Function((String, int, int, int)) y, Color color) =>
          SeriesSpec<(String, int, int, int)>(
            name: name,
            data: rows,
            kind: SeriesKind.spline,
            color: color,
            x: (row) => row.$1,
            y: y,
          );
      return CategoryChart<(String, int, int, int)>(
        xTitle: c.analytics.roundUnit,
        yTitle: 'Partidos acumulados',
        enableTrackball: true,
        enableZoom: true,
        series: [
          spec('Victorias locales', (r) => r.$2, ChartPalette.home),
          spec('Empates', (r) => r.$3, ChartPalette.draw),
          spec('Victorias visitantes', (r) => r.$4, ChartPalette.away),
        ],
      );
    },
  ),
  ChartDefinition(
    id: 'home-vs-away-performance-scatter',
    category: ChartCategory.homeAway,
    title: 'Rendimiento local vs visitante',
    description: 'Cada punto es un equipo: % de puntos en casa (X) frente a % de puntos fuera (Y). Líneas en el 50 %.',
    chartType: 'Scatter',
    scope: ChartScope.ranking,
    builder: (c) =>
        teamScatter(c, TeamMetric.homePerformance, TeamMetric.awayPerformance, xReference: 50, yReference: 50),
  ),
];
