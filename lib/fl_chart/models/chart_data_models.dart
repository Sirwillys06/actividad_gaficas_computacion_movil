import 'package:flutter/foundation.dart';

extension SafeDataParser on dynamic {
  double toSafeDouble({double defaultValue = 0.0}) {
    if (this == null) return defaultValue;
    if (this is double) return this as double;
    if (this is int) return (this as int).toDouble();
    final value = toString().replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(value) ?? defaultValue;
  }

  int toSafeInt({int defaultValue = 0}) {
    if (this == null) return defaultValue;
    if (this is int) return this as int;
    if (this is double) return (this as double).toInt();
    final value = toString().replaceAll(RegExp(r'[^0-9-]'), '');
    return int.tryParse(value) ?? defaultValue;
  }

  DateTime toSafeDate() => DateTime.tryParse(toString()) ?? DateTime.now();
}

@immutable
class ChartDataPoint {
  final String label;
  final double value;
  final double? secondaryValue;
  final String? group;
  final DateTime? timestamp;
  final Map<String, dynamic>? extraMetaData;

  const ChartDataPoint({
    required this.label,
    required this.value,
    this.secondaryValue,
    this.group,
    this.timestamp,
    this.extraMetaData,
  });
}

@immutable
class ChartDataSet {
  final String title;
  final String xLabel;
  final String yLabel;
  final List<ChartDataPoint> points;

  const ChartDataSet({
    required this.title,
    required this.xLabel,
    required this.yLabel,
    required this.points,
  });
}

class SportsApiMock {
  static ChartDataSet getMockStandings() => const ChartDataSet(
        title: 'Posiciones de temporada', xLabel: 'Equipos', yLabel: 'Puntos',
        points: [
          ChartDataPoint(label: 'ARS', value: 89, secondaryValue: 91, group: 'Top'),
          ChartDataPoint(label: 'MCI', value: 91, secondaryValue: 96, group: 'Top'),
          ChartDataPoint(label: 'LIV', value: 82, secondaryValue: 86, group: 'Top'),
          ChartDataPoint(label: 'AVL', value: 68, secondaryValue: 76, group: 'Mid'),
          ChartDataPoint(label: 'TOT', value: 66, secondaryValue: 74, group: 'Mid'),
          ChartDataPoint(label: 'CHE', value: 63, secondaryValue: 77, group: 'Mid'),
          ChartDataPoint(label: 'NEW', value: 60, secondaryValue: 85, group: 'Mid'),
          ChartDataPoint(label: 'MUN', value: 60, secondaryValue: 57, group: 'Low'),
        ],
      );

  static ChartDataSet getMockMatchStats() => const ChartDataSet(
        title: 'Estadísticas del partido', xLabel: 'Métrica', yLabel: 'Cantidad',
        points: [
          ChartDataPoint(label: 'Tiros', value: 8, secondaryValue: 3),
          ChartDataPoint(label: 'Posesión', value: 62, secondaryValue: 38),
          ChartDataPoint(label: 'Faltas', value: 11, secondaryValue: 14),
          ChartDataPoint(label: 'Corners', value: 7, secondaryValue: 2),
          ChartDataPoint(label: 'Tarjetas', value: 1, secondaryValue: 4),
        ],
      );

  static ChartDataSet getMockTimeline() => ChartDataSet(
        title: 'Goles por jornada', xLabel: 'Jornada', yLabel: 'Goles',
        points: List.generate(12, (i) => ChartDataPoint(
          label: '${i + 1}', value: (i * 3 + 2) % 7 + 1,
          secondaryValue: (i * 2 + 1) % 5 + 1,
          timestamp: DateTime(2024, 1, i + 1),
        )),
      );
}
