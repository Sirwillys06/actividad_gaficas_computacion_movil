import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../data/models/match_result.dart';

class GoalsPerMatchChart extends StatelessWidget {
  const GoalsPerMatchChart({super.key, required this.data});
  final List<MatchResult> data;

  @override
  Widget build(BuildContext context) => SfCartesianChart(
    tooltipBehavior: TooltipBehavior(enable: true),
    zoomPanBehavior: ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      enableDoubleTapZooming: true,
    ),
    crosshairBehavior: CrosshairBehavior(enable: true),
    series: <CartesianSeries<MatchResult, String>>[
      LineSeries<MatchResult, String>(
        dataSource: data,
        xValueMapper: (item, _) => item.label,
        yValueMapper: (item, _) => item.value,
        name: 'Goles por partido',
        markerSettings: const MarkerSettings(isVisible: true),
      ),
    ],
    primaryXAxis: CategoryAxis(title: AxisTitle(text: 'Partido reciente')),
    primaryYAxis: NumericAxis(title: AxisTitle(text: 'Goles'), interval: 1),
  );
}
