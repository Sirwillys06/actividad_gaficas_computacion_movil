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
    primaryXAxis: const CategoryAxis(labelRotation: -35),
    primaryYAxis: const NumericAxis(title: AxisTitle(text: 'Goles'), interval: 1),
  );
}
