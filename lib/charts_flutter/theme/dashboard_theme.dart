import 'package:flutter/material.dart';

/// Identidad visual del dashboard.
///
/// Los colores semánticos se reutilizan en todas las ligas para que el mismo
/// concepto (victoria, gol en contra, local...) siempre tenga el mismo color.
class DashboardColors {
  DashboardColors._();

  // Marca
  static const Color pitch = Color(0xFF0B3D2E);
  static const Color pitchDark = Color(0xFF062A1F);
  static const Color accent = Color(0xFF22C55E);
  static const Color background = Color(0xFFF3F5F7);
  static const Color surface = Colors.white;
  static const Color ink = Color(0xFF0F172A);
  static const Color inkMuted = Color(0xFF64748B);
  static const Color inkFaint = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color grid = Color(0xFFE8ECF1);

  // Resultados
  static const Color win = Color(0xFF16A34A);
  static const Color draw = Color(0xFF94A3B8);
  static const Color loss = Color(0xFFDC2626);

  // Goles
  static const Color goalsFor = Color(0xFF2563EB);
  static const Color goalsAgainst = Color(0xFFF97316);

  // Condición
  static const Color home = Color(0xFF0EA5E9);
  static const Color away = Color(0xFF7C3AED);

  // Métricas principales
  static const Color points = Color(0xFF0F766E);
  static const Color matches = Color(0xFFDB2777);

  /// Paleta categórica para series múltiples (p. ej. carrera del top 5).
  static const List<Color> series = [
    Color(0xFF2563EB),
    Color(0xFFF97316),
    Color(0xFF16A34A),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFF0891B2),
  ];
}

class DashboardTheme {
  DashboardTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: DashboardColors.pitch,
      primary: DashboardColors.pitch,
      surface: DashboardColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: DashboardColors.background,
      cardTheme: const CardThemeData(
        color: DashboardColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: DashboardColors.border),
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 350),
      ),
    );
  }
}

/// Formato numérico común: enteros sin decimales, resto con 1-2 decimales.
String formatNumber(double value, {int decimals = 1}) {
  if (!value.isFinite) return '–';
  if ((value - value.roundToDouble()).abs() < 0.000001) {
    return value.round().toString();
  }
  return value
      .toStringAsFixed(decimals)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// Igual que [formatNumber] pero con signo explícito (+12, 0, -4).
String formatSigned(double value) {
  final text = formatNumber(value);
  return value > 0 ? '+$text' : text;
}

const _singularUnits = {
  'goles': 'gol',
  'partidos': 'partido',
  'victorias': 'victoria',
  'empates': 'empate',
  'derrotas': 'derrota',
};

/// "1 partido", "7 partidos", "-1 gol", "21 pts".
String formatWithUnit(double value, String unit, {bool signed = false}) {
  final number = signed ? formatSigned(value) : formatNumber(value);
  if (unit.isEmpty) return number;
  final singular = value.abs() == 1 ? _singularUnits[unit] : null;
  return '$number ${singular ?? unit}';
}

const _monthsShort = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

String formatMonth(DateTime date) =>
    '${_monthsShort[date.month - 1]} ${date.year.toString().substring(2)}';

String formatDay(DateTime date) =>
    '${date.day} ${_monthsShort[date.month - 1]}';

String formatFullDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';
