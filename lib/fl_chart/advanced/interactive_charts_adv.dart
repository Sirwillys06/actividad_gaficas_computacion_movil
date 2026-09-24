import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/chart_data_models.dart';
import '../widgets/chart_card_wrapper.dart';

class _InteractiveLine extends StatefulWidget { final int type; const _InteractiveLine(this.type); @override State<_InteractiveLine> createState() => _InteractiveLineState(); }
class _InteractiveLineState extends State<_InteractiveLine> {
  int selected = -1; double zoom = 1;
  @override Widget build(BuildContext context) { final d = SportsApiMock.getMockTimeline(); final spots = d.points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList();
    return ChartCardWrapper(title: 'Avanzada interactiva ${widget.type}', chart: GestureDetector(onScaleUpdate: (v) => setState(() => zoom = (zoom * v.scale).clamp(.7, 2.5)), child: LineChart(LineChartData(minX: 0, maxX: spots.length / zoom, lineTouchData: LineTouchData(enabled: true, touchCallback: (event, response) { if (response?.lineBarSpots?.isNotEmpty == true) setState(() => selected = response!.lineBarSpots!.first.spotIndex); }), lineBarsData: [LineChartBarData(spots: spots, color: selected >= 0 ? Colors.orange : Colors.blue, barWidth: 3, dotData: FlDotData(show: true))])))); }
}
class _InteractiveBar extends StatefulWidget { final int type; const _InteractiveBar(this.type); @override State<_InteractiveBar> createState() => _InteractiveBarState(); }
class _InteractiveBarState extends State<_InteractiveBar> { int selected = -1; @override Widget build(BuildContext c) { final d = SportsApiMock.getMockStandings(); return ChartCardWrapper(title: 'Avanzada interactiva ${widget.type}', chart: BarChart(BarChartData(barGroups: d.points.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.value, color: selected == e.key ? Colors.orange : Colors.blue, width: 18)])).toList(), barTouchData: BarTouchData(enabled: true, touchCallback: (event, response) { if (response?.spot != null) setState(() => selected = response!.spot!.touchedBarGroupIndex); })))); } }
class _InteractivePie extends StatefulWidget { const _InteractivePie(); @override State<_InteractivePie> createState() => _InteractivePieState(); }
class _InteractivePieState extends State<_InteractivePie> { int selected = -1; @override Widget build(BuildContext c) { final d = SportsApiMock.getMockMatchStats(); return ChartCardWrapper(title: 'Pastel expansible y rotatorio', chart: PieChart(PieChartData(pieTouchData: PieTouchData(touchCallback: (event, response) { setState(() => selected = response?.touchedSection?.touchedSectionIndex ?? -1); }), sections: d.points.asMap().entries.map((e) => PieChartSectionData(value: e.value.value, title: e.value.label, radius: selected == e.key ? 88 : 65)).toList()))); } }
class _InteractiveScatter extends StatefulWidget { const _InteractiveScatter(); @override State<_InteractiveScatter> createState() => _InteractiveScatterState(); }
class _InteractiveScatterState extends State<_InteractiveScatter> { int selected = -1; @override Widget build(BuildContext c) { final d = SportsApiMock.getMockStandings(); return ChartCardWrapper(title: 'Dispersión con popover', chart: ScatterChart(ScatterChartData(scatterTouchData: ScatterTouchData(enabled: true, touchCallback: (event, response) { if (response?.touchedSpot != null) setState(() => selected = response!.touchedSpot!.spot.x.toInt()); }), scatterSpots: d.points.asMap().entries.map<ScatterSpot>((e) => ScatterSpot(e.value.value, e.value.secondaryValue ?? 0, dotPainter: FlDotCirclePainter(radius: 6, color: selected == e.key ? Colors.red : Colors.blue))).toList()))); } }
Widget _interactive(int n) => n <= 5 ? _InteractiveLine(n) : n == 10 ? const _InteractivePie() : n == 4 ? const _InteractiveScatter() : _InteractiveBar(n);
class AdvancedInteractiveChart1 extends StatelessWidget { const AdvancedInteractiveChart1({super.key}); @override Widget build(BuildContext c) => _interactive(1); }
class AdvancedInteractiveChart2 extends StatelessWidget { const AdvancedInteractiveChart2({super.key}); @override Widget build(BuildContext c) => _interactive(2); }
class AdvancedInteractiveChart3 extends StatelessWidget { const AdvancedInteractiveChart3({super.key}); @override Widget build(BuildContext c) => _interactive(3); }
class AdvancedInteractiveChart4 extends StatelessWidget { const AdvancedInteractiveChart4({super.key}); @override Widget build(BuildContext c) => _interactive(4); }
class AdvancedInteractiveChart5 extends StatelessWidget { const AdvancedInteractiveChart5({super.key}); @override Widget build(BuildContext c) => _interactive(5); }
class AdvancedInteractiveChart6 extends StatelessWidget { const AdvancedInteractiveChart6({super.key}); @override Widget build(BuildContext c) => _interactive(6); }
class AdvancedInteractiveChart7 extends StatelessWidget { const AdvancedInteractiveChart7({super.key}); @override Widget build(BuildContext c) => _interactive(7); }
class AdvancedInteractiveChart8 extends StatelessWidget { const AdvancedInteractiveChart8({super.key}); @override Widget build(BuildContext c) => _interactive(8); }
class AdvancedInteractiveChart9 extends StatelessWidget { const AdvancedInteractiveChart9({super.key}); @override Widget build(BuildContext c) => _interactive(9); }
class AdvancedInteractiveChart10 extends StatelessWidget { const AdvancedInteractiveChart10({super.key}); @override Widget build(BuildContext c) => _interactive(10); }
