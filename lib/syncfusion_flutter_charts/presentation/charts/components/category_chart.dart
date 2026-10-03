import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/theme/chart_palette.dart';
import 'chart_kit.dart';
import 'chart_tooltip.dart';

/// Tipos de serie cartesiana con eje X de categorías soportados por la app.
enum SeriesKind {
  column,
  bar,
  stackedColumn,
  stackedBar,
  stackedColumn100,
  stackedBar100,
  line,
  spline,
  area,
  splineArea,
  stepLine,
  stepArea,
  fastLine,
  stackedArea;

  bool get isHorizontal => this == bar || this == stackedBar || this == stackedBar100;
  bool get hasMarkers => this == line || this == spline || this == stepLine;
}

/// Definición declarativa de una serie: qué datos, cómo se mapean y cómo se
/// dibujan. Evita repetir la configuración de Syncfusion en cada gráfico.
class SeriesSpec<T> {
  final String name;
  final List<T> data;
  final String Function(T item) x;
  final num? Function(T item) y;
  final SeriesKind kind;
  final Color? color;
  final Color? Function(T item)? pointColor;
  final String Function(T item)? label;
  final String Function(T item)? tooltip;
  final bool showLabels;
  final bool showMarkers;
  final double? width;

  const SeriesSpec({
    required this.name,
    required this.data,
    required this.x,
    required this.y,
    this.kind = SeriesKind.column,
    this.color,
    this.pointColor,
    this.label,
    this.tooltip,
    this.showLabels = false,
    this.showMarkers = true,
    this.width,
  });
}

/// Gráfico cartesiano genérico con eje X de categorías (equipos, jornadas,
/// partidos, marcadores…). Admite combinaciones de series (p. ej. columnas +
/// línea) y todas las interacciones habituales de Syncfusion.
class CategoryChart<T> extends StatelessWidget {
  const CategoryChart({
    super.key,
    required this.series,
    this.xTitle,
    this.yTitle,
    this.yMinimum,
    this.yMaximum,
    this.yInterval,
    this.yInversed = false,
    this.integerY = false,
    this.yLabelFormat,
    this.plotBands = const [],
    this.enableZoom = false,
    this.enableTrackball = false,
    this.enableSelection = true,
    this.showLegend,
    this.labelRotation,
    this.visibleCount,
    this.maxLabelWidth = 130,
  });

  final List<SeriesSpec<T>> series;
  final String? xTitle;
  final String? yTitle;
  final double? yMinimum;
  final double? yMaximum;
  final double? yInterval;
  final bool yInversed;
  final bool integerY;
  final String? yLabelFormat;
  final List<PlotBand> plotBands;
  final bool enableZoom;
  final bool enableTrackball;
  final bool enableSelection;
  final bool? showLegend;
  final double? labelRotation;

  /// Número de categorías visibles a la vez; el resto se recorre con pan.
  final int? visibleCount;
  final double maxLabelWidth;

  bool get _horizontal => series.any((spec) => spec.kind.isHorizontal);

  /// Barras y columnas con valores no negativos siempre parten de cero para no
  /// exagerar visualmente las diferencias.
  double? _barBaseline() {
    const bars = {SeriesKind.column, SeriesKind.bar, SeriesKind.stackedColumn, SeriesKind.stackedBar};
    if (!series.any((spec) => bars.contains(spec.kind))) return null;
    for (final spec in series) {
      for (final item in spec.data) {
        final value = spec.y(item);
        if (value != null && value < 0) return null;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final scrollable = visibleCount != null;
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      legend: ChartKit.legend(visible: showLegend ?? series.length > 1),
      tooltipBehavior: enableTrackball ? null : _tooltip(),
      trackballBehavior: enableTrackball ? ChartKit.trackball() : null,
      zoomPanBehavior: enableZoom || scrollable ? ChartKit.zoomPan() : null,
      primaryXAxis: ChartKit.categoryAxis(
        title: xTitle,
        // En barras horizontales el primer elemento (líder) queda arriba.
        inversed: _horizontal,
        labelRotation: labelRotation,
        maxLabelWidth: maxLabelWidth,
        visibleCount: visibleCount,
      ),
      primaryYAxis: ChartKit.numericAxis(
        title: yTitle,
        minimum: yMinimum ?? _barBaseline(),
        maximum: yMaximum,
        interval: yInterval,
        inversed: yInversed,
        integer: integerY,
        labelFormat: yLabelFormat,
        plotBands: plotBands,
      ),
      series: [for (var i = 0; i < series.length; i++) _build(series[i], i)],
    );
  }

  TooltipBehavior _tooltip() {
    final hasCustom = series.any((spec) => spec.tooltip != null);
    if (!hasCustom) return ChartKit.tooltip(format: 'series.name\npoint.x : point.y');
    return TooltipBehavior(
      enable: true,
      builder: (dynamic data, dynamic point, dynamic chartSeries, int pointIndex, int seriesIndex) {
        final spec = series[seriesIndex];
        final item = data as T;
        final text =
            spec.tooltip?.call(item) ?? '${spec.name}\n${spec.x(item)} : ${spec.label?.call(item) ?? spec.y(item)}';
        return ChartTooltipBox(text);
      },
    );
  }

  CartesianSeries<T, String> _build(SeriesSpec<T> spec, int index) {
    final color = spec.color ?? ChartPalette.at(index);
    final labels = DataLabelSettings(
      isVisible: spec.showLabels,
      labelAlignment: ChartDataLabelAlignment.outer,
      textStyle: const TextStyle(fontSize: 10),
    );
    final markers = MarkerSettings(isVisible: spec.showMarkers && spec.kind.hasMarkers, height: 5, width: 5);
    final selection = enableSelection ? ChartKit.selection() : null;
    final labelMapper = spec.label == null ? null : (T item, int _) => spec.label!(item);
    final colorMapper = spec.pointColor == null ? null : (T item, int _) => spec.pointColor!(item);
    String xMap(T item, int _) => spec.x(item);
    num? yMap(T item, int _) => spec.y(item);

    switch (spec.kind) {
      case SeriesKind.column:
        return ColumnSeries<T, String>(
          name: spec.name,
          dataSource: spec.data,
          xValueMapper: xMap,
          yValueMapper: yMap,
          color: color,
          pointColorMapper: colorMapper,
          dataLabelMapper: labelMapper,
          dataLabelSettings: labels,
          selectionBehavior: selection,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          width: spec.width ?? 0.7,
          spacing: 0.1,
        );
      case SeriesKind.bar:
        return BarSeries<T, String>(
          name: spec.name,
          dataSource: spec.data,
          xValueMapper: xMap,
          yValueMapper: yMap,
          color: color,
          pointColorMapper: colorMapper,
          dataLabelMapper: labelMapper,
          dataLabelSettings: labels,
          selectionBehavior: selection,
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
          width: spec.width ?? 0.7,
          spacing: 0.1,
        );
      case SeriesKind.stackedColumn:
        return StackedColumnSeries<T, String>(
          name: spec.name,
          dataSource: spec.data,
          xValueMapper: xMap,
          yValueMapper: yMap,
          color: color,
          pointColorMapper: colorMapper,
          dataLabelMapper: labelMapper,
          dataLabelSettings: labels,
          selectionBehavior: selection,
          width: spec.width ?? 0.7,
        );
      case SeriesKind.stackedBar:
        return StackedBarSeries<T, String>(
          name: spec.name,
          dataSource: spec.data,
          xValueMapper: xMap,
          yValueMapper: yMap,
          color: color,
          pointColorMapper: colorMapper,
          dataLabelMapper: labelMapper,
          dataLabelSettings: labels,
          selectionBehavior: selection,
          width: spec.width ?? 0.7,
        );
      case SeriesKind.stackedColumn100:
        return StackedColumn100Series<T, String>(
          name: spec.name,
          dataSource: spec.data,
          xValueMapper: xMap,
          yValueMapper: yMap,
          color: color,
          pointColorMapper: colorMapper,
          dataLabelMapper: labelMapper,
          dataLabelSettings: labels,
          selectionBehavior: selection,
          width: spec.width ?? 0.7,
        );
      case SeriesKind.stackedBar100:
        return StackedBar100Series<T, String>(
          name: spec.name,
          dataSource: spec.data,
          xValueMapper: xMap,
          yValueMapper: yMap,
          color: color,
          pointColorMapper: colorMapper,
          dataLabelMapper: labelMapper,
          dataLabelSettings: labels,
          selectionBehavior: selection,
          width: spec.width ?? 0.7,
        );
      case SeriesKind.line:
        return LineSeries<T, String>(
          name: spec.name,
          dataSource: spec.data,
          xValueMapper: xMap,
          yValueMapper: yMap,
          color: color,
          dataLabelMapper: labelMapper,
          dataLabelSettings: labels,
          markerSettings: markers,
          width: spec.width ?? 2.2,
        );
      case SeriesKind.spline:
        return SplineSeries<T, String>(
          name: spec.name,
          dataSource: spec.data,
          xValueMapper: xMap,
          yValueMapper: yMap,
          color: color,
          dataLabelMapper: labelMapper,
          dataLabelSettings: labels,
          markerSettings: markers,
          width: spec.width ?? 2.2,
        );
      case SeriesKind.area:
        return AreaSeries<T, String>(
          name: spec.name,
          dataSource: spec.data,
          xValueMapper: xMap,
          yValueMapper: yMap,
          color: color.withValues(alpha: 0.45),
          borderColor: color,
          borderWidth: 2,
          dataLabelMapper: labelMapper,
          dataLabelSettings: labels,
        );
      case SeriesKind.splineArea:
        return SplineAreaSeries<T, String>(
          name: spec.name,
          dataSource: spec.data,
          xValueMapper: xMap,
          yValueMapper: yMap,
          color: color.withValues(alpha: 0.4),
          borderColor: color,
          borderWidth: 2,
          dataLabelMapper: labelMapper,
          dataLabelSettings: labels,
        );
      case SeriesKind.stepLine:
        return StepLineSeries<T, String>(
          name: spec.name,
          dataSource: spec.data,
          xValueMapper: xMap,
          yValueMapper: yMap,
          color: color,
          dataLabelMapper: labelMapper,
          dataLabelSettings: labels,
          markerSettings: markers,
          width: spec.width ?? 2,
        );
      case SeriesKind.stepArea:
        return StepAreaSeries<T, String>(
          name: spec.name,
          dataSource: spec.data,
          xValueMapper: xMap,
          yValueMapper: yMap,
          color: color.withValues(alpha: 0.35),
          borderColor: color,
          borderWidth: 2,
          dataLabelMapper: labelMapper,
          dataLabelSettings: labels,
        );
      case SeriesKind.fastLine:
        return FastLineSeries<T, String>(
          name: spec.name,
          dataSource: spec.data,
          xValueMapper: xMap,
          yValueMapper: yMap,
          color: color,
          width: spec.width ?? 1.6,
        );
      case SeriesKind.stackedArea:
        return StackedAreaSeries<T, String>(
          name: spec.name,
          dataSource: spec.data,
          xValueMapper: xMap,
          yValueMapper: yMap,
          color: color.withValues(alpha: 0.75),
          dataLabelMapper: labelMapper,
          dataLabelSettings: labels,
        );
    }
  }
}
