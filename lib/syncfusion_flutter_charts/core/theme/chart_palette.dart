import 'package:flutter/material.dart';

/// Colores semánticos de los gráficos. Victoria/empate/derrota y
/// local/visitante mantienen siempre el mismo color en toda la app.
class ChartPalette {
  static const Color primary = Color(0xFF35C9A5);
  static const Color win = Color(0xFF35C9A5);
  static const Color draw = Color(0xFFF2C14E);
  static const Color loss = Color(0xFFEF6F6C);
  static const Color home = Color(0xFF4EA8DE);
  static const Color away = Color(0xFFB388EB);
  static const Color goalsFor = Color(0xFF35C9A5);
  static const Color goalsAgainst = Color(0xFFEF6F6C);
  static const Color neutral = Color(0xFF8D99AE);
  static const Color highlight = Color(0xFFFFB86B);
  static const Color grid = Color(0x22FFFFFF);

  /// Paleta categórica para series de varios equipos.
  static const List<Color> series = [
    Color(0xFF35C9A5),
    Color(0xFF4EA8DE),
    Color(0xFFFFB86B),
    Color(0xFFB388EB),
    Color(0xFFEF6F6C),
    Color(0xFFF2C14E),
    Color(0xFF7BD389),
    Color(0xFFFF8FAB),
  ];

  static Color at(int index) => series[index % series.length];

  static Color signed(num value) => value >= 0 ? win : loss;
}
