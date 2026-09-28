import 'advanced_charts.dart';
import 'chart_definition.dart';
import 'comparison_charts.dart';
import 'distribution_charts.dart';
import 'evolution_charts.dart';
import 'goals_charts.dart';
import 'home_away_charts.dart';
import 'matches_charts.dart';
import 'performance_charts.dart';
import 'results_charts.dart';
import 'standings_charts.dart';

/// Catálogo completo de visualizaciones. El número de cada gráfico es su
/// posición en esta lista (1-based).
class ChartCatalog {
  static final List<ChartDefinition> all = List.unmodifiable([
    ...standingsCharts,
    ...goalsCharts,
    ...resultsCharts,
    ...performanceCharts,
    ...matchesCharts,
    ...homeAwayCharts,
    ...evolutionCharts,
    ...distributionCharts,
    ...comparisonCharts,
    ...advancedCharts,
  ]);

  static int numberOf(ChartDefinition definition) => all.indexOf(definition) + 1;

  static List<ChartDefinition> byCategory(ChartCategory category) =>
      all.where((definition) => definition.category == category).toList();
}
