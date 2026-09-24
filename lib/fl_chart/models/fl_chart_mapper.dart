import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'chart_data_models.dart';

class FlChartMapper {
  static List<FlSpot> toFlSpots(ChartDataSet set, {bool secondary = false}) =>
      set.points.asMap().entries.map((e) => FlSpot(
        e.key.toDouble(), secondary ? (e.value.secondaryValue ?? 0) : e.value.value,
      )).toList();

  static List<BarChartGroupData> toBarGroups(ChartDataSet set, {Color color = const Color(0xff1976d2)}) =>
      set.points.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
        BarChartRodData(toY: e.value.value, width: 16, color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
      ])).toList();

  static List<PieChartSectionData> toPieSections(ChartDataSet set, {double radius = 70}) =>
      set.points.map((p) => PieChartSectionData(value: p.value, title: p.label, radius: radius)).toList();

  static List<ScatterSpot> toScatterSpots(ChartDataSet set) => set.points.asMap().entries.map((e) =>
      ScatterSpot(e.value.value, e.value.secondaryValue ?? e.key.toDouble(),
        radius: 4 + (e.value.value.abs() % 8))).toList();

  static RadarChartData toRadarData(ChartDataSet set, {Color color = const Color(0xff1976d2)}) => RadarChartData(
    getTitle: (index, angle) => RadarChartTitle(text: index < set.points.length ? set.points[index].label : ''),
    dataSets: [RadarDataSet(
      fillColor: color.withOpacity(.22), borderColor: color, entryRadius: 3,
      borderWidth: 2, dataEntries: set.points.map((p) => RadarEntry(value: p.value)).toList(),
    )],
  );
}
