import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/chart_data_models.dart';
import '../models/fl_chart_mapper.dart';
import '../widgets/chart_card_wrapper.dart';

class _BasicLine extends StatelessWidget {
  final int variant;
  const _BasicLine(this.variant);
  @override Widget build(BuildContext context) {
    final data = SportsApiMock.getMockTimeline();
    final spots = FlChartMapper.toFlSpots(data);
    final secondary = FlChartMapper.toFlSpots(data, secondary: true);
    final bars = [LineChartBarData(spots: spots, isCurved: variant == 2, color: Colors.blue,
      barWidth: 3, dashArray: variant == 4 ? [5, 5] : null,
      dotData: FlDotData(show: variant == 6), belowBarData: BarAreaData(show: variant == 3, color: Colors.blue.withOpacity(.18)))];
    if (variant == 5) bars.add(LineChartBarData(spots: secondary, isCurved: true, color: Colors.orange, barWidth: 3));
    final average = spots.map((e) => e.y).fold(0.0, (a, b) => a + b) / spots.length;
    return ChartCardWrapper(title: 'Línea básica $variant', subtitle: data.title, chart: LineChart(LineChartData(
      minY: variant == 9 ? 0 : null, maxY: variant == 9 ? 100 : null,
      gridData: FlGridData(show: variant != 7), borderData: FlBorderData(show: variant != 7),
      lineBarsData: bars, extraLinesData: variant == 10 ? ExtraLinesData(horizontalLines: [HorizontalLine(y: average, color: Colors.red, dashArray: [6, 4])]) : null,
    )));
  }
}

class BasicLineChart1 extends StatelessWidget { const BasicLineChart1({super.key}); @override Widget build(BuildContext c) => const _BasicLine(1); }
class BasicLineChart2 extends StatelessWidget { const BasicLineChart2({super.key}); @override Widget build(BuildContext c) => const _BasicLine(2); }
class BasicLineChart3 extends StatelessWidget { const BasicLineChart3({super.key}); @override Widget build(BuildContext c) => const _BasicLine(3); }
class BasicLineChart4 extends StatelessWidget { const BasicLineChart4({super.key}); @override Widget build(BuildContext c) => const _BasicLine(4); }
class BasicLineChart5 extends StatelessWidget { const BasicLineChart5({super.key}); @override Widget build(BuildContext c) => const _BasicLine(5); }
class BasicLineChart6 extends StatelessWidget { const BasicLineChart6({super.key}); @override Widget build(BuildContext c) => const _BasicLine(6); }
class BasicLineChart7 extends StatelessWidget { const BasicLineChart7({super.key}); @override Widget build(BuildContext c) => const _BasicLine(7); }
class BasicLineChart8 extends StatelessWidget { const BasicLineChart8({super.key}); @override Widget build(BuildContext c) => const _BasicLine(8); }
class BasicLineChart9 extends StatelessWidget { const BasicLineChart9({super.key}); @override Widget build(BuildContext c) => const _BasicLine(9); }
class BasicLineChart10 extends StatelessWidget { const BasicLineChart10({super.key}); @override Widget build(BuildContext c) => const _BasicLine(10); }
