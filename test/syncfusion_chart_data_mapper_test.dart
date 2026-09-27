import 'package:flutter_test/flutter_test.dart';

import 'package:actividad_graficos/syncfusion_flutter_charts/data/mappers/chart_data_mapper.dart';
import 'package:actividad_graficos/syncfusion_flutter_charts/data/models/event.dart';

void main() {
  final events = [
    const SportEvent(id: '1', homeTeam: 'A', awayTeam: 'B', homeScore: 2, awayScore: 1),
    const SportEvent(id: '2', homeTeam: 'B', awayTeam: 'A', homeScore: 0, awayScore: 0),
  ];

  test('maps goals by team without inventing values', () {
    final data = ChartDataMapper.goalsByTeam(events);
    expect(data.first.label, 'A');
    expect(data.first.value, 2);
    expect(data[1].label, 'B');
    expect(data[1].value, 1);
  });

  test('maps match outcomes correctly', () {
    final data = ChartDataMapper.outcomes(events);
    expect(data.map((item) => item.value).toList(), [1, 1]);
  });

  test('ignores events without scores', () {
    final data = ChartDataMapper.goalsByMatch([
      ...events,
      const SportEvent(id: '3', homeTeam: 'A', awayTeam: 'C'),
    ]);
    expect(data.length, 2);
  });
}
