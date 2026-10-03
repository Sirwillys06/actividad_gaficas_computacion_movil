import '../../../core/theme/chart_palette.dart';
import '../../../data/mappers/chart_data_mapper.dart';
import '../../../data/models/match_result.dart';
import '../../../data/models/team_metric.dart';
import '../components/breakdown_chart.dart';
import '../components/category_chart.dart';
import '../components/team_ranking_chart.dart';
import '../outcomes_doughnut_chart.dart';
import 'catalog_helpers.dart';
import 'chart_definition.dart';

const _wdl = [ChartPalette.win, ChartPalette.draw, ChartPalette.loss];

final List<ChartDefinition> resultsCharts = [
  ChartDefinition(
    id: 'wdl-stacked',
    category: ChartCategory.results,
    title: 'Victorias, empates y derrotas',
    description: 'Balance de resultados de cada equipo, en el orden de la clasificación.',
    chartType: 'Stacked Bar',
    scope: ChartScope.ranking,
    height: ChartSizing.teamRows,
    builder: (c) => teamMetricsChart(
      c,
      [
        (TeamMetric.wins, ChartPalette.win),
        (TeamMetric.draws, ChartPalette.draw),
        (TeamMetric.losses, ChartPalette.loss),
      ],
      SeriesKind.stackedBar,
      yTitle: 'Partidos',
      labels: true,
    ),
  ),
  ChartDefinition(
    id: 'wdl-percent',
    category: ChartCategory.results,
    title: 'Porcentaje de victorias, empates y derrotas',
    description: 'Reparto porcentual de resultados: permite comparar equipos con distinto número de partidos.',
    chartType: '100% Stacked Bar',
    scope: ChartScope.ranking,
    height: ChartSizing.teamRows,
    builder: (c) => teamMetricsChart(
      c,
      [
        (TeamMetric.winRate, ChartPalette.win),
        (TeamMetric.drawRate, ChartPalette.draw),
        (TeamMetric.lossRate, ChartPalette.loss),
      ],
      SeriesKind.stackedBar100,
      yTitle: '% de partidos',
    ),
  ),
  ChartDefinition(
    id: 'win-rate',
    category: ChartCategory.results,
    title: 'Porcentaje de victorias',
    description: 'Partidos ganados sobre partidos jugados.',
    chartType: 'Column',
    scope: ChartScope.ranking,
    builder: (c) => TeamRankingChart(
      teams: c.teams,
      metric: TeamMetric.winRate,
      kind: SeriesKind.column,
      maximum: 100,
      minimum: 0,
      highlightKey: c.team?.key,
    ),
  ),
  ChartDefinition(
    id: 'league-outcomes',
    category: ChartCategory.results,
    title: 'Distribución general de resultados',
    description: 'Victorias locales, empates y victorias visitantes en la liga (gráfico original de la app).',
    chartType: 'Doughnut',
    builder: (c) => OutcomesDoughnutChart(data: ChartDataMapper.outcomes(c.analytics.scoredEvents)),
  ),
  ChartDefinition(
    id: 'team-results-pie',
    category: ChartCategory.results,
    title: 'Resultados del equipo',
    description: 'Reparto de victorias, empates y derrotas del equipo seleccionado.',
    chartType: 'Pie',
    scope: ChartScope.team,
    builder: (c) {
      final team = c.team!;
      return BreakdownChart(
        kind: BreakdownKind.pie,
        colors: _wdl,
        data: [
          MatchResult('Victorias', team.wins.toDouble()),
          MatchResult('Empates', team.draws.toDouble()),
          MatchResult('Derrotas', team.losses.toDouble()),
        ],
      );
    },
  ),
  ChartDefinition(
    id: 'wins-home-away',
    category: ChartCategory.results,
    title: 'Victorias como local y como visitante',
    description: 'Compara cuántas victorias consigue cada equipo en casa y fuera.',
    chartType: 'Column agrupado',
    scope: ChartScope.ranking,
    builder: (c) => teamMetricsChart(
      c,
      [(TeamMetric.homeWins, ChartPalette.home), (TeamMetric.awayWins, ChartPalette.away)],
      SeriesKind.column,
      yTitle: 'Victorias',
    ),
  ),
  ChartDefinition(
    id: 'draws-home-away',
    category: ChartCategory.results,
    title: 'Empates como local y como visitante',
    description: 'Empates de cada equipo según la condición de local o visitante.',
    chartType: 'Bar agrupado',
    scope: ChartScope.ranking,
    height: (c) => ChartSizing.teamRows(c, perRow: 36),
    builder: (c) => teamMetricsChart(
      c,
      [(TeamMetric.homeDraws, ChartPalette.home), (TeamMetric.awayDraws, ChartPalette.away)],
      SeriesKind.bar,
      yTitle: 'Empates',
    ),
  ),
  ChartDefinition(
    id: 'losses-home-away',
    category: ChartCategory.results,
    title: 'Derrotas como local y como visitante',
    description: 'Derrotas acumuladas en casa y fuera por cada equipo.',
    chartType: 'Stacked Column',
    scope: ChartScope.ranking,
    builder: (c) => teamMetricsChart(
      c,
      [(TeamMetric.homeLosses, ChartPalette.home), (TeamMetric.awayLosses, ChartPalette.away)],
      SeriesKind.stackedColumn,
      yTitle: 'Derrotas',
      teams: [...c.teams]..sort((a, b) => b.losses.compareTo(a.losses)),
    ),
  ),
];
