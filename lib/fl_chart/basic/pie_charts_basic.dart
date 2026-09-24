import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/chart_data_models.dart';
import '../widgets/chart_card_wrapper.dart';

class _BasicPie extends StatelessWidget {
  final int variant;
  const _BasicPie(this.variant);
  @override Widget build(BuildContext context) {
    final data = SportsApiMock.getMockMatchStats();
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.red, Colors.purple];
    final total = data.points.fold(0.0, (a, b) => a + b.value);
    final sections = data.points.asMap().entries.map((e) => PieChartSectionData(
      value: e.value.value, color: colors[e.key % colors.length],
      title: variant == 30 ? '${(e.value.value / total * 100).round()}%' : e.value.label,
      radius: variant == 29 && e.key == 0 ? 88 : (variant == 34 ? 15 : 70),
      showTitle: variant != 31,
      badgeWidget: variant == 31 ? Icon(Icons.sports_soccer, color: colors[e.key % colors.length], size: 18) : null,
    )).toList();
    return ChartCardWrapper(title: 'Pastel básico ${variant - 25}', subtitle: data.title, chart: PieChart(PieChartData(
      sections: sections, sectionsSpace: variant == 32 ? 4 : 0,
      centerSpaceRadius: variant == 26 || variant == 33 ? 0 : (variant == 28 ? 40 : (variant == 34 ? 65 : 40)),
      startDegreeOffset: variant == 35 ? 20 : 0,
    )));
  }
}

class BasicPieChart1 extends StatelessWidget { const BasicPieChart1({super.key}); @override Widget build(BuildContext c) => const _BasicPie(26); }
class BasicPieChart2 extends StatelessWidget { const BasicPieChart2({super.key}); @override Widget build(BuildContext c) => const _BasicPie(27); }
class BasicPieChart3 extends StatelessWidget { const BasicPieChart3({super.key}); @override Widget build(BuildContext c) => const _BasicPie(28); }
class BasicPieChart4 extends StatelessWidget { const BasicPieChart4({super.key}); @override Widget build(BuildContext c) => const _BasicPie(29); }
class BasicPieChart5 extends StatelessWidget { const BasicPieChart5({super.key}); @override Widget build(BuildContext c) => const _BasicPie(30); }
class BasicPieChart6 extends StatelessWidget { const BasicPieChart6({super.key}); @override Widget build(BuildContext c) => const _BasicPie(31); }
class BasicPieChart7 extends StatelessWidget { const BasicPieChart7({super.key}); @override Widget build(BuildContext c) => const _BasicPie(32); }
class BasicPieChart8 extends StatelessWidget { const BasicPieChart8({super.key}); @override Widget build(BuildContext c) => const _BasicPie(33); }
class BasicPieChart9 extends StatelessWidget { const BasicPieChart9({super.key}); @override Widget build(BuildContext c) => const _BasicPie(34); }
class BasicPieChart10 extends StatelessWidget { const BasicPieChart10({super.key}); @override Widget build(BuildContext c) => const _BasicPie(35); }
