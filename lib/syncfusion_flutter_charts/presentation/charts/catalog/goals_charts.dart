import '../../../core/theme/chart_palette.dart';
import '../../../data/mappers/chart_data_mapper.dart';
import '../../../data/models/team_metric.dart';
import '../components/category_chart.dart';
import '../components/team_ranking_chart.dart';
import '../goals_by_team_chart.dart';
import 'catalog_helpers.dart';
import 'chart_definition.dart';

final List<ChartDefinition> goalsCharts = [
  ChartDefinition(
    id: 'goals-by-team',
    category: ChartCategory.goals,
    title: 'Goles a favor por equipo',
    description: 'Goles marcados por cada equipo en los partidos con marcador (gráfico original de la app).',
    chartType: 'Column',
    scope: ChartScope.ranking,
    height: (c) => c.teams.length > 12 ? 420 : 340,
    builder: (c) {
      final names = {for (final team in c.teams) team.name};
      final data = ChartDataMapper.goalsByTeam(
        c.analytics.scoredEvents,
      ).where((item) => names.contains(item.label)).toList();
      return GoalsByTeamChart(data: data);
    },
  ),
  ChartDefinition(
    id: 'goals-against',
    category: ChartCategory.goals,
    title: 'Goles en contra por equipo',
    description: 'Goles encajados. Los equipos con más goles recibidos aparecen primero.',
    chartType: 'Bar',
    scope: ChartScope.ranking,
    height: ChartSizing.teamRows,
    builder: (c) => TeamRankingChart(
      teams: c.teams,
      metric: TeamMetric.goalsAgainst,
      color: ChartPalette.goalsAgainst,
      highlightKey: c.team?.key,
    ),
  ),
  ChartDefinition(
    id: 'goal-difference',
    category: ChartCategory.goals,
    title: 'Diferencia de goles',
    description: 'Goles a favor menos goles en contra. Verde positivo, rojo negativo.',
    chartType: 'Bar divergente',
    scope: ChartScope.ranking,
    height: ChartSizing.teamRows,
    builder: (c) => TeamRankingChart(
      teams: c.teams,
      metric: TeamMetric.goalDifference,
      signedColors: true,
      showAverage: false,
      referenceValue: 0,
      highlightKey: c.team?.key,
    ),
  ),
  ChartDefinition(
    id: 'goals-for-per-match',
    category: ChartCategory.goals,
    title: 'Promedio de goles a favor por partido',
    description: 'Capacidad ofensiva normalizada por partidos jugados, con la media de la liga como referencia.',
    chartType: 'Column + línea de media',
    scope: ChartScope.ranking,
    builder: (c) => TeamRankingChart(
      teams: c.teams,
      metric: TeamMetric.goalsForPerMatch,
      kind: SeriesKind.column,
      color: ChartPalette.home,
      highlightKey: c.team?.key,
    ),
  ),
  ChartDefinition(
    id: 'home-away-goals-stacked',
    category: ChartCategory.goals,
    title: 'Goles locales y visitantes por equipo',
    description: 'Goles a favor desglosados según se marcaron como local o como visitante.',
    chartType: 'Stacked Column',
    scope: ChartScope.ranking,
    builder: (c) => teamMetricsChart(
      c,
      [(TeamMetric.homeGoalsFor, ChartPalette.home), (TeamMetric.awayGoalsFor, ChartPalette.away)],
      SeriesKind.stackedColumn,
      yTitle: 'Goles a favor',
      teams: [...c.teams]..sort((a, b) => b.goalsFor.compareTo(a.goalsFor)),
    ),
  ),
  ChartDefinition(
    id: 'goals-in-matches',
    category: ChartCategory.goals,
    title: 'Goles totales en los partidos de cada equipo',
    description: 'Suma de goles marcados y encajados: mide lo abiertos que son los partidos de cada equipo.',
    chartType: 'Stacked Bar',
    scope: ChartScope.ranking,
    height: ChartSizing.teamRows,
    builder: (c) => teamMetricsChart(
      c,
      [(TeamMetric.goalsFor, ChartPalette.goalsFor), (TeamMetric.goalsAgainst, ChartPalette.goalsAgainst)],
      SeriesKind.stackedBar,
      yTitle: 'Goles',
      teams: [...c.teams]..sort((a, b) => (b.goalsFor + b.goalsAgainst).compareTo(a.goalsFor + a.goalsAgainst)),
    ),
  ),
  ChartDefinition(
    id: 'clean-sheets',
    category: ChartCategory.goals,
    title: 'Porterías a cero',
    description: 'Partidos en los que el equipo no encajó ningún gol.',
    chartType: 'Column',
    scope: ChartScope.ranking,
    builder: (c) => TeamRankingChart(
      teams: c.teams,
      metric: TeamMetric.cleanSheets,
      kind: SeriesKind.column,
      color: ChartPalette.primary,
      highlightKey: c.team?.key,
    ),
  ),
  ChartDefinition(
    id: 'failed-to-score',
    category: ChartCategory.goals,
    title: 'Partidos sin marcar',
    description: 'Partidos en los que el equipo no anotó ningún gol.',
    chartType: 'Bar',
    scope: ChartScope.ranking,
    height: ChartSizing.teamRows,
    builder: (c) => TeamRankingChart(
      teams: c.teams,
      metric: TeamMetric.failedToScore,
      color: ChartPalette.loss,
      highlightKey: c.team?.key,
    ),
  ),
];
