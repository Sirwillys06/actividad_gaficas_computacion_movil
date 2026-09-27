import 'package:actividad_graficos/charts_flutter/charts/chart_catalog.dart';
import 'package:actividad_graficos/charts_flutter/charts/chart_models.dart';
import 'package:actividad_graficos/charts_flutter/charts/chart_body.dart';
import 'package:actividad_graficos/charts_flutter/theme/dashboard_theme.dart';
import 'package:actividad_graficos/charts_flutter/widgets/chart_card.dart';
import 'package:actividad_graficos/main.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/league_fixture.dart';

void main() {
  final data = buildFixtureLeague();
  final chartContext = ChartContext(data: data, season: '2026-2027');

  for (final definition in ChartCatalog.all) {
    for (final width in [360.0, 620.0]) {
      testWidgets('renderiza ${definition.id} a ${width.toInt()}px', (tester) async {
        tester.view.physicalSize = Size(width, 560);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: DashboardTheme.light(),
            home: Scaffold(
              body: ChartCard(
                definition: definition,
                number: 1,
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ChartLegend(
                      data: definition.build(data),
                      kind: definition.kind,
                      context: chartContext,
                    ),
                    Expanded(
                      child: ChartBody(
                        kind: definition.kind,
                        data: definition.build(data),
                        context: chartContext,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text(definition.title), findsOneWidget);

        // Hover en el centro del gráfico: debe aparecer un tooltip sin errores.
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await gesture.moveTo(Offset(width / 2, 330));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('la app arranca sin descargar todas las ligas', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.text('THE SPORTS ANALYTICS'), findsOneWidget);
    // Accesos directos a las 5 ligas en la portada.
    for (final name in ['Premier League', 'La Liga', 'Serie A', 'Bundesliga', 'Ligue 1']) {
      expect(find.text(name), findsWidgets);
    }
    // Solo la liga abierta construye sus 4 tarjetas de la sección activa.
    expect(find.byType(LazyChartCard), findsWidgets);
    expect(find.byType(LazyChartCard).evaluate().length, lessThanOrEqualTo(4));
    // Sin red (HTTP 400 en tests) cada tarjeta muestra su propio error.
    await tester.pumpAndSettle();
    expect(find.text('No se pudieron cargar las estadísticas.'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
