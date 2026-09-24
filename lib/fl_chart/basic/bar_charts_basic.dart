import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/chart_data_models.dart';
import '../models/fl_chart_mapper.dart';
import '../widgets/chart_card_wrapper.dart';

class _BasicBar extends StatelessWidget {
  final int variant;
  const _BasicBar(this.variant);
  @override Widget build(BuildContext context) {
    final data = SportsApiMock.getMockStandings();
    final groups = data.points.asMap().entries.map((e) {
      final p = e.value;
      final value = variant == 23 && p.value < 50 ? 50 - p.value : p.value;
      final rods = variant == 14 ? [p.value, p.secondaryValue ?? 0, (p.extraMetaData?['against'] as double?) ?? 0]
          .map((v) => BarChartRodData(toY: v, width: variant == 24 ? 3 : 12, color: v >= 50 ? Colors.green : Colors.red, borderRadius: variant == 25 ? BorderRadius.zero : BorderRadius.circular(4))).toList()
          : [BarChartRodData(toY: value, width: variant == 24 ? 3 : (8 + e.key.toDouble()), color: variant == 17 ? Colors.indigo : Colors.blue, borderRadius: variant == 25 ? BorderRadius.zero : BorderRadius.circular(4))];
      return BarChartGroupData(x: e.key, barRods: rods);
    }).toList();
    return ChartCardWrapper(title: 'Barras básicas $variant', subtitle: data.title, chart: BarChart(BarChartData(
      barGroups: groups, alignment: BarChartAlignment.spaceAround,
      gridData: FlGridData(show: variant != 20), borderData: FlBorderData(show: true),
      maxY: variant == 21 ? 100 : null,
      titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) =>
        v >= 0 && v < data.points.length ? SideTitleWidget(axisSide: m.axisSide, child: Text(data.points[v.toInt()].label, style: const TextStyle(fontSize: 9))) : const SizedBox.shrink()))),
    )));
  }
}

class BasicBarChart1 extends StatelessWidget { const BasicBarChart1({super.key}); @override Widget build(BuildContext c) => const _BasicBar(11); }
class BasicBarChart2 extends StatelessWidget { const BasicBarChart2({super.key}); @override Widget build(BuildContext c) => const _BasicBar(12); }
class BasicBarChart3 extends StatelessWidget { const BasicBarChart3({super.key}); @override Widget build(BuildContext c) => const _BasicBar(13); }
class BasicBarChart4 extends StatelessWidget { const BasicBarChart4({super.key}); @override Widget build(BuildContext c) => const _BasicBar(14); }
class BasicBarChart5 extends StatelessWidget { const BasicBarChart5({super.key}); @override Widget build(BuildContext c) => const _BasicBar(15); }
class BasicBarChart6 extends StatelessWidget { const BasicBarChart6({super.key}); @override Widget build(BuildContext c) => const _BasicBar(16); }
class BasicBarChart7 extends StatelessWidget { const BasicBarChart7({super.key}); @override Widget build(BuildContext c) => const _BasicBar(17); }
class BasicBarChart8 extends StatelessWidget { const BasicBarChart8({super.key}); @override Widget build(BuildContext c) => const _BasicBar(18); }
class BasicBarChart9 extends StatelessWidget { const BasicBarChart9({super.key}); @override Widget build(BuildContext c) => const _BasicBar(19); }
class BasicBarChart10 extends StatelessWidget { const BasicBarChart10({super.key}); @override Widget build(BuildContext c) => const _BasicBar(20); }
class BasicBarChart11 extends StatelessWidget { const BasicBarChart11({super.key}); @override Widget build(BuildContext c) => const _BasicBar(21); }
class BasicBarChart12 extends StatelessWidget { const BasicBarChart12({super.key}); @override Widget build(BuildContext c) => const _BasicBar(22); }
class BasicBarChart13 extends StatelessWidget { const BasicBarChart13({super.key}); @override Widget build(BuildContext c) => const _BasicBar(23); }
class BasicBarChart14 extends StatelessWidget { const BasicBarChart14({super.key}); @override Widget build(BuildContext c) => const _BasicBar(24); }
class BasicBarChart15 extends StatelessWidget { const BasicBarChart15({super.key}); @override Widget build(BuildContext c) => const _BasicBar(25); }
