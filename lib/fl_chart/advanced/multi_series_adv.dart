import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/chart_data_models.dart';
import '../widgets/chart_card_wrapper.dart';

class _MultiSeries extends StatelessWidget { final int type; const _MultiSeries(this.type); @override Widget build(BuildContext c) { final d = SportsApiMock.getMockTimeline(); final one = d.points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(); final two = d.points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.secondaryValue ?? 0)).toList(); final bars = d.points.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.value, color: Colors.blue, width: 12), BarChartRodData(toY: e.value.secondaryValue ?? 0, color: Colors.orange, width: 12)])).toList(); return ChartCardWrapper(title: 'Multi-serie avanzada ${type - 10}', chart: type == 12 || type == 17 ? BarChart(BarChartData(barGroups: bars)) : LineChart(LineChartData(lineBarsData: [LineChartBarData(spots: one, color: Colors.blue, barWidth: 3, isCurved: true), LineChartBarData(spots: two, color: Colors.orange, barWidth: 3, isCurved: true)]))); } }
class AdvancedMultiSeriesChart1 extends StatelessWidget { const AdvancedMultiSeriesChart1({super.key}); @override Widget build(BuildContext c) => const _MultiSeries(11); }
class AdvancedMultiSeriesChart2 extends StatelessWidget { const AdvancedMultiSeriesChart2({super.key}); @override Widget build(BuildContext c) => const _MultiSeries(12); }
class AdvancedMultiSeriesChart3 extends StatelessWidget { const AdvancedMultiSeriesChart3({super.key}); @override Widget build(BuildContext c) => const _MultiSeries(13); }
class AdvancedMultiSeriesChart4 extends StatelessWidget { const AdvancedMultiSeriesChart4({super.key}); @override Widget build(BuildContext c) => const _MultiSeries(14); }
class AdvancedMultiSeriesChart5 extends StatelessWidget { const AdvancedMultiSeriesChart5({super.key}); @override Widget build(BuildContext c) => const _MultiSeries(15); }
class AdvancedMultiSeriesChart6 extends StatelessWidget { const AdvancedMultiSeriesChart6({super.key}); @override Widget build(BuildContext c) => const _MultiSeries(16); }
class AdvancedMultiSeriesChart7 extends StatelessWidget { const AdvancedMultiSeriesChart7({super.key}); @override Widget build(BuildContext c) => const _MultiSeries(17); }
class AdvancedMultiSeriesChart8 extends StatelessWidget { const AdvancedMultiSeriesChart8({super.key}); @override Widget build(BuildContext c) => const _MultiSeries(18); }
class AdvancedMultiSeriesChart9 extends StatelessWidget { const AdvancedMultiSeriesChart9({super.key}); @override Widget build(BuildContext c) => const _MultiSeries(19); }
class AdvancedMultiSeriesChart10 extends StatelessWidget { const AdvancedMultiSeriesChart10({super.key}); @override Widget build(BuildContext c) => const _MultiSeries(20); }
