import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../data/models/match_result.dart';

class GoalsByTeamChart extends StatelessWidget {
  const GoalsByTeamChart({super.key, required this.data});
  final List<MatchResult> data;

  @override
  Widget build(BuildContext context) => SfCartesianChart(
    tooltipBehavior: TooltipBehavior(enable: true),
    selectionType: SelectionType.point,
    series: <CartesianSeries<MatchResult, String>>[
      ColumnSeries<MatchResult, String>(
        dataSource: data,
        xValueMapper: (item, _) => item.label,
        yValueMapper: (item, _) => item.value,
        name: 'Goles',
        dataLabelSettings: const DataLabelSettings(isVisible: true),
      ),
    ],
    // Todas las etiquetas visibles; con muchos equipos se recorre con pan.
    zoomPanBehavior: data.length > 12 ? ZoomPanBehavior(enablePanning: true) : null,
    primaryXAxis: CategoryAxis(
      labelRotation: -35,
      interval: 1,
      maximumLabelWidth: 90,
      autoScrollingDelta: data.length > 12 ? 12 : null,
      autoScrollingMode: AutoScrollingMode.start,
    ),
    primaryYAxis: NumericAxis(title: AxisTitle(text: 'Goles'), interval: 1),
  );
}
