import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:actividad_graficos/syncfusion_flutter_charts/data/mappers/season_analytics.dart';
import 'package:actividad_graficos/syncfusion_flutter_charts/data/models/ranking_filter.dart';
import 'package:actividad_graficos/syncfusion_flutter_charts/presentation/charts/catalog/chart_catalog.dart';
import 'package:actividad_graficos/syncfusion_flutter_charts/presentation/charts/catalog/chart_definition.dart';

import 'support/season_fixture.dart';

void main() {
  final analytics = SeasonAnalytics.fromEvents(buildSeasonFixture());
  final context = ChartContext(
    analytics: analytics,
    filter: RankingFilter.all,
    team: analytics.standings.first,
    compared: analytics.standings.take(3).toList(),
  );

  test('catalog exposes 80 unique charts across every category', () {
    expect(ChartCatalog.all, hasLength(80));
    expect(ChartCatalog.all.map((c) => c.id).toSet(), hasLength(80));
    for (final category in ChartCategory.values) {
      expect(ChartCatalog.byCategory(category), isNotEmpty, reason: category.label);
    }
  });

  test('every chart reports a reason instead of building with empty data', () {
    final empty = ChartContext(analytics: SeasonAnalytics.empty, filter: RankingFilter.all);
    for (final chart in ChartCatalog.all) {
      expect(chart.unavailableReason(empty), isNotNull, reason: chart.id);
    }
  });

  for (final chart in ChartCatalog.all) {
    testWidgets('renders #${ChartCatalog.numberOf(chart)} ${chart.id}', (tester) async {
      expect(chart.unavailableReason(context), isNull, reason: chart.id);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 800, height: chart.resolveHeight(context), child: chart.builder(context)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
