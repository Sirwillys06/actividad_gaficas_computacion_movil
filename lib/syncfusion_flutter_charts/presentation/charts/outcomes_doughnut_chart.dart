import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../data/models/match_result.dart';

class OutcomesDoughnutChart extends StatelessWidget {
  const OutcomesDoughnutChart({super.key, required this.data});
  final List<MatchResult> data;

  @override
  Widget build(BuildContext context) => SfCircularChart(
    legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
    tooltipBehavior: TooltipBehavior(enable: true),
    series: <CircularSeries<MatchResult, String>>[
      DoughnutSeries<MatchResult, String>(
        dataSource: data,
        xValueMapper: (item, _) => item.label,
        yValueMapper: (item, _) => item.value,
        dataLabelSettings: const DataLabelSettings(isVisible: true, labelPosition: ChartDataLabelPosition.outside),
        enableTooltip: true,
      ),
    ],
  );
}
