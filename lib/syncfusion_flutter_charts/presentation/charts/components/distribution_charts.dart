import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/theme/chart_palette.dart';
import '../../../data/models/chart_point.dart';
import 'chart_kit.dart';

/// Histograma de una variable discreta (goles por partido, puntos…), con la
/// curva normal ajustada opcionalmente.
class HistogramChart extends StatelessWidget {
  const HistogramChart({
    super.key,
    required this.values,
    required this.xTitle,
    this.yTitle = 'Frecuencia',
    this.binInterval = 1,
    this.showNormalCurve = true,
    this.color = ChartPalette.home,
  });

  final List<num> values;
  final String xTitle;
  final String yTitle;
  final double binInterval;
  final bool showNormalCurve;
  final Color color;

  @override
  Widget build(BuildContext context) => SfCartesianChart(
    plotAreaBorderWidth: 0,
    tooltipBehavior: ChartKit.tooltip(format: 'Intervalo point.x\nFrecuencia: point.y'),
    primaryXAxis: NumericAxis(
      title: ChartKit.title(xTitle),
      majorGridLines: const MajorGridLines(width: 0),
      labelStyle: const TextStyle(fontSize: 11, color: Colors.white70),
    ),
    primaryYAxis: ChartKit.numericAxis(title: yTitle, minimum: 0, integer: true),
    series: <CartesianSeries<num, double>>[
      HistogramSeries<num, double>(
        name: yTitle,
        dataSource: values,
        yValueMapper: (value, _) => value,
        binInterval: binInterval,
        color: color,
        borderColor: Colors.black26,
        borderWidth: 1,
        showNormalDistributionCurve: showNormalCurve && values.length > 2,
        curveColor: ChartPalette.highlight,
        curveWidth: 2,
        dataLabelSettings: const DataLabelSettings(isVisible: true, textStyle: TextStyle(fontSize: 10)),
      ),
    ],
  );
}

/// Diagrama de caja y bigotes: mediana, cuartiles, extremos, media y atípicos.
class BoxPlotChart extends StatelessWidget {
  const BoxPlotChart({
    super.key,
    required this.groups,
    required this.xTitle,
    required this.yTitle,
    this.color = ChartPalette.away,
  });

  final List<ValueGroup> groups;
  final String xTitle;
  final String yTitle;
  final Color color;

  @override
  Widget build(BuildContext context) => SfCartesianChart(
    plotAreaBorderWidth: 0,
    tooltipBehavior: ChartKit.tooltip(),
    zoomPanBehavior: ChartKit.zoomPan(),
    primaryXAxis: ChartKit.categoryAxis(
      title: xTitle,
      labelRotation: groups.length > 8 ? -45 : null,
      visibleCount: groups.length > 14 ? 14 : null,
    ),
    primaryYAxis: ChartKit.numericAxis(title: yTitle, minimum: 0, interval: 1),
    series: <CartesianSeries<ValueGroup, String>>[
      BoxAndWhiskerSeries<ValueGroup, String>(
        name: yTitle,
        dataSource: groups,
        xValueMapper: (group, _) => group.label,
        yValueMapper: (group, _) => group.values,
        boxPlotMode: BoxPlotMode.exclusive,
        showMean: true,
        color: color.withValues(alpha: 0.6),
        borderColor: color,
        borderWidth: 1.5,
        markerSettings: const MarkerSettings(isVisible: true, height: 5, width: 5),
      ),
    ],
  );
}
