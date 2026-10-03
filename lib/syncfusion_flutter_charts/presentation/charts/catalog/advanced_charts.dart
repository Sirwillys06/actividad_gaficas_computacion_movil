import '../../../data/mappers/team_series_mapper.dart';
import '../../../data/models/team_metric.dart';
import '../components/range_chart.dart';
import 'catalog_helpers.dart';
import 'chart_definition.dart';

String? _needsThreeTeams(ChartContext c) =>
    c.teams.length < 3 ? 'Se necesitan al menos tres equipos para analizar la relación.' : null;

final List<ChartDefinition> advancedCharts = [
  ChartDefinition(
    id: 'attack-defense-scatter',
    category: ChartCategory.advanced,
    title: 'Ataque vs defensa',
    description:
        'Goles a favor (X) frente a goles en contra (Y). Abajo a la derecha: equipos que marcan mucho y encajan poco.',
    chartType: 'Scatter',
    scope: ChartScope.ranking,
    builder: (c) => teamScatter(c, TeamMetric.goalsFor, TeamMetric.goalsAgainst, averages: true),
  ),
  ChartDefinition(
    id: 'goals-for-vs-points',
    category: ChartCategory.advanced,
    title: 'Goles a favor vs puntos',
    description: 'Relación entre capacidad goleadora y puntos, con recta de regresión lineal.',
    chartType: 'Scatter + Trendline',
    scope: ChartScope.ranking,
    availability: _needsThreeTeams,
    builder: (c) => teamScatter(c, TeamMetric.goalsFor, TeamMetric.points, trendline: true),
  ),
  ChartDefinition(
    id: 'goals-against-vs-losses',
    category: ChartCategory.advanced,
    title: 'Goles en contra vs derrotas',
    description: 'Cuánto se asocian los goles encajados con las derrotas, con recta de regresión lineal.',
    chartType: 'Scatter + Trendline',
    scope: ChartScope.ranking,
    availability: _needsThreeTeams,
    builder: (c) => teamScatter(c, TeamMetric.goalsAgainst, TeamMetric.losses, trendline: true),
  ),
  ChartDefinition(
    id: 'goal-difference-vs-points',
    category: ChartCategory.advanced,
    title: 'Diferencia de goles vs puntos',
    description: 'Los equipos por encima de la recta suman más puntos de los que su diferencia de goles sugiere.',
    chartType: 'Scatter + Trendline',
    scope: ChartScope.ranking,
    availability: _needsThreeTeams,
    builder: (c) => teamScatter(c, TeamMetric.goalDifference, TeamMetric.points, trendline: true),
  ),
  ChartDefinition(
    id: 'teams-bubble',
    category: ChartCategory.advanced,
    title: 'Comparación global de equipos',
    description: 'Goles a favor (X), goles en contra (Y) y puntos (tamaño de la burbuja).',
    chartType: 'Bubble',
    scope: ChartScope.ranking,
    builder: (c) => teamScatter(c, TeamMetric.goalsFor, TeamMetric.goalsAgainst, size: TeamMetric.points),
  ),
  ChartDefinition(
    id: 'avg-goals-vs-win-rate',
    category: ChartCategory.advanced,
    title: 'Promedio de goles vs % de victorias',
    description: 'Goles a favor por partido frente al porcentaje de victorias, con tendencia lineal.',
    chartType: 'Scatter + Trendline',
    scope: ChartScope.ranking,
    availability: _needsThreeTeams,
    builder: (c) => teamScatter(c, TeamMetric.goalsForPerMatch, TeamMetric.winRate, trendline: true),
  ),
  ChartDefinition(
    id: 'played-vs-points',
    category: ChartCategory.advanced,
    title: 'Partidos jugados vs puntos',
    description: 'Detecta equipos con partidos de menos o de más que distorsionan la clasificación.',
    chartType: 'Scatter',
    scope: ChartScope.ranking,
    builder: (c) => teamScatter(c, TeamMetric.played, TeamMetric.points, averages: true),
  ),
  ChartDefinition(
    id: 'goals-consistency',
    category: ChartCategory.advanced,
    title: 'Regularidad goleadora',
    description: 'Media de goles a favor por partido ± desviación típica: barras cortas indican equipos más regulares.',
    chartType: 'Hilo + Scatter',
    scope: ChartScope.ranking,
    builder: (c) => MeanDeviationChart(
      items: [for (final team in c.teams) TeamSeriesMapper.goalsDeviation(team)],
      xTitle: 'Equipo',
      yTitle: 'Goles a favor por partido',
    ),
  ),
];
