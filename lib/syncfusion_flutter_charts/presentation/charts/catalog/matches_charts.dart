import '../../../core/theme/chart_palette.dart';
import '../../../data/mappers/chart_data_mapper.dart';
import '../../../data/models/chart_point.dart';
import '../components/category_chart.dart';
import '../components/chart_kit.dart';
import '../components/xy_chart.dart';
import '../goals_per_match_chart.dart';
import 'catalog_helpers.dart';
import 'chart_definition.dart';

String _goals(double value) => '${value.round()} goles';

final List<ChartDefinition> matchesCharts = [
  ChartDefinition(
    id: 'recent-matches-goals',
    category: ChartCategory.matches,
    title: 'Goles en los partidos más recientes',
    description:
        'Goles totales de los últimos 12 partidos con marcador (1 = el más reciente; gráfico original). Zoom, pan y crosshair.',
    chartType: 'Line',
    builder: (c) {
      final recent = c.analytics.scoredEvents.reversed.toList();
      return GoalsPerMatchChart(data: ChartDataMapper.goalsByMatch(recent));
    },
  ),
  ChartDefinition(
    id: 'margin-by-match',
    category: ChartCategory.matches,
    title: 'Diferencia de goles por partido',
    description:
        'Margen absoluto del marcador en cada partido, en orden cronológico. Desliza para recorrer la temporada.',
    chartType: 'Column con desplazamiento',
    builder: (c) {
      final data = ChartDataMapper.marginByMatch(c.analytics.scoredEvents);
      return CategoryChart<LabeledValue>(
        xTitle: 'Partido (orden cronológico)',
        yTitle: 'Margen (goles)',
        integerY: true,
        visibleCount: data.length > 30 ? 30 : null,
        showLegend: false,
        series: [valueSeries('Margen', data, SeriesKind.column, color: ChartPalette.away)],
      );
    },
  ),
  ChartDefinition(
    id: 'highest-scoring',
    category: ChartCategory.matches,
    title: 'Partidos con más goles',
    description: 'Los 10 partidos con más goles de la temporada.',
    chartType: 'Bar',
    height: (_) => 400,
    builder: (c) => CategoryChart<LabeledValue>(
      xTitle: 'Partido',
      yTitle: 'Goles',
      yMinimum: 0,
      maxLabelWidth: 180,
      showLegend: false,
      series: [
        valueSeries(
          'Goles',
          ChartDataMapper.highestScoringMatches(c.analytics.scoredEvents),
          SeriesKind.bar,
          color: ChartPalette.primary,
          labels: true,
          format: (v) => v.round().toString(),
        ),
      ],
    ),
  ),
  ChartDefinition(
    id: 'lowest-scoring',
    category: ChartCategory.matches,
    title: 'Partidos con menos goles',
    description: 'Los 10 partidos con menos goles de la temporada.',
    chartType: 'Bar',
    height: (_) => 400,
    builder: (c) => CategoryChart<LabeledValue>(
      xTitle: 'Partido',
      yTitle: 'Goles',
      yMinimum: 0,
      yMaximum: 4,
      yInterval: 1,
      maxLabelWidth: 180,
      showLegend: false,
      series: [
        valueSeries(
          'Goles',
          ChartDataMapper.lowestScoringMatches(c.analytics.scoredEvents),
          SeriesKind.bar,
          color: ChartPalette.neutral,
          labels: true,
          format: (v) => v.round().toString(),
        ),
      ],
    ),
  ),
  ChartDefinition(
    id: 'scoreline-frequency',
    category: ChartCategory.matches,
    title: 'Marcadores más frecuentes',
    description: 'Frecuencia de cada marcador final (goles local – goles visitante).',
    chartType: 'Column',
    builder: (c) {
      final data = ChartDataMapper.scorelineFrequency(c.analytics.scoredEvents);
      return CategoryChart<LabeledValue>(
        xTitle: 'Marcador (local-visitante)',
        yTitle: 'Partidos',
        integerY: true,
        visibleCount: data.length > 15 ? 15 : null,
        showLegend: false,
        series: [
          valueSeries(
            'Partidos',
            data,
            SeriesKind.column,
            color: ChartPalette.home,
            labels: true,
            format: (v) => v.round().toString(),
          ),
        ],
      );
    },
  ),
  ChartDefinition(
    id: 'wins-by-margin',
    category: ChartCategory.matches,
    title: 'Victorias por margen de goles',
    description: 'Partidos con ganador agrupados por la diferencia final (1, 2, 3 o 4+ goles).',
    chartType: 'Column',
    builder: (c) => CategoryChart<LabeledValue>(
      xTitle: 'Margen de victoria',
      yTitle: 'Partidos',
      integerY: true,
      showLegend: false,
      series: [
        valueSeries(
          'Partidos',
          ChartDataMapper.winsByMargin(c.analytics.scoredEvents),
          SeriesKind.column,
          color: ChartPalette.win,
          labels: true,
          format: (v) => v.round().toString(),
        ),
      ],
    ),
  ),
  ChartDefinition(
    id: 'goals-intensity',
    category: ChartCategory.matches,
    title: 'Intensidad goleadora de la temporada',
    description: 'Goles de todos los partidos en orden cronológico con la media de la liga. Trackball y zoom.',
    chartType: 'Fast Line',
    builder: (c) => CategoryChart<LabeledValue>(
      xTitle: 'Partido (orden cronológico)',
      yTitle: 'Goles',
      integerY: true,
      enableTrackball: true,
      enableZoom: true,
      showLegend: false,
      plotBands: [
        ChartKit.referenceLine(c.analytics.averageGoals, 'Media ${c.analytics.averageGoals.toStringAsFixed(2)}'),
      ],
      series: [
        valueSeries(
          'Goles',
          ChartDataMapper.goalsPerMatchDetailed(c.analytics.scoredEvents),
          SeriesKind.fastLine,
          color: ChartPalette.primary,
          format: _goals,
        ),
      ],
    ),
  ),
  ChartDefinition(
    id: 'score-matrix',
    category: ChartCategory.matches,
    title: 'Mapa de marcadores',
    description:
        'Goles del local (X) frente a goles del visitante (Y); el tamaño indica cuántos partidos acabaron así.',
    chartType: 'Bubble',
    builder: (c) => XYChart(
      points: ChartDataMapper.scoreMatrix(c.analytics.scoredEvents),
      xTitle: 'Goles del local',
      yTitle: 'Goles del visitante',
      bubble: true,
      showLabels: false,
      xMinimum: 0,
      yMinimum: 0,
      xInterval: 1,
      yInterval: 1,
      tooltip: (p) => p.label,
    ),
  ),
];
