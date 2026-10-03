import 'dart:math' as math;

import 'package:charts_flutter_updated/charts_flutter_updated.dart' as charts;
import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';
import '../widgets/team_badge.dart';
import 'chart_models.dart';

/// Escala numérica común a charts_flutter y a las etiquetas Flutter.
///
/// charts_flutter_updated 0.16 fija internamente un textScaleFactor de 16
/// (GraphicsFactory.getTextScaleFactorOf), por lo que cualquier texto dibujado
/// dentro del lienzo sale gigante. Por eso el lienzo solo dibuja marcas:
/// los ejes se ocultan (NoneRenderSpec), los márgenes son 0 y la extensión
/// del eje se fija con [viewport]. Así el área de dibujo coincide con el
/// widget y las etiquetas Flutter se alinean exactamente.
class AxisScale {
  final double min;
  final double max;
  final List<double> ticks;

  const AxisScale(this.min, this.max, this.ticks);

  double get range => max - min;

  /// Posición 0..1 de un valor dentro del eje.
  double fraction(double value) => range == 0 ? 0 : (value - min) / range;

  /// Escala con ticks enteros "bonitos".
  ///
  /// [includeZero] ancla el eje en 0 (barras). En dispersión se desactiva y
  /// se añade un margen para que los puntos no queden cortados en el borde.
  factory AxisScale.nice(
    Iterable<double> values, {
    bool includeZero = true,
    double pixelLength = 300,
  }) {
    final finite = values.where((v) => v.isFinite).toList();
    var lo = finite.isEmpty ? 0.0 : finite.reduce(math.min);
    var hi = finite.isEmpty ? 1.0 : finite.reduce(math.max);

    if (includeZero) {
      lo = math.min(lo, 0);
      hi = math.max(hi, 0);
    } else {
      final pad = math.max(1.0, (hi - lo) * 0.08);
      lo -= pad;
      hi += pad;
    }
    if (hi <= lo) hi = lo + 1;

    final ticks = IntegerAxisMath.ticks(lo, hi, pixelLength);
    return AxisScale(ticks.first, ticks.last, ticks);
  }

  charts.NumericAxisSpec hiddenAxisSpec() {
    return charts.NumericAxisSpec(
      viewport: charts.NumericExtents(min, max),
      tickProviderSpec: charts.StaticNumericTickProviderSpec(
        ticks.map((t) => charts.TickSpec<num>(t)).toList(),
      ),
      renderSpec: const charts.NoneRenderSpec<num>(),
      showAxisLine: false,
    );
  }
}

/// Ticks enteros con paso 1, 2, 5, 10... (se conserva la lógica original).
class IntegerAxisMath {
  IntegerAxisMath._();

  static List<double> ticks(double minValue, double maxValue, double width) {
    final min = minValue.isFinite ? minValue : 0.0;
    final max = maxValue.isFinite ? maxValue : 1.0;
    final safeMax = max <= min ? min + 1.0 : max;
    final range = safeMax - min;
    final targetCount = width < 220 ? 4 : (width < 340 ? 5 : 6);

    if (range <= 3 &&
        min.floorToDouble() == min &&
        safeMax.ceilToDouble() == safeMax) {
      final values = <double>[];
      for (var value = min; value <= safeMax; value += 1) {
        values.add(value);
      }
      if (values.length >= 2) return values;
    }

    final rawStep = range / (targetCount - 1);
    final power =
        math.pow(10, (math.log(rawStep) / math.ln10).floor()).toDouble();

    const multipliers = <double>[1, 2, 2.5, 5, 10];
    var step = multipliers.first * power;
    var bestDistance = double.infinity;
    for (final multiplier in multipliers) {
      final candidate = multiplier * power;
      final distance = (math.log(candidate / rawStep)).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        step = candidate;
      }
    }
    step = step < 1 ? 1 : step.roundToDouble();

    final startTick = (min / step).floor() * step;
    final endTick = (safeMax / step).ceil() * step;
    final ticks = <double>[];
    for (var value = startTick;
        value <= endTick + step * 0.001;
        value += step) {
      ticks.add(value);
    }
    if (ticks.length < 2) {
      ticks
        ..clear()
        ..add(min)
        ..add(safeMax);
    }
    return ticks;
  }
}

/// Escala temporal con fechas reales (DateTime).
class TimeScale {
  final DateTime start;
  final DateTime end;
  final List<DateTime> ticks;

  const TimeScale(this.start, this.end, this.ticks);

  factory TimeScale.fromDates(List<DateTime> dates, {double pixelLength = 300}) {
    if (dates.isEmpty) {
      final now = DateTime.now();
      return TimeScale(now, now.add(const Duration(days: 1)), [now]);
    }
    final first = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final last = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    final spanMs = last.difference(first).inMilliseconds;
    final pad = Duration(
      milliseconds: math.max(
        const Duration(days: 1).inMilliseconds,
        (spanMs * 0.04).round(),
      ),
    );
    final start = first.subtract(pad);
    final end = last.add(pad);

    final count = pixelLength < 260 ? 3 : (pixelLength < 420 ? 4 : 5);
    final total = end.difference(start).inMilliseconds;
    final ticks = <DateTime>[
      for (var i = 0; i < count; i++)
        DateTime.fromMillisecondsSinceEpoch(
          start.millisecondsSinceEpoch + (total * (i + 0.5) / count).round(),
        ),
    ];
    return TimeScale(start, end, ticks);
  }

  double fraction(DateTime date) {
    final total = end.difference(start).inMilliseconds;
    if (total == 0) return 0;
    return date.difference(start).inMilliseconds / total;
  }

  DateTime atFraction(double f) => DateTime.fromMillisecondsSinceEpoch(
        start.millisecondsSinceEpoch +
            (end.difference(start).inMilliseconds * f).round(),
      );

  charts.DateTimeAxisSpec hiddenAxisSpec() {
    return charts.DateTimeAxisSpec(
      viewport: charts.DateTimeExtents(start: start, end: end),
      renderSpec: const charts.NoneRenderSpec<DateTime>(),
      showAxisLine: false,
    );
  }
}

/// Márgenes 0: el área de dibujo de charts_flutter = tamaño del widget.
charts.LayoutConfig zeroMarginLayout() => charts.LayoutConfig(
      leftMarginSpec: charts.MarginSpec.fixedPixel(0),
      topMarginSpec: charts.MarginSpec.fixedPixel(0),
      rightMarginSpec: charts.MarginSpec.fixedPixel(0),
      bottomMarginSpec: charts.MarginSpec.fixedPixel(0),
    );

const charts.OrdinalAxisSpec hiddenOrdinalAxis = charts.OrdinalAxisSpec(
  renderSpec: charts.NoneRenderSpec<String>(),
  showAxisLine: false,
);

const _axisTextStyle = TextStyle(
  fontSize: 10,
  height: 1,
  color: DashboardColors.inkMuted,
  fontFeatures: [FontFeature.tabularFigures()],
);

/// Etiquetas numéricas pequeñas, fuera del lienzo de charts_flutter.
class NumericAxisLabels extends StatelessWidget {
  final AxisScale scale;
  final Axis axis;
  final double width;
  final String Function(double value) format;

  const NumericAxisLabels({
    super.key,
    required this.scale,
    this.axis = Axis.horizontal,
    this.width = 34,
    this.format = formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    if (axis == Axis.vertical) {
      return SizedBox(
        width: width,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final tick in scale.ticks)
                  Positioned(
                    left: 0,
                    right: 6,
                    top: height * (1 - scale.fraction(tick)) - 6,
                    height: 12,
                    child: Text(
                      format(tick),
                      textAlign: TextAlign.right,
                      style: _axisTextStyle,
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    return SizedBox(
      height: 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final tick in scale.ticks)
                Positioned(
                  left: w * scale.fraction(tick) - 20,
                  top: 4,
                  width: 40,
                  height: 12,
                  child: Text(
                    format(tick),
                    textAlign: TextAlign.center,
                    style: _axisTextStyle,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Etiquetas de fechas reales bajo una serie temporal.
class DateAxisLabels extends StatelessWidget {
  final TimeScale scale;

  const DateAxisLabels({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    final spanDays = scale.end.difference(scale.start).inDays;
    return SizedBox(
      height: 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final tick in scale.ticks)
                Positioned(
                  left: w * scale.fraction(tick) - 30,
                  top: 4,
                  width: 60,
                  height: 12,
                  child: Text(
                    spanDays > 200 ? formatMonth(tick) : formatDay(tick),
                    textAlign: TextAlign.center,
                    style: _axisTextStyle,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Eje de categorías bajo columnas: escudo + abreviatura por banda.
class CategoryAxisStrip extends StatelessWidget {
  final List<CategoryItem> items;
  final ChartContext context;
  final int? highlighted;

  const CategoryAxisStrip({
    super.key,
    required this.items,
    required this.context,
    this.highlighted,
  });

  static const double height = 34;

  @override
  Widget build(BuildContext buildContext) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (_, constraints) {
          final band = constraints.maxWidth / math.max(1, items.length);
          final showText = band >= 15;
          final hasBadges = items.any((i) => i.teamId != null);
          return Row(
            children: [
              for (var i = 0; i < items.length; i++)
                SizedBox(
                  width: band,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      if (hasBadges)
                        TeamBadge(
                          badgeUrl: context.badge(items[i].teamId),
                          name: items[i].label,
                          size: math.min(16, band - 2).clamp(8, 16).toDouble(),
                        ),
                      if (showText) ...[
                        const SizedBox(height: 2),
                        Text(
                          items[i].shortLabel,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          softWrap: false,
                          style: _axisTextStyle.copyWith(
                            fontSize: band < 22 ? 8 : 9,
                            fontWeight: highlighted == i
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: highlighted == i
                                ? DashboardColors.ink
                                : DashboardColors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Eje de categorías a la izquierda de barras horizontales: escudo + nombre.
class CategoryRowLabels extends StatelessWidget {
  final List<CategoryItem> items;
  final ChartContext context;
  final double width;
  final int? highlighted;

  const CategoryRowLabels({
    super.key,
    required this.items,
    required this.context,
    required this.width,
    this.highlighted,
  });

  @override
  Widget build(BuildContext buildContext) {
    return SizedBox(
      width: width,
      child: LayoutBuilder(
        builder: (_, constraints) {
          final rowHeight = constraints.maxHeight / math.max(1, items.length);
          return Column(
            children: [
              for (var i = 0; i < items.length; i++)
                SizedBox(
                  height: rowHeight,
                  child: TeamLabel(
                    name: items[i].label,
                    badgeUrl: context.badge(items[i].teamId),
                    showBadge: items[i].teamId != null,
                    highlighted: highlighted == i,
                    fontSize: rowHeight < 16 ? 9 : 10,
                    badgeSize: math.min(18, rowHeight - 2).clamp(8, 18).toDouble(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Líneas de cuadrícula alineadas con los ticks de [AxisScale].
class GridPainter extends CustomPainter {
  final List<double> fractions;
  final Axis axis;

  /// Fracción donde está el 0 (se dibuja más marcado), si aplica.
  final double? zeroFraction;

  const GridPainter({
    required this.fractions,
    this.axis = Axis.vertical,
    this.zeroFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = DashboardColors.grid
      ..strokeWidth = 1;
    final zero = Paint()
      ..color = DashboardColors.inkFaint
      ..strokeWidth = 1.2;

    void line(double f, Paint paint) {
      if (axis == Axis.vertical) {
        final y = size.height * (1 - f);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      } else {
        final x = size.width * f;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    }

    for (final f in fractions) {
      line(f, grid);
    }
    if (zeroFraction != null && zeroFraction! >= 0 && zeroFraction! <= 1) {
      line(zeroFraction!, zero);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter old) =>
      old.axis != axis ||
      old.zeroFraction != zeroFraction ||
      old.fractions.length != fractions.length ||
      !_sameList(old.fractions, fractions);

  static bool _sameList(List<double> a, List<double> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
