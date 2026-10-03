/// Estructuras neutras que reciben los widgets de Syncfusion. Los gráficos
/// nunca leen JSON ni modelos de la API directamente.
class LabeledValue {
  final String label;
  final double value;
  final String? detail;

  const LabeledValue(this.label, this.value, {this.detail});
}

class XYPoint {
  final double x;
  final double y;
  final String label;
  final double size;

  const XYPoint({required this.x, required this.y, required this.label, this.size = 1});
}

class RangePoint {
  final String label;
  final double low;
  final double high;

  const RangePoint(this.label, this.low, this.high);
}

class ValueGroup {
  final String label;
  final List<num> values;

  const ValueGroup(this.label, this.values);
}

class MeanDeviation {
  final String label;
  final double mean;
  final double deviation;

  const MeanDeviation(this.label, this.mean, this.deviation);
}

/// Serie con nombre para gráficos de evolución y comparación.
class NamedSeries {
  final String name;
  final List<LabeledValue> points;

  const NamedSeries(this.name, this.points);

  bool get isEmpty => points.isEmpty;
}
