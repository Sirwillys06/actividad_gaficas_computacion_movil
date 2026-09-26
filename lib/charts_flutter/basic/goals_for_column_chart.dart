import 'package:flutter/material.dart';
import 'package:charts_flutter_updated/charts_flutter_updated.dart'
    as charts;

import '../models/chart_data_point.dart';
import '../models/chart_data_set.dart';

class GoalsForColumnChart extends StatelessWidget {
  final ChartDataSet data;

  const GoalsForColumnChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final series = [
      charts.Series<ChartDataPoint, String>(
        id: 'Goles a favor',
        domainFn: (ChartDataPoint point, _) => point.label,
        measureFn: (ChartDataPoint point, _) => point.value,
        data: data.points,
      ),
    ];

    return SizedBox(
      height: 350,
      child: charts.BarChart(
        series,
        animate: true,
        vertical: true,
        domainAxis: charts.OrdinalAxisSpec(
          renderSpec: charts.NoneRenderSpec(),
        ),
        primaryMeasureAxis: charts.NumericAxisSpec(
          renderSpec: charts.GridlineRendererSpec(
            labelStyle: charts.TextStyleSpec(
              fontSize: 6,
            ),
          ),
          tickProviderSpec:
              charts.BasicNumericTickProviderSpec(
            desiredTickCount: 6,
          ),
        ),
      ),
    );
  }
}
