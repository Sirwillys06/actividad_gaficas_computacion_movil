import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/theme/chart_palette.dart';
import '../../../data/models/chart_point.dart';
import 'chart_kit.dart';
import 'chart_tooltip.dart';

/// Dispersión o burbujas sobre dos ejes numéricos, con línea de tendencia
/// opcional (regresión lineal calculada por Syncfusion sobre los datos reales).
class XYChart extends StatelessWidget {
  const XYChart({
    super.key,
    required this.points,
    required this.xTitle,
    required this.yTitle,
    this.bubble = false,
    this.trendline = false,
    this.showLabels = true,
    this.highlightLabel,
    this.xMinimum,
    this.yMinimum,
    this.xInterval,
    this.yInterval,
    this.plotBands = const [],
    this.xPlotBands = const [],
    this.tooltip,
  });

  final List<XYPoint> points;
  final String xTitle;
  final String yTitle;
  final bool bubble;
  final bool trendline;
  final bool showLabels;
  final String? highlightLabel;
  final double? xMinimum;
  final double? yMinimum;
  final double? xInterval;
  final double? yInterval;
  final List<PlotBand> plotBands;
  final List<PlotBand> xPlotBands;
  final String Function(XYPoint point)? tooltip;

  @override
  Widget build(BuildContext context) {
    final labels = DataLabelSettings(
      isVisible: showLabels,
      labelAlignment: ChartDataLabelAlignment.top,
      textStyle: const TextStyle(fontSize: 9),
      labelIntersectAction: LabelIntersectAction.hide,
    );
    Color colorOf(XYPoint point, int _) =>
        point.label == highlightLabel ? ChartPalette.highlight : ChartPalette.primary;
    final trend = trendline
        ? <Trendline>[
            Trendline(
              type: TrendlineType.linear,
              color: ChartPalette.highlight,
              width: 1.5,
              dashArray: const [6, 4],
              name: 'Tendencia lineal',
            ),
          ]
        : null;
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      legend: ChartKit.legend(visible: trendline),
      zoomPanBehavior: ChartKit.zoomPan(mode: ZoomMode.xy),
      crosshairBehavior: ChartKit.crosshair(),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
          final item = data as XYPoint;
          return ChartTooltipBox(
            tooltip?.call(item) ?? '${item.label}\n$xTitle: ${_fmt(item.x)}\n$yTitle: ${_fmt(item.y)}',
          );
        },
      ),
      primaryXAxis: NumericAxis(
        title: ChartKit.title(xTitle),
        minimum: xMinimum,
        interval: xInterval,
        plotBands: xPlotBands,
        majorGridLines: const MajorGridLines(width: 0.6, color: ChartPalette.grid),
        labelStyle: const TextStyle(fontSize: 11, color: Colors.white70),
        rangePadding: ChartRangePadding.additional,
      ),
      primaryYAxis: ChartKit.numericAxis(title: yTitle, minimum: yMinimum, interval: yInterval, plotBands: plotBands),
      series: <CartesianSeries<XYPoint, double>>[
        if (bubble)
          BubbleSeries<XYPoint, double>(
            name: yTitle,
            dataSource: points,
            xValueMapper: (p, _) => p.x,
            yValueMapper: (p, _) => p.y,
            sizeValueMapper: (p, _) => p.size,
            color: ChartPalette.primary,
            pointColorMapper: colorOf,
            opacity: 0.75,
            minimumRadius: 4,
            maximumRadius: 22,
            dataLabelMapper: (p, _) => _short(p.label),
            dataLabelSettings: labels,
            selectionBehavior: ChartKit.selection(),
            trendlines: trend,
          )
        else
          ScatterSeries<XYPoint, double>(
            name: yTitle,
            dataSource: points,
            xValueMapper: (p, _) => p.x,
            yValueMapper: (p, _) => p.y,
            color: ChartPalette.primary,
            pointColorMapper: colorOf,
            markerSettings: const MarkerSettings(height: 11, width: 11),
            dataLabelMapper: (p, _) => _short(p.label),
            dataLabelSettings: labels,
            selectionBehavior: ChartKit.selection(),
            trendlines: trend,
          ),
      ],
    );
  }

  static String _fmt(double value) =>
      value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(2);

  static String _short(String label) {
    final first = label.split('\n').first;
    return first.length > 14 ? '${first.substring(0, 13)}…' : first;
  }
}
