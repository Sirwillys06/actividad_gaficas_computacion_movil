import '../../../core/theme/chart_palette.dart';
import '../../../core/utils/stats_utils.dart';
import '../../../data/mappers/team_series_mapper.dart';
import '../../../data/models/chart_point.dart';
import '../../../data/models/team_metric.dart';
import '../../../data/models/team_stats.dart';
import '../components/breakdown_chart.dart';
import '../components/category_chart.dart';
import '../components/team_ranking_chart.dart';
import 'catalog_helpers.dart';
import 'chart_definition.dart';

final _keyIndicators = <TeamMetric>[
  TeamMetric.points,
  TeamMetric.wins,
  TeamMetric.draws,
  TeamMetric.losses,
  TeamMetric.goalsFor,
  TeamMetric.goalsAgainst,
];

final _perMatchIndicators = <TeamMetric>[
  TeamMetric.pointsPerMatch,
  TeamMetric.goalsForPerMatch,
  TeamMetric.goalsAgainstPerMatch,
];

final _homePoints = TeamMetric('Puntos como local', (t) => t.home.points.toDouble(), unit: 'pts');
final _awayPoints = TeamMetric('Puntos como visitante', (t) => t.away.points.toDouble(), unit: 'pts');

List<LabeledValue> _indicators(List<TeamMetric> metrics, double Function(TeamMetric metric) value) => [
  for (final metric in metrics) LabeledValue(metric.label, value(metric)),
];

double _groupMean(List<TeamStats> teams, TeamMetric metric) => StatsUtils.mean(teams.map(metric.value));

String? _needsRounds(ChartContext c) =>
    c.analytics.rounds.length < 2 ? 'Se necesitan al menos dos jornadas con marcador.' : null;

final List<ChartDefinition> comparisonCharts = [
  ChartDefinition(
    id: 'compared-key-indicators',
    category: ChartCategory.comparisons,
    title: 'Indicadores clave de los equipos comparados',
    description: 'Puntos, victorias, empates, derrotas y goles de cada equipo seleccionado, lado a lado.',
    chartType: 'Column agrupado',
    scope: ChartScope.comparison,
    builder: (c) => CategoryChart<LabeledValue>(
      xTitle: 'Indicador',
      yTitle: 'Valor',
      integerY: true,
      series: [
        for (var i = 0; i < c.compared.length; i++)
          valueSeries(
            c.compared[i].name,
            _indicators(_keyIndicators, (m) => m.value(c.compared[i])),
            SeriesKind.column,
            color: ChartPalette.at(i),
          ),
      ],
    ),
  ),
  ChartDefinition(
    id: 'attack-vs-defense-bars',
    category: ChartCategory.comparisons,
    title: 'Ataque vs defensa por equipo',
    description:
        'Goles a favor y en contra por partido de cada equipo: cuanto más larga la barra verde y más corta la roja, mejor.',
    chartType: 'Bar agrupado',
    scope: ChartScope.ranking,
    height: (c) => ChartSizing.teamRows(c, perRow: 36),
    builder: (c) => teamMetricsChart(
      c,
      [
        (TeamMetric.goalsForPerMatch, ChartPalette.goalsFor),
        (TeamMetric.goalsAgainstPerMatch, ChartPalette.goalsAgainst),
      ],
      SeriesKind.bar,
      yTitle: 'Goles por partido',
    ),
  ),
  ChartDefinition(
    id: 'compared-home-away-points',
    category: ChartCategory.comparisons,
    title: 'Puntos local y visitante de los equipos comparados',
    description: 'Contribución de los partidos en casa y fuera al total de puntos de cada equipo seleccionado.',
    chartType: 'Stacked Bar',
    scope: ChartScope.comparison,
    height: (c) => ChartSizing.forRows(c.compared.length, perRow: 48, min: 300),
    builder: (c) => teamMetricsChart(
      c,
      [(_homePoints, ChartPalette.home), (_awayPoints, ChartPalette.away)],
      SeriesKind.stackedBar,
      yTitle: 'Puntos',
      teams: c.compared,
      labels: true,
    ),
  ),
  ChartDefinition(
    id: 'compared-points-evolution',
    category: ChartCategory.comparisons,
    title: 'Evolución de puntos de varios equipos',
    description: 'Puntos acumulados por jornada de los equipos comparados.',
    chartType: 'Line',
    scope: ChartScope.comparison,
    availability: _needsRounds,
    builder: (c) => CategoryChart<LabeledValue>(
      xTitle: c.analytics.roundUnit,
      yTitle: 'Puntos acumulados',
      integerY: true,
      enableTrackball: true,
      enableZoom: true,
      series: comparedSeries(c.compared, (t) => TeamSeriesMapper.pointsByRound(c.analytics, t), SeriesKind.line),
    ),
  ),
  ChartDefinition(
    id: 'compared-goal-difference-evolution',
    category: ChartCategory.comparisons,
    title: 'Evolución de la diferencia de goles',
    description: 'Diferencia de goles acumulada por jornada de los equipos comparados.',
    chartType: 'Spline',
    scope: ChartScope.comparison,
    availability: _needsRounds,
    builder: (c) => CategoryChart<LabeledValue>(
      xTitle: c.analytics.roundUnit,
      yTitle: 'Diferencia de goles',
      integerY: true,
      enableTrackball: true,
      enableZoom: true,
      series: comparedSeries(
        c.compared,
        (t) => TeamSeriesMapper.goalDifferenceByRound(c.analytics, t),
        SeriesKind.spline,
      ),
    ),
  ),
  ChartDefinition(
    id: 'top-vs-bottom',
    category: ChartCategory.comparisons,
    title: 'Top 5 vs Bottom 5 vs media de la liga',
    description: 'Promedios por partido de los cinco primeros, los cinco últimos y el conjunto de la liga.',
    chartType: 'Column agrupado',
    availability: (c) => c.analytics.standings.length < 10 ? 'Se necesitan al menos 10 equipos.' : null,
    builder: (c) {
      final all = c.analytics.standings;
      final top = all.take(5).toList();
      final bottom = all.sublist(all.length - 5);
      SeriesSpec<LabeledValue> group(String name, List<TeamStats> teams, int color) => valueSeries(
        name,
        _indicators(_perMatchIndicators, (m) => _groupMean(teams, m)),
        SeriesKind.column,
        color: ChartPalette.at(color),
        labels: true,
        format: (v) => v.toStringAsFixed(2),
      );
      return CategoryChart<LabeledValue>(
        xTitle: 'Indicador (por partido)',
        yTitle: 'Promedio',
        yMinimum: 0,
        series: [group('Top 5', top, 0), group('Bottom 5', bottom, 4), group('Liga', all, 1)],
      );
    },
  ),
  ChartDefinition(
    id: 'head-to-head',
    category: ChartCategory.comparisons,
    title: 'Enfrentamientos directos',
    description: 'Resultados de los partidos entre los dos primeros equipos comparados en la temporada.',
    chartType: 'Doughnut',
    scope: ChartScope.comparison,
    availability: (c) =>
        c.compared.length >= 2 &&
            TeamSeriesMapper.headToHead(c.compared[0], c.compared[1]).every((item) => item.value == 0)
        ? 'Estos equipos aún no se han enfrentado en los partidos disponibles.'
        : null,
    builder: (c) => BreakdownChart(
      kind: BreakdownKind.doughnut,
      colors: const [ChartPalette.primary, ChartPalette.draw, ChartPalette.home],
      data: TeamSeriesMapper.headToHead(c.compared[0], c.compared[1]).where((item) => item.value > 0).toList(),
      centerText: '${c.compared[0].name}\nvs\n${c.compared[1].name}',
    ),
  ),
  ChartDefinition(
    id: 'points-vs-mean',
    category: ChartCategory.comparisons,
    title: 'Puntos respecto a la media',
    description: 'Puntos de cada equipo por encima (verde) o por debajo (rojo) de la media de la liga.',
    chartType: 'Bar divergente',
    scope: ChartScope.ranking,
    height: ChartSizing.teamRows,
    builder: (c) {
      final mean = _groupMean(c.analytics.standings, TeamMetric.points);
      return TeamRankingChart(
        teams: c.teams,
        metric: TeamMetric('Puntos sobre la media', (t) => t.points - mean, unit: 'pts', isDecimal: true),
        signedColors: true,
        showAverage: false,
        referenceValue: 0,
        highlightKey: c.team?.key,
      );
    },
  ),
];
