import 'package:flutter/material.dart';

import 'category_chart_view.dart';
import 'chart_models.dart';
import 'pie_chart_view.dart';
import 'scatter_chart_view.dart';
import 'team_bar_chart.dart';
import 'time_chart_view.dart';

/// Elige la vista adecuada para cada tipo de gráfico del catálogo.
class ChartBody extends StatelessWidget {
  final ChartKind kind;
  final ChartData data;
  final ChartContext context;

  const ChartBody({
    super.key,
    required this.kind,
    required this.data,
    required this.context,
  });

  @override
  Widget build(BuildContext buildContext) {
    final data = this.data;
    switch (data) {
      case CategoryChartData():
        if (kind == ChartKind.horizontalBar || kind == ChartKind.divergingBar) {
          return TeamBarChart(
            data: data,
            context: context,
            diverging: kind == ChartKind.divergingBar,
          );
        }
        return CategoryChartView(data: data, context: context, kind: kind);
      case ScatterChartData():
        return ScatterChartView(data: data, context: context);
      case TimeChartData():
        return TimeChartView(
          data: data,
          context: context,
          area: kind == ChartKind.area,
        );
      case PieChartData():
        return PieChartView(
          data: data,
          context: context,
          donut: kind == ChartKind.donut,
        );
    }
  }
}
