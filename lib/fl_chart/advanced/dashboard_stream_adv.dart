import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/chart_data_models.dart';
import '../widgets/chart_card_wrapper.dart';

class _DashboardChart extends StatefulWidget {
  final int type;
  const _DashboardChart(this.type);
  @override State<_DashboardChart> createState() => _DashboardChartState();
}

class _DashboardChartState extends State<_DashboardChart> {
  double filter = 0;
  bool alternate = false;
  String query = '';
  int page = 0;

  @override Widget build(BuildContext context) {
    final data = SportsApiMock.getMockStandings();
    final points = data.points.where((p) => p.value >= filter &&
      (query.isEmpty || p.label.toLowerCase().contains(query.toLowerCase()))).toList();
    final visible = points.skip(page * 5).take(5).toList();
    final chart = widget.type == 24
      ? ScatterChart(ScatterChartData(scatterSpots: points.map<ScatterSpot>((p) => ScatterSpot(
          p.value, p.secondaryValue ?? 0,
          dotPainter: FlDotCirclePainter(radius: 6, color: Colors.teal),
        )).toList()))
      : widget.type == 23 || widget.type == 28 || widget.type == 30
      ? PieChart(PieChartData(
          centerSpaceRadius: widget.type == 30 ? 35 : 0,
          sections: points.map((p) => PieChartSectionData(value: p.value, title: p.label, radius: 60)).toList(),
        ))
      : BarChart(BarChartData(
          barGroups: visible.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(toY: alternate ? e.value.secondaryValue ?? 0 : e.value.value, color: Colors.teal, width: 16),
          ])).toList(),
        ));

    final controls = <Widget>[
      if (widget.type == 24) Slider(value: filter.clamp(0, 100), max: 100, onChanged: (v) => setState(() => filter = v)),
      if (widget.type == 32) TextField(decoration: const InputDecoration(labelText: 'Buscar equipo'), onChanged: (v) => setState(() => query = v)),
      if (widget.type == 25 || widget.type == 26) SwitchListTile(title: const Text('Modo alternativo'), value: alternate, onChanged: (v) => setState(() => alternate = v)),
      if (widget.type == 27) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(onPressed: page > 0 ? () => setState(() => page--) : null, icon: const Icon(Icons.chevron_left)),
        Text('Página ${page + 1}'),
        IconButton(onPressed: () => setState(() => page++), icon: const Icon(Icons.chevron_right)),
      ]),
    ];
    return ChartCardWrapper(
      title: 'Dashboard avanzada ${widget.type - 20}',
      subtitle: 'Datos TheSportDB / fallback offline',
      chart: Column(children: [Expanded(child: chart), ...controls]),
    );
  }
}

Widget _dashboard(int n) => _DashboardChart(n);
class AdvancedDashboardChart1 extends StatelessWidget { const AdvancedDashboardChart1({super.key}); @override Widget build(BuildContext c) => _dashboard(21); }
class AdvancedDashboardChart2 extends StatelessWidget { const AdvancedDashboardChart2({super.key}); @override Widget build(BuildContext c) => _dashboard(22); }
class AdvancedDashboardChart3 extends StatelessWidget { const AdvancedDashboardChart3({super.key}); @override Widget build(BuildContext c) => _dashboard(23); }
class AdvancedDashboardChart4 extends StatelessWidget { const AdvancedDashboardChart4({super.key}); @override Widget build(BuildContext c) => _dashboard(24); }
class AdvancedDashboardChart5 extends StatelessWidget { const AdvancedDashboardChart5({super.key}); @override Widget build(BuildContext c) => _dashboard(25); }
class AdvancedDashboardChart6 extends StatelessWidget { const AdvancedDashboardChart6({super.key}); @override Widget build(BuildContext c) => _dashboard(26); }
class AdvancedDashboardChart7 extends StatelessWidget { const AdvancedDashboardChart7({super.key}); @override Widget build(BuildContext c) => _dashboard(27); }
class AdvancedDashboardChart8 extends StatelessWidget { const AdvancedDashboardChart8({super.key}); @override Widget build(BuildContext c) => _dashboard(28); }
class AdvancedDashboardChart9 extends StatelessWidget { const AdvancedDashboardChart9({super.key}); @override Widget build(BuildContext c) => _dashboard(29); }
class AdvancedDashboardChart10 extends StatelessWidget { const AdvancedDashboardChart10({super.key}); @override Widget build(BuildContext c) => _dashboard(30); }
class AdvancedDashboardChart11 extends StatelessWidget { const AdvancedDashboardChart11({super.key}); @override Widget build(BuildContext c) => _dashboard(31); }
class AdvancedDashboardChart12 extends StatelessWidget { const AdvancedDashboardChart12({super.key}); @override Widget build(BuildContext c) => _dashboard(32); }
class AdvancedDashboardChart13 extends StatelessWidget { const AdvancedDashboardChart13({super.key}); @override Widget build(BuildContext c) => _dashboard(33); }
class AdvancedDashboardChart14 extends StatelessWidget { const AdvancedDashboardChart14({super.key}); @override Widget build(BuildContext c) => _dashboard(34); }
class AdvancedDashboardChart15 extends StatelessWidget { const AdvancedDashboardChart15({super.key}); @override Widget build(BuildContext c) => _dashboard(35); }
class AdvancedDashboardChart16 extends StatelessWidget { const AdvancedDashboardChart16({super.key}); @override Widget build(BuildContext c) => _dashboard(36); }
