import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/theme/chart_palette.dart';
import '../../../data/models/chart_point.dart';
import 'chart_kit.dart';
import 'chart_tooltip.dart';

/// Cascada: cada barra suma o resta al acumulado y la última muestra el total.
class WaterfallChart extends StatelessWidget {
  const WaterfallChart({
    super.key,
    required this.steps,
    required this.xTitle,
    required this.yTitle,
    this.totalLabel = 'Total',
  });

  /// Variación de cada paso (el detalle se muestra en el tooltip).
  final List<LabeledValue> steps;
  final String xTitle;
  final String yTitle;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    final data = [for (final step in steps) _Step(step), _Step(LabeledValue(totalLabel, 0), isTotal: true)];
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      zoomPanBehavior: ChartKit.zoomPan(),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        builder: (dynamic item, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
          final entry = item as _Step;
          final step = entry.value;
          if (entry.isTotal) {
            final sum = steps.fold<double>(0, (acc, value) => acc + value.value);
            return ChartTooltipBox('$totalLabel: ${sum.round()}');
          }
          final sign = step.value > 0 ? '+' : '';
          return ChartTooltipBox('${step.detail ?? step.label}\nVariación: $sign${step.value.round()}');
        },
      ),
      primaryXAxis: ChartKit.categoryAxis(title: xTitle, showAll: false, visibleCount: data.length > 20 ? 20 : null),
      primaryYAxis: ChartKit.numericAxis(title: yTitle, integer: true),
      series: <CartesianSeries<_Step, String>>[
        WaterfallSeries<_Step, String>(
          name: yTitle,
          dataSource: data,
          xValueMapper: (step, _) => step.value.label,
          yValueMapper: (step, _) => step.isTotal ? null : step.value.value,
          totalSumPredicate: (step, _) => step.isTotal,
          color: ChartPalette.win,
          negativePointsColor: ChartPalette.loss,
          totalSumColor: ChartPalette.home,
          connectorLineSettings: const WaterfallConnectorLineSettings(width: 1, color: Colors.white38),
        ),
      ],
    );
  }
}

class _Step {
  const _Step(this.value, {this.isTotal = false});
  final LabeledValue value;
  final bool isTotal;
}
