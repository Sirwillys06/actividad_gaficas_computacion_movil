import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/theme/chart_palette.dart';
import '../../../data/models/match_result.dart';
import 'chart_kit.dart';

enum BreakdownKind { pie, doughnut, radialBar }

/// Gráfico circular (pie, doughnut o radial bar) para repartos y
/// porcentajes. Los colores pueden fijarse para mantener la semántica
/// victoria/empate/derrota o local/visitante.
class BreakdownChart extends StatelessWidget {
  const BreakdownChart({
    super.key,
    required this.data,
    this.kind = BreakdownKind.doughnut,
    this.colors,
    this.maximumValue,
    this.valueSuffix = '',
    this.centerText,
  });

  final List<MatchResult> data;
  final BreakdownKind kind;
  final List<Color>? colors;

  /// Solo para radial bar: valor que representa la vuelta completa.
  final double? maximumValue;
  final String valueSuffix;
  final String? centerText;

  @override
  Widget build(BuildContext context) {
    Color colorOf(MatchResult item, int index) =>
        colors != null && index < colors!.length ? colors![index] : ChartPalette.at(index);
    String labelOf(MatchResult item, int _) => '${_fmt(item.value)}$valueSuffix';
    const labelSettings = DataLabelSettings(
      isVisible: true,
      labelPosition: ChartDataLabelPosition.outside,
      textStyle: TextStyle(fontSize: 11),
    );
    final CircularSeries<MatchResult, String> series = switch (kind) {
      BreakdownKind.pie => PieSeries<MatchResult, String>(
        dataSource: data,
        xValueMapper: (item, _) => item.label,
        yValueMapper: (item, _) => item.value,
        pointColorMapper: colorOf,
        dataLabelMapper: labelOf,
        dataLabelSettings: labelSettings,
        explode: true,
        explodeIndex: 0,
        selectionBehavior: ChartKit.selection(),
      ),
      BreakdownKind.doughnut => DoughnutSeries<MatchResult, String>(
        dataSource: data,
        xValueMapper: (item, _) => item.label,
        yValueMapper: (item, _) => item.value,
        pointColorMapper: colorOf,
        dataLabelMapper: labelOf,
        dataLabelSettings: labelSettings,
        innerRadius: '58%',
        selectionBehavior: ChartKit.selection(),
      ),
      BreakdownKind.radialBar => RadialBarSeries<MatchResult, String>(
        dataSource: data,
        // En barras radiales las etiquetas se solapan: el valor va en la leyenda.
        xValueMapper: (item, _) => '${item.label}: ${_fmt(item.value)}$valueSuffix',
        yValueMapper: (item, _) => item.value,
        pointColorMapper: colorOf,
        maximumValue: maximumValue,
        cornerStyle: CornerStyle.bothCurve,
        gap: '6%',
        radius: '95%',
        innerRadius: '25%',
        trackOpacity: 0.15,
        useSeriesColor: true,
      ),
    };
    return SfCircularChart(
      legend: ChartKit.legend(),
      tooltipBehavior: TooltipBehavior(enable: true, format: 'point.x : point.y$valueSuffix'),
      annotations: centerText == null
          ? null
          : [
              CircularChartAnnotation(
                widget: Text(
                  centerText!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
      series: [series],
    );
  }

  static String _fmt(double value) =>
      value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);
}
