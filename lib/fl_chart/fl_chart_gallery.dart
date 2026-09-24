import 'package:flutter/material.dart';
import 'basic/line_charts_basic.dart';
import 'basic/bar_charts_basic.dart';
import 'basic/pie_charts_basic.dart';
import 'basic/scatter_radar_basic.dart';
import 'advanced/interactive_charts_adv.dart';
import 'advanced/multi_series_adv.dart';
import 'advanced/dashboard_stream_adv.dart';

class FlChartGallery extends StatelessWidget {
  const FlChartGallery({super.key});
  List<Widget> get charts => [
    const BasicLineChart1(), const BasicLineChart2(), const BasicLineChart3(), const BasicLineChart4(), const BasicLineChart5(), const BasicLineChart6(), const BasicLineChart7(), const BasicLineChart8(), const BasicLineChart9(), const BasicLineChart10(),
    const BasicBarChart1(), const BasicBarChart2(), const BasicBarChart3(), const BasicBarChart4(), const BasicBarChart5(), const BasicBarChart6(), const BasicBarChart7(), const BasicBarChart8(), const BasicBarChart9(), const BasicBarChart10(), const BasicBarChart11(), const BasicBarChart12(), const BasicBarChart13(), const BasicBarChart14(), const BasicBarChart15(),
    const BasicPieChart1(), const BasicPieChart2(), const BasicPieChart3(), const BasicPieChart4(), const BasicPieChart5(), const BasicPieChart6(), const BasicPieChart7(), const BasicPieChart8(), const BasicPieChart9(), const BasicPieChart10(),
    const BasicScatterChart1(), const BasicScatterChart2(), const BasicScatterChart3(), const BasicScatterChart4(), const BasicRadarChart1(), const BasicRadarChart2(), const BasicRadarChart3(), const BasicRadarChart4(),
    const AdvancedInteractiveChart1(), const AdvancedInteractiveChart2(), const AdvancedInteractiveChart3(), const AdvancedInteractiveChart4(), const AdvancedInteractiveChart5(), const AdvancedInteractiveChart6(), const AdvancedInteractiveChart7(), const AdvancedInteractiveChart8(), const AdvancedInteractiveChart9(), const AdvancedInteractiveChart10(),
    const AdvancedMultiSeriesChart1(), const AdvancedMultiSeriesChart2(), const AdvancedMultiSeriesChart3(), const AdvancedMultiSeriesChart4(), const AdvancedMultiSeriesChart5(), const AdvancedMultiSeriesChart6(), const AdvancedMultiSeriesChart7(), const AdvancedMultiSeriesChart8(), const AdvancedMultiSeriesChart9(), const AdvancedMultiSeriesChart10(),
    const AdvancedDashboardChart1(), const AdvancedDashboardChart2(), const AdvancedDashboardChart3(), const AdvancedDashboardChart4(), const AdvancedDashboardChart5(), const AdvancedDashboardChart6(), const AdvancedDashboardChart7(), const AdvancedDashboardChart8(), const AdvancedDashboardChart9(), const AdvancedDashboardChart10(), const AdvancedDashboardChart11(), const AdvancedDashboardChart12(), const AdvancedDashboardChart13(), const AdvancedDashboardChart14(), const AdvancedDashboardChart15(), const AdvancedDashboardChart16(),
  ];
  @override Widget build(BuildContext context) => DefaultTabController(length: 2, child: Scaffold(appBar: AppBar(title: const Text('Galería fl_chart'), bottom: const TabBar(tabs: [Tab(text: 'Básicas'), Tab(text: 'Avanzadas')])), body: TabBarView(children: [GridView.builder(padding: const EdgeInsets.all(8), gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 420, mainAxisExtent: 360), itemCount: 43, itemBuilder: (_, i) => charts[i]), GridView.builder(padding: const EdgeInsets.all(8), gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 420, mainAxisExtent: 360), itemCount: 36, itemBuilder: (_, i) => charts[i + 43])])));
}
