import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:actividad_graficos/syncfusion_flutter_charts/core/theme/app_theme.dart';
import 'package:actividad_graficos/syncfusion_flutter_charts/data/repositories/sports_repository.dart';
import 'package:actividad_graficos/syncfusion_flutter_charts/data/services/sports_api_service.dart';
import 'package:actividad_graficos/syncfusion_flutter_charts/presentation/screens/dashboard_screen.dart';

import 'support/fake_api.dart';
import 'support/season_fixture.dart';

Future<void> _pumpDashboard(WidgetTester tester, FakeSportsApi api, {Size size = const Size(1400, 1000)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = SportsRepository(service: SportsApiService(client: api.client));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: DashboardScreen(repository: repository),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('loads real-shaped API data and shows the summary', (tester) async {
    final api = FakeSportsApi(events: buildSeasonFixture());
    await _pumpDashboard(tester, api);

    expect(find.text('Panel de análisis deportivo'), findsOneWidget);
    expect(find.text('Clasificación calculada'), findsOneWidget);
    expect(find.textContaining('English Premier League'), findsWidgets);
    // Temporada actual tomada de lookupleague.
    expect(find.text('2025-2026'), findsWidgets);
    // 1 petición por endpoint: sin llamadas duplicadas.
    final paths = api.requests.map((uri) => uri.pathSegments.last).toList();
    expect(paths.toSet().length, paths.length);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigating categories and filters never hits the API again', (tester) async {
    final api = FakeSportsApi(events: buildSeasonFixture());
    await _pumpDashboard(tester, api);
    final before = api.requests.length;

    await tester.tap(find.text('Goles (8)'));
    await tester.pumpAndSettle();
    expect(find.text('Goles a favor por equipo'), findsOneWidget);

    await tester.tap(find.text('Top 5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Análisis avanzado (8)'));
    await tester.pumpAndSettle();
    expect(find.text('Ataque vs defensa'), findsOneWidget);

    expect(api.requests.length, before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an error instead of a broken screen when the API fails', (tester) async {
    final api = FakeSportsApi(events: const [], failSeason: true);
    await _pumpDashboard(tester, api);
    expect(find.textContaining('HTTP 500'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('works on phone width with section chips', (tester) async {
    final api = FakeSportsApi(events: buildSeasonFixture());
    await _pumpDashboard(tester, api, size: const Size(400, 900));
    expect(find.byType(ChoiceChip), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
