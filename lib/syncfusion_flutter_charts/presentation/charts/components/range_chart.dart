import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/theme/chart_palette.dart';
import '../../../data/models/chart_point.dart';
import 'chart_kit.dart';
import 'chart_tooltip.dart';

enum RangeKind { rangeColumn, rangeArea }

/// Rango mínimo–máximo por categoría (Range Column o Range Area) con
/// una línea opcional superpuesta (p. ej. la media o un equipo concreto).
class RangeChart extends StatelessWidget {
  const RangeChart({
    super.key,
    required this.points,
    required this.xTitle,
    required this.yTitle,
    this.kind = RangeKind.rangeColumn,
    this.rangeName = 'Rango',
    this.overlay,
    this.overlayName,
    this.inversed = false,
  });

  final List<RangePoint> points;
  final String xTitle;
  final String yTitle;
  final RangeKind kind;
  final String rangeName;
  final List<LabeledValue>? overlay;
  final String? overlayName;
  final bool inversed;

  @override
  Widget build(BuildContext context) {
    String x(RangePoint p, int _) => p.label;
    num low(RangePoint p, int _) => p.low;
    num high(RangePoint p, int _) => p.high;
    final CartesianSeries<RangePoint, String> range = switch (kind) {
      RangeKind.rangeColumn => RangeColumnSeries<RangePoint, String>(
        name: rangeName,
        dataSource: points,
        xValueMapper: x,
        lowValueMapper: low,
        highValueMapper: high,
        color: ChartPalette.home,
        borderRadius: BorderRadius.circular(4),
        dataLabelSettings: const DataLabelSettings(isVisible: true, textStyle: TextStyle(fontSize: 9)),
      ),
      RangeKind.rangeArea => RangeAreaSeries<RangePoint, String>(
        name: rangeName,
        dataSource: points,
        xValueMapper: x,
        lowValueMapper: low,
        highValueMapper: high,
        color: ChartPalette.home.withValues(alpha: 0.35),
        borderColor: ChartPalette.home,
        borderWidth: 1.5,
      ),
    };
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      legend: ChartKit.legend(visible: overlay != null),
      trackballBehavior: ChartKit.trackball(),
      zoomPanBehavior: ChartKit.zoomPan(),
      primaryXAxis: ChartKit.categoryAxis(title: xTitle, showAll: false),
      primaryYAxis: ChartKit.numericAxis(title: yTitle, inversed: inversed),
      series: <CartesianSeries<dynamic, String>>[
        range,
        if (overlay != null)
          LineSeries<LabeledValue, String>(
            name: overlayName ?? '',
            dataSource: overlay!,
            xValueMapper: (p, _) => p.label,
            yValueMapper: (p, _) => p.value,
            color: ChartPalette.highlight,
            width: 2.2,
            markerSettings: const MarkerSettings(isVisible: true, height: 5, width: 5),
          ),
      ],
    );
  }
}

/// Media ± desviación típica por categoría: Hilo para el intervalo y Scatter
/// para la media (la ErrorBarSeries de Syncfusion solo admite errores
/// globales, no por punto).
class MeanDeviationChart extends StatelessWidget {
  const MeanDeviationChart({super.key, required this.items, required this.xTitle, required this.yTitle});

  final List<MeanDeviation> items;
  final String xTitle;
  final String yTitle;

  @override
  Widget build(BuildContext context) => SfCartesianChart(
    plotAreaBorderWidth: 0,
    legend: ChartKit.legend(),
    tooltipBehavior: TooltipBehavior(
      enable: true,
      builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
        final item = data as MeanDeviation;
        return ChartTooltipBox(
          '${item.label}\nMedia: ${item.mean.toStringAsFixed(2)}\nDesv. típica: ${item.deviation.toStringAsFixed(2)}',
        );
      },
    ),
    zoomPanBehavior: ChartKit.zoomPan(),
    primaryXAxis: ChartKit.categoryAxis(title: xTitle, labelRotation: -45, visibleCount: items.length > 12 ? 12 : null),
    primaryYAxis: ChartKit.numericAxis(title: yTitle, minimum: 0),
    series: <CartesianSeries<MeanDeviation, String>>[
      HiloSeries<MeanDeviation, String>(
        name: 'Media ± desviación típica',
        dataSource: items,
        xValueMapper: (item, _) => item.label,
        lowValueMapper: (item, _) => (item.mean - item.deviation).clamp(0, double.infinity),
        highValueMapper: (item, _) => item.mean + item.deviation,
        color: ChartPalette.home,
        borderWidth: 3,
      ),
      ScatterSeries<MeanDeviation, String>(
        name: 'Media',
        dataSource: items,
        xValueMapper: (item, _) => item.label,
        yValueMapper: (item, _) => item.mean,
        color: ChartPalette.highlight,
        markerSettings: const MarkerSettings(height: 9, width: 9),
      ),
    ],
  );
}
