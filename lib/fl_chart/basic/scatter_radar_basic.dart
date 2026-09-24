import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/chart_data_models.dart';
import '../models/fl_chart_mapper.dart';
import '../widgets/chart_card_wrapper.dart';

class _BasicScatter extends StatelessWidget {
  final int variant;
  const _BasicScatter(this.variant);
  @override Widget build(BuildContext context) {
    final data = SportsApiMock.getMockStandings();
    return ChartCardWrapper(title: 'Dispersión básica ${variant - 35}', subtitle: 'Fundación vs capacidad', chart: ScatterChart(ScatterChartData(
      scatterSpots: FlChartMapper.toScatterSpots(data).map((p) => ScatterSpot(p.x, p.y, radius: variant == 37 ? p.radius + 4 : p.radius, color: data.points[p.x.toInt() % data.points.length].group == 'Top' ? Colors.orange : Colors.blue)).toList(),
      gridData: FlGridData(show: variant != 39), borderData: FlBorderData(show: variant != 39),
    )));
  }
}
class BasicScatterChart1 extends StatelessWidget { const BasicScatterChart1({super.key}); @override Widget build(BuildContext c) => const _BasicScatter(36); }
class BasicScatterChart2 extends StatelessWidget { const BasicScatterChart2({super.key}); @override Widget build(BuildContext c) => const _BasicScatter(37); }
class BasicScatterChart3 extends StatelessWidget { const BasicScatterChart3({super.key}); @override Widget build(BuildContext c) => const _BasicScatter(38); }
class BasicScatterChart4 extends StatelessWidget { const BasicScatterChart4({super.key}); @override Widget build(BuildContext c) => const _BasicScatter(39); }

class _BasicRadar extends StatelessWidget {
  final int variant;
  const _BasicRadar(this.variant);
  @override Widget build(BuildContext context) {
    final data = SportsApiMock.getMockMatchStats();
    return ChartCardWrapper(title: 'Radar básico ${variant - 39}', chart: RadarChart(RadarChartData(
      radarShape: RadarShape.polygon, tickCount: variant == 40 ? 3 : 5, titleTextStyle: const TextStyle(fontSize: 10),
      getTitle: (index, angle) => RadarChartTitle(text: index < data.points.length ? data.points[index].label : ''),
      dataSets: [RadarDataSet(fillColor: Colors.blue.withOpacity(variant == 42 ? .3 : .18), borderColor: Colors.blue, entryRadius: variant == 43 ? 4 : 0, dataEntries: data.points.map((p) => RadarEntry(value: p.value)).toList())],
    )));
  }
}
class BasicRadarChart1 extends StatelessWidget { const BasicRadarChart1({super.key}); @override Widget build(BuildContext c) => const _BasicRadar(40); }
class BasicRadarChart2 extends StatelessWidget { const BasicRadarChart2({super.key}); @override Widget build(BuildContext c) => const _BasicRadar(41); }
class BasicRadarChart3 extends StatelessWidget { const BasicRadarChart3({super.key}); @override Widget build(BuildContext c) => const _BasicRadar(42); }
class BasicRadarChart4 extends StatelessWidget { const BasicRadarChart4({super.key}); @override Widget build(BuildContext c) => const _BasicRadar(43); }
