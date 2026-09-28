import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/theme/chart_palette.dart';

/// Fábrica de ejes y comportamientos comunes, para que todos los gráficos
/// compartan estilo e interactividad sin duplicar configuración.
class ChartKit {
  static const TextStyle _axisLabel = TextStyle(fontSize: 11, color: Colors.white70);
  static const TextStyle _axisTitle = TextStyle(fontSize: 12, color: Colors.white);

  static AxisTitle title(String? text) => AxisTitle(text: text, textStyle: _axisTitle);

  /// Eje de categorías. Con [showAll] se fuerza a mostrar todas las etiquetas
  /// (nombres de equipos) y se recortan a [maxLabelWidth] píxeles.
  static CategoryAxis categoryAxis({
    String? title,
    bool showAll = true,
    bool inversed = false,
    double? labelRotation,
    double maxLabelWidth = 120,
    int? visibleCount,
  }) => CategoryAxis(
    title: ChartKit.title(title),
    interval: showAll ? 1 : null,
    isInversed: inversed,
    labelRotation: labelRotation?.toInt() ?? 0,
    maximumLabelWidth: maxLabelWidth,
    labelStyle: _axisLabel,
    labelIntersectAction: showAll ? AxisLabelIntersectAction.trim : AxisLabelIntersectAction.hide,
    majorGridLines: const MajorGridLines(width: 0),
    autoScrollingDelta: visibleCount,
    autoScrollingMode: AutoScrollingMode.start,
  );

  static NumericAxis numericAxis({
    String? title,
    double? minimum,
    double? maximum,
    double? interval,
    bool inversed = false,
    String? labelFormat,
    List<PlotBand> plotBands = const [],
    bool integer = false,
  }) => NumericAxis(
    title: ChartKit.title(title),
    minimum: minimum,
    maximum: maximum,
    interval: interval,
    isInversed: inversed,
    labelFormat: labelFormat,
    decimalPlaces: integer ? 0 : 2,
    // En magnitudes enteras (goles, partidos…) no se muestran marcas fraccionarias.
    axisLabelFormatter: integer
        ? (details) => ChartAxisLabel(details.value % 1 == 0 ? details.text : '', details.textStyle)
        : null,
    labelStyle: _axisLabel,
    plotBands: plotBands,
    majorGridLines: const MajorGridLines(width: 0.6, color: ChartPalette.grid),
    axisLine: const AxisLine(width: 0.8),
  );

  /// Línea de referencia (media de la liga, 50 %, cero…).
  static PlotBand referenceLine(double value, String label, {Color color = ChartPalette.highlight}) => PlotBand(
    start: value,
    end: value,
    borderWidth: 1.5,
    borderColor: color,
    dashArray: const [6, 4],
    text: label,
    textStyle: TextStyle(color: color, fontSize: 11),
    horizontalTextAlignment: TextAnchor.end,
    verticalTextAlignment: TextAnchor.start,
    shouldRenderAboveSeries: true,
    textAngle: 0,
  );

  static TooltipBehavior tooltip({String? format, bool shared = false}) =>
      TooltipBehavior(enable: true, format: format, shared: shared, canShowMarker: true, header: '');

  static ZoomPanBehavior zoomPan({ZoomMode mode = ZoomMode.x}) => ZoomPanBehavior(
    enablePinching: true,
    enablePanning: true,
    enableDoubleTapZooming: true,
    enableMouseWheelZooming: true,
    enableSelectionZooming: false,
    zoomMode: mode,
  );

  static TrackballBehavior trackball() => TrackballBehavior(
    enable: true,
    activationMode: ActivationMode.singleTap,
    tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
    lineType: TrackballLineType.vertical,
    markerSettings: const TrackballMarkerSettings(markerVisibility: TrackballVisibilityMode.visible),
  );

  static CrosshairBehavior crosshair() =>
      CrosshairBehavior(enable: true, activationMode: ActivationMode.longPress, lineType: CrosshairLineType.both);

  static SelectionBehavior selection() =>
      SelectionBehavior(enable: true, unselectedOpacity: 0.45, toggleSelection: true);

  static Legend legend({bool visible = true}) => Legend(
    isVisible: visible,
    position: LegendPosition.bottom,
    overflowMode: LegendItemOverflowMode.wrap,
    toggleSeriesVisibility: true,
    textStyle: const TextStyle(fontSize: 11),
  );
}
