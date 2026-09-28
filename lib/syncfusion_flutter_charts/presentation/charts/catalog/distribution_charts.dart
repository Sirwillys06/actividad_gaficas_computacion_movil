import '../../../core/theme/chart_palette.dart';
import '../../../data/mappers/chart_data_mapper.dart';
import '../../../data/mappers/team_series_mapper.dart';
import '../../../data/models/chart_point.dart';
import '../../../data/models/team_metric.dart';
import '../components/breakdown_chart.dart';
import '../components/category_chart.dart';
import '../components/distribution_charts.dart';
import '../components/team_ranking_chart.dart';
import 'catalog_helpers.dart';
import 'chart_definition.dart';

final List<ChartDefinition> distributionCharts = [
  ChartDefinition(
    id: 'goals-boxplot-by-round',
    category: ChartCategory.distribution,
    title: 'Distribución de goles por jornada',
    description: 'Mediana, cuartiles, media y valores atípicos de los goles por partido en cada jornada.',
    chartType: 'Box and Whisker',
    availability: (c) => c.analytics.rounds.isEmpty ? 'No hay jornadas con marcador.' : null,
    builder: (c) => BoxPlotChart(
      groups: [for (final r in c.analytics.rounds) ValueGroup(r.label, r.goalsPerMatch)],
      xTitle: c.analytics.roundUnit,
      yTitle: 'Goles por partido',
    ),
  ),
  ChartDefinition(
    id: 'team-goals-boxplot',
    category: ChartCategory.distribution,
    title: 'Distribución de goles a favor por equipo',
    description: 'Variabilidad de los goles marcados por partido de los equipos comparados.',
    chartType: 'Box and Whisker',
    scope: ChartScope.comparison,
    builder: (c) => BoxPlotChart(
      groups: [for (final t in c.compared) ValueGroup(t.name, TeamSeriesMapper.goalsForPerMatch(t))],
      xTitle: 'Equipo',
      yTitle: 'Goles a favor por partido',
      color: ChartPalette.primary,
    ),
  ),
  ChartDefinition(
    id: 'matches-by-weekday',
    category: ChartCategory.distribution,
    title: 'Partidos por día de la semana',
    description: 'En qué días se disputan los partidos, según la fecha publicada por TheSportsDB.',
    chartType: 'Column',
    availability: (c) => ChartDataMapper.matchesByWeekday(c.analytics.scoredEvents).isEmpty
        ? 'TheSportsDB no informó fechas para estos partidos.'
        : null,
    builder: (c) => CategoryChart<LabeledValue>(
      xTitle: 'Día de la semana',
      yTitle: 'Partidos',
      integerY: true,
      showLegend: false,
      series: [
        valueSeries(
          'Partidos',
          ChartDataMapper.matchesByWeekday(c.analytics.scoredEvents),
          SeriesKind.column,
          color: ChartPalette.home,
          labels: true,
          format: (v) => v.round().toString(),
        ),
      ],
    ),
  ),
  ChartDefinition(
    id: 'goals-by-weekday',
    category: ChartCategory.distribution,
    title: 'Goles por partido según el día',
    description: 'Promedio de goles por partido para cada día de la semana.',
    chartType: 'Line',
    availability: (c) => ChartDataMapper.averageGoalsByWeekday(c.analytics.scoredEvents).length < 2
        ? 'Se necesitan partidos en al menos dos días distintos.'
        : null,
    builder: (c) => CategoryChart<LabeledValue>(
      xTitle: 'Día de la semana',
      yTitle: 'Goles por partido',
      yMinimum: 0,
      showLegend: false,
      series: [
        valueSeries(
          'Goles por partido',
          ChartDataMapper.averageGoalsByWeekday(c.analytics.scoredEvents),
          SeriesKind.line,
          color: ChartPalette.highlight,
          labels: true,
          format: (v) => v.toStringAsFixed(2),
        ),
      ],
    ),
  ),
  ChartDefinition(
    id: 'matches-by-hour',
    category: ChartCategory.distribution,
    title: 'Partidos por hora de inicio (UTC)',
    description: 'Horarios de inicio según strTime/strTimestamp de TheSportsDB, expresados en UTC.',
    chartType: 'Column',
    availability: (c) => ChartDataMapper.matchesByKickoffHour(c.analytics.scoredEvents).isEmpty
        ? 'TheSportsDB no informó la hora de inicio de estos partidos.'
        : null,
    builder: (c) => CategoryChart<LabeledValue>(
      xTitle: 'Hora de inicio (UTC)',
      yTitle: 'Partidos',
      integerY: true,
      showLegend: false,
      series: [
        valueSeries(
          'Partidos',
          ChartDataMapper.matchesByKickoffHour(c.analytics.scoredEvents),
          SeriesKind.column,
          color: ChartPalette.away,
          labels: true,
          format: (v) => v.round().toString(),
        ),
      ],
    ),
  ),
  ChartDefinition(
    id: 'over-under',
    category: ChartCategory.distribution,
    title: 'Más / menos de 2.5 goles',
    description: 'Partidos con 3 o más goles frente a partidos con 2 o menos.',
    chartType: 'Doughnut',
    builder: (c) => BreakdownChart(
      kind: BreakdownKind.doughnut,
      colors: const [ChartPalette.primary, ChartPalette.neutral],
      data: ChartDataMapper.overUnder(c.analytics.scoredEvents),
      centerText: '${c.analytics.scoredEvents.length}\npartidos',
    ),
  ),
  ChartDefinition(
    id: 'both-teams-scored',
    category: ChartCategory.distribution,
    title: 'Partidos en los que marcan ambos equipos',
    description: 'Porcentaje de partidos de cada equipo en los que marcaron los dos contendientes.',
    chartType: 'Bar',
    scope: ChartScope.ranking,
    height: ChartSizing.teamRows,
    builder: (c) => TeamRankingChart(
      teams: c.teams,
      metric: TeamMetric.bothTeamsScoredRate,
      color: ChartPalette.draw,
      minimum: 0,
      maximum: 100,
      highlightKey: c.team?.key,
    ),
  ),
  ChartDefinition(
    id: 'goals-histogram',
    category: ChartCategory.distribution,
    title: 'Histograma de goles por partido',
    description: 'Frecuencia de partidos según sus goles totales, con la curva normal ajustada.',
    chartType: 'Histogram',
    builder: (c) => HistogramChart(
      values: ChartDataMapper.totalGoals(c.analytics.scoredEvents),
      xTitle: 'Goles en el partido',
      yTitle: 'Partidos',
    ),
  ),
];
