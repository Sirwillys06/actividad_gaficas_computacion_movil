import '../../../core/constants/app_constants.dart';
import '../../../core/theme/chart_palette.dart';
import '../../../data/mappers/team_series_mapper.dart';
import '../../../data/models/match_result.dart';
import '../../../data/models/team_metric.dart';
import '../../../data/models/team_stats.dart';
import '../components/breakdown_chart.dart';
import '../components/category_chart.dart';
import '../components/team_ranking_chart.dart';
import '../components/waterfall_chart.dart';
import 'catalog_helpers.dart';
import 'chart_definition.dart';

final List<ChartDefinition> performanceCharts = [
  ChartDefinition(
    id: 'team-profile-radial',
    category: ChartCategory.performance,
    title: 'Perfil de rendimiento del equipo',
    description:
        'Índices 0–100 relativos a la liga: ataque, defensa, rendimiento, victorias, porterías a cero y forma. '
        'Syncfusion Flutter Charts no incluye series radar/polar, por eso se representa con barras radiales.',
    chartType: 'Radial Bar',
    scope: ChartScope.team,
    height: (_) => 380,
    builder: (c) => BreakdownChart(
      kind: BreakdownKind.radialBar,
      maximumValue: 100,
      data: TeamSeriesMapper.performanceProfile(c.analytics, c.team!),
    ),
  ),
  ChartDefinition(
    id: 'profile-comparison',
    category: ChartCategory.performance,
    title: 'Comparativa de perfiles',
    description: 'Los mismos índices 0–100 para varios equipos a la vez (alternativa al radar comparativo).',
    chartType: 'Column agrupado normalizado',
    scope: ChartScope.comparison,
    builder: (c) => CategoryChart<MatchResult>(
      xTitle: 'Indicador',
      yTitle: 'Índice (0–100)',
      yMinimum: 0,
      yMaximum: 100,
      series: [
        for (var i = 0; i < c.compared.length; i++)
          SeriesSpec<MatchResult>(
            name: c.compared[i].name,
            data: TeamSeriesMapper.performanceProfile(c.analytics, c.compared[i]),
            x: (item) => item.label,
            y: (item) => item.value,
            color: ChartPalette.at(i),
            tooltip: (item) => '${c.compared[i].name}\n${item.label}: ${item.value.toStringAsFixed(1)}',
          ),
      ],
    ),
  ),
  ChartDefinition(
    id: 'home-performance',
    category: ChartCategory.performance,
    title: 'Rendimiento como local',
    description: 'Porcentaje de puntos obtenidos en los partidos disputados en casa.',
    chartType: 'Bar',
    scope: ChartScope.ranking,
    height: ChartSizing.teamRows,
    builder: (c) => TeamRankingChart(
      teams: c.teams,
      metric: TeamMetric.homePerformance,
      color: ChartPalette.home,
      minimum: 0,
      maximum: 100,
      highlightKey: c.team?.key,
    ),
  ),
  ChartDefinition(
    id: 'away-performance',
    category: ChartCategory.performance,
    title: 'Rendimiento como visitante',
    description: 'Porcentaje de puntos obtenidos fuera de casa.',
    chartType: 'Bar',
    scope: ChartScope.ranking,
    height: ChartSizing.teamRows,
    builder: (c) => TeamRankingChart(
      teams: c.teams,
      metric: TeamMetric.awayPerformance,
      color: ChartPalette.away,
      minimum: 0,
      maximum: 100,
      highlightKey: c.team?.key,
    ),
  ),
  ChartDefinition(
    id: 'ppg-home-away',
    category: ChartCategory.performance,
    title: 'Puntos por partido: local vs visitante',
    description: 'Eficiencia en puntos de cada equipo según juegue en casa o fuera.',
    chartType: 'Column agrupado',
    scope: ChartScope.ranking,
    builder: (c) => teamMetricsChart(
      c,
      [(TeamMetric.homePointsPerMatch, ChartPalette.home), (TeamMetric.awayPointsPerMatch, ChartPalette.away)],
      SeriesKind.column,
      yTitle: 'Puntos por partido',
    ),
  ),
  ChartDefinition(
    id: 'recent-form',
    category: ChartCategory.performance,
    title: 'Forma reciente',
    description:
        'Puntos logrados en los últimos ${AppConstants.recentFormMatches} partidos con marcador de cada equipo.',
    chartType: 'Column',
    scope: ChartScope.ranking,
    builder: (c) => TeamRankingChart(
      teams: c.teams,
      metric: TeamMetric.recentForm,
      kind: SeriesKind.column,
      color: ChartPalette.highlight,
      minimum: 0,
      maximum: (AppConstants.recentFormMatches * AppConstants.pointsPerWin).toDouble(),
      highlightKey: c.team?.key,
    ),
  ),
  ChartDefinition(
    id: 'goal-difference-waterfall',
    category: ChartCategory.performance,
    title: 'Cascada de diferencia de goles',
    description: 'Cómo cada partido del equipo suma o resta a su diferencia de goles hasta el total actual.',
    chartType: 'Waterfall',
    scope: ChartScope.team,
    builder: (c) => WaterfallChart(
      steps: TeamSeriesMapper.goalDifferenceSteps(c.team!),
      xTitle: 'Partido',
      yTitle: 'Diferencia de goles',
      totalLabel: 'Total',
    ),
  ),
  ChartDefinition(
    id: 'team-match-goals',
    category: ChartCategory.performance,
    title: 'Goles a favor y en contra partido a partido',
    description: 'Goles marcados (arriba) y encajados (abajo) por el equipo en cada partido.',
    chartType: 'Stacked Column divergente',
    scope: ChartScope.team,
    builder: (c) {
      final matches = c.team!.matches;
      SeriesSpec<TeamMatch> spec(String name, bool against) => SeriesSpec<TeamMatch>(
        name: name,
        data: matches,
        kind: SeriesKind.stackedColumn,
        color: against ? ChartPalette.goalsAgainst : ChartPalette.goalsFor,
        x: TeamSeriesMapper.matchLabel,
        y: (m) => against ? -m.goalsAgainst : m.goalsFor,
        tooltip: (m) => '${m.label}\n$name: ${against ? m.goalsAgainst : m.goalsFor}',
      );
      return CategoryChart<TeamMatch>(
        xTitle: 'Partido',
        yTitle: 'Goles (encajados en negativo)',
        integerY: true,
        visibleCount: matches.length > 20 ? 20 : null,
        series: [spec('Goles a favor', false), spec('Goles en contra', true)],
      );
    },
  ),
];
