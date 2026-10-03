import '../../../core/theme/chart_palette.dart';
import '../../../core/utils/stats_utils.dart';
import '../../../data/mappers/team_series_mapper.dart';
import '../../../data/models/chart_point.dart';
import '../../../data/models/round_stats.dart';
import '../components/category_chart.dart';
import '../components/chart_kit.dart';
import '../components/range_chart.dart';
import 'catalog_helpers.dart';
import 'chart_definition.dart';

String? _needsRounds(ChartContext c) =>
    c.analytics.rounds.length < 2 ? 'Se necesitan al menos dos jornadas con marcador.' : null;

String? _needsTwoMatches(ChartContext c) =>
    (c.team?.played ?? 0) < 2 ? 'El equipo necesita al menos dos partidos con marcador.' : null;

final List<ChartDefinition> evolutionCharts = [
  ChartDefinition(
    id: 'goals-by-round',
    category: ChartCategory.evolution,
    title: 'Goles por jornada',
    description: 'Total de goles marcados en cada jornada, con la media por jornada como referencia.',
    chartType: 'Column',
    availability: _needsRounds,
    builder: (c) {
      final rounds = c.analytics.rounds;
      final mean = StatsUtils.mean(rounds.map((r) => r.goals));
      return CategoryChart<RoundStats>(
        xTitle: c.analytics.roundUnit,
        yTitle: 'Goles',
        integerY: true,
        showLegend: false,
        visibleCount: rounds.length > 20 ? 20 : null,
        plotBands: [ChartKit.referenceLine(mean, 'Media ${mean.toStringAsFixed(1)}')],
        series: [roundSeries('Goles', rounds, (r) => r.goals, SeriesKind.column, color: ChartPalette.primary)],
      );
    },
  ),
  ChartDefinition(
    id: 'average-goals-by-round',
    category: ChartCategory.evolution,
    title: 'Promedio de goles por partido en cada jornada',
    description: 'Goles por partido de cada jornada frente a la media de la temporada.',
    chartType: 'Spline',
    availability: _needsRounds,
    builder: (c) => CategoryChart<RoundStats>(
      xTitle: c.analytics.roundUnit,
      yTitle: 'Goles por partido',
      yMinimum: 0,
      enableTrackball: true,
      enableZoom: true,
      showLegend: false,
      plotBands: [
        ChartKit.referenceLine(c.analytics.averageGoals, 'Temporada ${c.analytics.averageGoals.toStringAsFixed(2)}'),
      ],
      series: [
        roundSeries(
          'Goles por partido',
          c.analytics.rounds,
          (r) => r.averageGoals,
          SeriesKind.spline,
          color: ChartPalette.home,
        ),
      ],
    ),
  ),
  ChartDefinition(
    id: 'outcomes-by-round',
    category: ChartCategory.evolution,
    title: 'Victorias, empates y derrotas por jornada',
    description: 'Número de victorias locales, empates y victorias visitantes (derrotas locales) en cada jornada.',
    chartType: 'Line',
    availability: _needsRounds,
    builder: (c) => CategoryChart<RoundStats>(
      xTitle: c.analytics.roundUnit,
      yTitle: 'Partidos',
      integerY: true,
      enableTrackball: true,
      enableZoom: true,
      series: [
        roundSeries(
          'Victorias locales',
          c.analytics.rounds,
          (r) => r.homeWins,
          SeriesKind.line,
          color: ChartPalette.home,
        ),
        roundSeries('Empates', c.analytics.rounds, (r) => r.draws, SeriesKind.line, color: ChartPalette.draw),
        roundSeries(
          'Victorias visitantes',
          c.analytics.rounds,
          (r) => r.awayWins,
          SeriesKind.line,
          color: ChartPalette.away,
        ),
      ],
    ),
  ),
  ChartDefinition(
    id: 'cumulative-league-goals',
    category: ChartCategory.evolution,
    title: 'Evolución acumulada de goles',
    description: 'Goles acumulados en la liga al cierre de cada jornada.',
    chartType: 'Area',
    availability: _needsRounds,
    builder: (c) {
      var total = 0;
      final data = [
        for (final round in c.analytics.rounds) LabeledValue(round.label, (total += round.goals).toDouble()),
      ];
      return CategoryChart<LabeledValue>(
        xTitle: c.analytics.roundUnit,
        yTitle: 'Goles acumulados',
        integerY: true,
        enableTrackball: true,
        enableZoom: true,
        showLegend: false,
        series: [valueSeries('Goles acumulados', data, SeriesKind.area, color: ChartPalette.primary)],
      );
    },
  ),
  ChartDefinition(
    id: 'team-performance-evolution',
    category: ChartCategory.evolution,
    title: 'Evolución del rendimiento del equipo',
    description: 'Porcentaje de puntos obtenidos acumulado partido a partido por el equipo seleccionado.',
    chartType: 'Spline Area',
    scope: ChartScope.team,
    availability: _needsTwoMatches,
    builder: (c) {
      final data = [
        for (final m in c.team!.matches)
          LabeledValue(
            TeamSeriesMapper.matchLabel(m),
            StatsUtils.percent(m.cumulativePoints, m.order * 3),
            detail: m.label,
          ),
      ];
      return CategoryChart<LabeledValue>(
        xTitle: 'Partido',
        yTitle: 'Rendimiento acumulado (%)',
        yMinimum: 0,
        yMaximum: 100,
        enableTrackball: true,
        showLegend: false,
        plotBands: [ChartKit.referenceLine(50, '50 %', color: ChartPalette.neutral)],
        series: [
          valueSeries(
            'Rendimiento',
            data,
            SeriesKind.splineArea,
            color: ChartPalette.away,
            format: (v) => '${v.toStringAsFixed(1)} %',
          ),
        ],
      );
    },
  ),
  ChartDefinition(
    id: 'team-cumulative-goals',
    category: ChartCategory.evolution,
    title: 'Goles acumulados del equipo',
    description: 'Goles a favor y en contra acumulados partido a partido por el equipo seleccionado.',
    chartType: 'Step Area',
    scope: ChartScope.team,
    availability: _needsTwoMatches,
    builder: (c) => CategoryChart<LabeledValue>(
      xTitle: 'Partido',
      yTitle: 'Goles acumulados',
      integerY: true,
      enableTrackball: true,
      series: [
        valueSeries(
          'Goles a favor',
          TeamSeriesMapper.cumulativeGoalsFor(c.team!),
          SeriesKind.stepArea,
          color: ChartPalette.goalsFor,
        ),
        valueSeries(
          'Goles en contra',
          TeamSeriesMapper.cumulativeGoalsAgainst(c.team!),
          SeriesKind.stepArea,
          color: ChartPalette.goalsAgainst,
        ),
      ],
    ),
  ),
  ChartDefinition(
    id: 'team-home-away-evolution',
    category: ChartCategory.evolution,
    title: 'Evolución local y visitante del equipo',
    description: 'Puntos acumulados en casa y fuera, según el número de partido disputado en cada condición.',
    chartType: 'Line',
    scope: ChartScope.team,
    availability: _needsTwoMatches,
    builder: (c) => CategoryChart<LabeledValue>(
      xTitle: 'N.º de partido en la condición',
      yTitle: 'Puntos acumulados',
      integerY: true,
      enableTrackball: true,
      series: [
        valueSeries(
          'Como local',
          TeamSeriesMapper.cumulativeSplitPoints(c.team!, home: true),
          SeriesKind.line,
          color: ChartPalette.home,
        ),
        valueSeries(
          'Como visitante',
          TeamSeriesMapper.cumulativeSplitPoints(c.team!, home: false),
          SeriesKind.line,
          color: ChartPalette.away,
        ),
      ],
    ),
  ),
  ChartDefinition(
    id: 'goals-range-by-round',
    category: ChartCategory.evolution,
    title: 'Rango de goles por jornada',
    description: 'Partido con menos y con más goles de cada jornada, con el promedio superpuesto.',
    chartType: 'Range Column + Line',
    availability: _needsRounds,
    builder: (c) => RangeChart(
      points: [for (final r in c.analytics.rounds) RangePoint(r.label, r.minGoals.toDouble(), r.maxGoals.toDouble())],
      kind: RangeKind.rangeColumn,
      rangeName: 'Mínimo – máximo por partido',
      xTitle: c.analytics.roundUnit,
      yTitle: 'Goles por partido',
      overlay: [for (final r in c.analytics.rounds) LabeledValue(r.label, r.averageGoals)],
      overlayName: 'Promedio',
    ),
  ),
];
