import 'dart:math' as math;

import 'package:charts_flutter_updated/charts_flutter_updated.dart' as charts;
import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';
import '../widgets/chart_tooltip.dart';
import 'chart_axes.dart';
import 'chart_models.dart';
import 'interactive_plot.dart';

/// Gráficos por categorías con charts_flutter_updated:
///
/// * [ChartKind.column]  → BarChart vertical, una serie.
/// * [ChartKind.grouped] → BarChart con BarGroupingType.grouped.
/// * [ChartKind.stacked] → BarChart horizontal con BarGroupingType.stacked.
/// * [ChartKind.combo]   → OrdinalComboChart: barras + LineRendererConfig.
/// * [ChartKind.line]    → LineChart con dominio numérico alineado a bandas.
class CategoryChartView extends StatefulWidget {
  final CategoryChartData data;
  final ChartContext context;
  final ChartKind kind;

  const CategoryChartView({
    super.key,
    required this.data,
    required this.context,
    required this.kind,
  });

  @override
  State<CategoryChartView> createState() => _CategoryChartViewState();
}

class _CategoryChartViewState extends State<CategoryChartView> {
  int? _hovered;
  Offset _pointer = Offset.zero;

  // El widget del gráfico se memoriza: el hover solo reconstruye la capa
  // de interacción, no el lienzo de charts_flutter.
  Widget? _chart;
  String? _chartKey;

  bool get _horizontal => widget.kind == ChartKind.stacked;
  int get _count => widget.data.categories.length;

  @override
  void didUpdateWidget(covariant CategoryChartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data || oldWidget.kind != widget.kind) {
      _chart = null;
      _hovered = null;
    }
  }

  List<double> _measureValues() {
    final series = widget.data.series;
    if (widget.kind == ChartKind.stacked) {
      return List.generate(
        _count,
        (i) => series.fold(0.0, (sum, s) => sum + s.values[i]),
      );
    }
    return series.expand((s) => s.values).toList();
  }

  List<charts.Series<int, String>> _ordinalSeries() {
    return [
      for (final s in widget.data.series)
        _withRenderer(
          charts.Series<int, String>(
            id: s.name,
            data: List.generate(_count, (i) => i),
            domainFn: (i, _) => '$i',
            measureFn: (i, _) => s.values[i],
            colorFn: (_, _) => charts.ColorUtil.fromDartColor(s.color),
          ),
          s.asLine,
        ),
    ];
  }

  /// En el combo, las series marcadas como línea se asignan al renderer
  /// 'line'; el resto usa el renderer por defecto (barras).
  static charts.Series<int, String> _withRenderer(
    charts.Series<int, String> series,
    bool asLine,
  ) {
    if (asLine) series.setAttribute(charts.rendererIdKey, 'line');
    return series;
  }

  Widget _buildChart(AxisScale scale) {
    final measureAxis = scale.hiddenAxisSpec();
    final ordinalBehaviors = <charts.ChartBehavior<String>>[
      charts.SelectNearest<String>(eventTrigger: charts.SelectionTrigger.tap),
      charts.DomainHighlighter<String>(),
    ];

    switch (widget.kind) {
      case ChartKind.combo:
        return charts.OrdinalComboChart(
          _ordinalSeries(),
          animate: false,
          layoutConfig: zeroMarginLayout(),
          domainAxis: hiddenOrdinalAxis,
          primaryMeasureAxis: measureAxis,
          behaviors: ordinalBehaviors,
          defaultRenderer: charts.BarRendererConfig<String>(
            cornerStrategy: const charts.ConstCornerStrategy(3),
            maxBarWidthPx: 48,
          ),
          customSeriesRenderers: [
            charts.LineRendererConfig<String>(
              customRendererId: 'line',
              includePoints: true,
              radiusPx: 4.5,
              strokeWidthPx: 2.5,
            ),
          ],
        );
      case ChartKind.line:
        return charts.LineChart(
          [
            for (final s in widget.data.series)
              charts.Series<int, num>(
                id: s.name,
                data: List.generate(_count, (i) => i),
                domainFn: (i, _) => i,
                measureFn: (i, _) => s.values[i],
                colorFn: (_, _) => charts.ColorUtil.fromDartColor(s.color),
              ),
          ],
          animate: false,
          layoutConfig: zeroMarginLayout(),
          // -0.5..n-0.5 centra cada punto en la banda de su equipo, igual que
          // una barra: el eje de escudos inferior queda alineado.
          domainAxis: charts.NumericAxisSpec(
            viewport: charts.NumericExtents(-0.5, _count - 0.5),
            renderSpec: const charts.NoneRenderSpec<num>(),
            showAxisLine: false,
          ),
          primaryMeasureAxis: measureAxis,
          defaultRenderer: charts.LineRendererConfig<num>(
            includePoints: true,
            radiusPx: 3,
            strokeWidthPx: 2.2,
          ),
          behaviors: [
            charts.SelectNearest<num>(eventTrigger: charts.SelectionTrigger.tap),
            charts.LinePointHighlighter<num>(),
          ],
        );
      case ChartKind.stacked:
      case ChartKind.grouped:
      case ChartKind.column:
      default:
        return charts.BarChart(
          _ordinalSeries(),
          animate: false,
          // En horizontal, BarChart ya coloca la primera categoría arriba
          // (comprobado en navegador), igual que las etiquetas Flutter.
          vertical: !_horizontal,
          layoutConfig: zeroMarginLayout(),
          defaultRenderer: charts.BarRendererConfig<String>(
            groupingType: widget.kind == ChartKind.stacked
                ? charts.BarGroupingType.stacked
                : charts.BarGroupingType.grouped,
            cornerStrategy: const charts.ConstCornerStrategy(2),
            maxBarWidthPx: widget.kind == ChartKind.column ? 34 : null,
          ),
          domainAxis: hiddenOrdinalAxis,
          primaryMeasureAxis: measureAxis,
          behaviors: ordinalBehaviors,
        );
    }
  }

  void _onPoint(Offset position, Size size) {
    final extent = _horizontal ? size.height : size.width;
    final coord = _horizontal ? position.dy : position.dx;
    final index = (coord / (extent / _count)).floor().clamp(0, _count - 1);
    setState(() {
      _hovered = index;
      _pointer = position;
    });
  }

  TooltipContent _tooltip(int index) {
    final item = widget.data.categories[index];
    String withUnit(double v) => formatWithUnit(v, widget.data.unit);
    final rows = [
      for (final s in widget.data.series)
        TooltipRow(
          s.name,
          withUnit(s.values[index]),
          color: s.color,
          emphasized: widget.data.series.length == 1,
        ),
      if (widget.kind == ChartKind.stacked)
        TooltipRow(
          'Total',
          withUnit(widget.data.series.fold(0.0, (sum, s) => sum + s.values[index])),
          emphasized: true,
        ),
    ];
    return TooltipContent(
      title: item.label,
      showBadge: item.teamId != null,
      badgeUrl: widget.context.badge(item.teamId),
      subtitle: '${widget.context.leagueName} · Temporada ${widget.context.season}',
      rows: rows,
      notes: item.details,
    );
  }

  /// Valores directos: sobre cada columna, o al final de cada barra apilada.
  List<Widget> _directValues(Size size, AxisScale scale) {
    final step = (_horizontal ? size.height : size.width) / _count;
    if (widget.kind == ChartKind.column && step >= 16) {
      final values = widget.data.series.first.values;
      return [
        for (var i = 0; i < _count; i++)
          Positioned(
            left: step * i,
            width: step,
            top: size.height * (1 - scale.fraction(values[i])) - 14,
            child: Text(
              formatNumber(values[i]),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: step < 24 ? 8.5 : 10,
                fontWeight: FontWeight.w800,
                color: DashboardColors.ink,
              ),
            ),
          ),
      ];
    }
    if (widget.kind == ChartKind.stacked && step >= 11) {
      final totals = _measureValues();
      return [
        for (var i = 0; i < _count; i++)
          Positioned(
            left: size.width * scale.fraction(totals[i]) + 4,
            top: step * i + step / 2 - 6,
            child: Text(
              formatNumber(totals[i]),
              style: const TextStyle(
                fontSize: 9.5,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: DashboardColors.ink,
              ),
            ),
          ),
      ];
    }
    return const [];
  }

  Widget _plot(AxisScale scale) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        final chartKey = '${scale.min}|${scale.max}|${widget.kind.name}';
        if (_chart == null || _chartKey != chartKey) {
          _chart = _buildChart(scale);
          _chartKey = chartKey;
        }
        return PlotPointerRegion(
          onPoint: (p) => _onPoint(p, size),
          onExit: () => setState(() => _hovered = null),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: GridPainter(
                    axis: _horizontal ? Axis.horizontal : Axis.vertical,
                    fractions: scale.ticks.map(scale.fraction).toList(),
                    zeroFraction: scale.fraction(0),
                  ),
                ),
              ),
              if (_hovered != null)
                BandHighlight(
                  index: _hovered!,
                  count: _count,
                  direction: _horizontal ? Axis.vertical : Axis.horizontal,
                ),
              Positioned.fill(child: _chart!),
              ..._directValues(size, scale),
              if (_hovered != null)
                TooltipOverlay(
                  anchor: _horizontal
                      ? Offset(_pointer.dx, size.height / _count * (_hovered! + 0.5))
                      : Offset(size.width / _count * (_hovered! + 0.5), _pointer.dy),
                  content: _tooltip(_hovered!),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final values = _measureValues();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_horizontal) {
          final labelWidth = constraints.maxWidth < 430 ? 108.0 : 146.0;
          final plotWidth = math.max(80.0, constraints.maxWidth - labelWidth - 36);
          final scale = AxisScale.nice(values, pixelLength: plotWidth);
          return Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    CategoryRowLabels(
                      items: widget.data.categories,
                      context: widget.context,
                      width: labelWidth,
                      highlighted: _hovered,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _plot(scale)),
                    const SizedBox(width: 28),
                  ],
                ),
              ),
              Row(
                children: [
                  SizedBox(width: labelWidth + 8),
                  Expanded(child: NumericAxisLabels(scale: scale)),
                  const SizedBox(width: 28),
                ],
              ),
            ],
          );
        }

        const yLabelWidth = 32.0;
        final scale = AxisScale.nice(
          values,
          pixelLength: math.max(120.0, constraints.maxHeight - CategoryAxisStrip.height),
        );
        return Column(
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: [
                  NumericAxisLabels(
                    scale: scale,
                    axis: Axis.vertical,
                    width: yLabelWidth,
                  ),
                  Expanded(child: _plot(scale)),
                ],
              ),
            ),
            Row(
              children: [
                const SizedBox(width: yLabelWidth),
                Expanded(
                  child: CategoryAxisStrip(
                    items: widget.data.categories,
                    context: widget.context,
                    highlighted: _hovered,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
