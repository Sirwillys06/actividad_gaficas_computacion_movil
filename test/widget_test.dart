import 'package:flutter_test/flutter_test.dart';

import 'package:actividad_graficos/main.dart';

void main() {
  testWidgets('Sports analytics app starts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const SportsChartsApp());

    expect(find.text('Sports Analytics'), findsOneWidget);
    expect(find.text('Cargando datos deportivos...'), findsOneWidget);
  });
}
