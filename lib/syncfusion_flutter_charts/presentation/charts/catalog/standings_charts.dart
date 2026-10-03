import '../../../core/theme/chart_palette.dart';
import '../../../data/mappers/team_series_mapper.dart';
import '../../../data/models/chart_point.dart';
import '../../../data/models/team_metric.dart';
import '../components/category_chart.dart';
import '../components/range_chart.dart';
import '../components/team_ranking_chart.dart';
import 'catalog_helpers.dart';
import 'chart_definition.dart';

String? _needsRounds(ChartContext c) =>
    c.analytics.rounds.length < 2 ? 'Se necesitan al menos dos jornadas con marcador.' : null;

final List<ChartDefinition> standingsCharts = [
  ChartDefinition(
    id: 'points-by-team',
    category: ChartCategory.standings,
    title: 'Puntos por equipo',
    description: 'Clasificación calculada (3 pts victoria, 1 empate) a partir de los partidos con marcador.',
    chartType: 'Bar',
    scope: ChartScope.ranking,
    height: ChartSizing.teamRows,
    builder: (c) => TeamRankingChart(teams: c.teams, metric: TeamMetric.points, highlightKey: c.team?.key),
  ),
  ChartDefinition(
    id: 'matches-played',
    category: ChartCategory.standings,
    title: 'Partidos jugados',
    description:
        'Partidos con marcador disputados por cada equipo. Detecta calendarios desiguales o partidos pendientes.',
    chartType: 'Column',
    scope: ChartScope.ranking,
    builder: (c) => TeamRankingChart(
      teams: c.teams,
      metric: TeamMetric.played,
      kind: SeriesKind.column,
      color: ChartPalette.neutral,
      highlightKey: c.team?.key,
    ),
  ),
  ChartDefinition(
    id: 'points-per-match',
    category: ChartCategory.standings,
    title: 'Puntos por partido',
    description: 'Normaliza los puntos por partidos jugados para comparar equipos con distinto número de encuentros.',
    chartType: 'Bar + línea de media',
    scope: ChartScope.ranking,
    height: ChartSizing.teamRows,
    builder: (c) => TeamRankingChart(
      teams: c.teams,
      metric: TeamMetric.pointsPerMatch,
      color: ChartPalette.home,
      highlightKey: c.team?.key,
      minimum: 0,
      maximum: 3,
    ),
  ),
  ChartDefinition(
    id: 'performance-percent',
    category: ChartCategory.standings,
    title: 'Rendimiento porcentual',
    description: 'Porcentaje de los puntos posibles que ha conseguido cada equipo (puntos / (3 × PJ)).',
    chartType: 'Bar',
    scope: ChartScope.ranking,
    height: ChartSizing.teamRows,
    builder: (c) => TeamRankingChart(
      teams: c.teams,
      metric: TeamMetric.performance,
      color: ChartPalette.away,
      minimum: 0,
      maximum: 100,
      referenceValue: 50,
      referenceLabel: '50 %',
      highlightKey: c.team?.key,
    ),
  ),
  ChartDefinition(
    id: 'position-evolution',
    category: ChartCategory.standings,
    title: 'Evolución de la posición',
    description: 'Puesto en la tabla calculada al cierre de cada jornada para los equipos comparados (1 = líder).',
    chartType: 'Line (eje Y invertido)',
    scope: ChartScope.comparison,
    availability: _needsRounds,
    builder: (c) => CategoryChart<LabeledValue>(
      xTitle: c.analytics.roundUnit,
      yTitle: 'Posición',
      yInversed: true,
      yMinimum: 1,
      yMaximum: c.analytics.standings.length.toDouble(),
      yInterval: c.analytics.standings.length > 12 ? 2 : 1,
      enableTrackball: true,
      enableZoom: true,
      showLegend: true,
      series: comparedSeries(c.compared, (t) => TeamSeriesMapper.positionByRound(c.analytics, t), SeriesKind.line),
    ),
  ),
  ChartDefinition(
    id: 'points-vs-leader',
    category: ChartCategory.standings,
    title: 'Puntos acumulados: equipo vs líder',
    description: 'Puntos acumulados jornada a jornada del equipo seleccionado frente al líder actual de la tabla.',
    chartType: 'Step Line',
    scope: ChartScope.team,
    availability: _needsRounds,
    builder: (c) {
      final leader = c.analytics.standings.first;
      final team = c.team!;
      return CategoryChart<LabeledValue>(
        xTitle: c.analytics.roundUnit,
        yTitle: 'Puntos acumulados',
        yMinimum: 0,
        enableTrackball: true,
        enableZoom: true,
        showLegend: true,
        series: [
          valueSeries(
            team.name,
            TeamSeriesMapper.pointsByRound(c.analytics, team),
            SeriesKind.stepLine,
            color: ChartPalette.highlight,
          ),
          if (leader.key != team.key)
            valueSeries(
              '${leader.name} (líder)',
              TeamSeriesMapper.pointsByRound(c.analytics, leader),
              SeriesKind.stepLine,
              color: ChartPalette.primary,
            ),
        ],
      );
    },
  ),
  ChartDefinition(
    id: 'gap-to-leader',
    category: ChartCategory.standings,
    title: 'Distancia al líder',
    description: 'Puntos que separan a cada equipo del primer clasificado.',
    chartType: 'Column',
    scope: ChartScope.ranking,
    builder: (c) {
      final leaderPoints = c.analytics.standings.first.points;
      return TeamRankingChart(
        teams: c.teams,
        metric: TeamMetric('Puntos por detrás del líder', (t) => (leaderPoints - t.points).toDouble(), unit: 'pts'),
        kind: SeriesKind.column,
        ascending: true,
        color: ChartPalette.loss,
        showAverage: false,
        highlightKey: c.team?.key,
      );
    },
  ),
  ChartDefinition(
    id: 'points-range',
    category: ChartCategory.standings,
    title: 'Horquilla de puntos de la liga',
    description:
        'Mínimo y máximo de puntos acumulados en la liga por jornada, con la trayectoria del equipo seleccionado.',
    chartType: 'Range Area + Line',
    scope: ChartScope.team,
    availability: _needsRounds,
    builder: (c) => RangeChart(
      points: TeamSeriesMapper.leaguePointsRange(c.analytics),
      kind: RangeKind.rangeArea,
      rangeName: 'Mínimo – máximo de la liga',
      xTitle: c.analytics.roundUnit,
      yTitle: 'Puntos acumulados',
      overlay: TeamSeriesMapper.pointsByRound(c.analytics, c.team!),
      overlayName: c.team!.name,
    ),
  ),
];
