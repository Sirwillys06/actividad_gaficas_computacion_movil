import 'dart:math' as math;

/// Funciones estadísticas puras usadas por los mappers.
class StatsUtils {
  static double mean(Iterable<num> values) {
    if (values.isEmpty) return 0;
    var sum = 0.0;
    var count = 0;
    for (final value in values) {
      sum += value;
      count++;
    }
    return sum / count;
  }

  static double standardDeviation(Iterable<num> values) {
    final list = values.toList();
    if (list.length < 2) return 0;
    final avg = mean(list);
    final variance = list.map((value) => math.pow(value - avg, 2)).reduce((a, b) => a + b) / list.length;
    return math.sqrt(variance);
  }

  static double ratio(num part, num total) => total == 0 ? 0 : part / total;

  static double percent(num part, num total) => ratio(part, total) * 100;
}
