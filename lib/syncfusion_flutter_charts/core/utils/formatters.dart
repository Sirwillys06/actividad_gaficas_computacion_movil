/// Formateo homogéneo de valores numéricos para ejes, tooltips y tarjetas.
class Formatters {
  /// Enteros sin decimales; valores fraccionarios con [decimals] decimales.
  static String number(num value, {int decimals = 2}) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(decimals);
  }

  static String decimal(num value) => value.toStringAsFixed(2);

  static String percent(num value, {int decimals = 1}) => '${value.toStringAsFixed(decimals)} %';

  static String signed(num value, {int decimals = 2}) {
    final text = number(value, decimals: decimals);
    return value > 0 ? '+$text' : text;
  }

  static const List<String> weekdays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
}
