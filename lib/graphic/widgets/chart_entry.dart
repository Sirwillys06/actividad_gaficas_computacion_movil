import 'package:flutter/widgets.dart';

/// Una entrada catalogable de la galería: metadatos + el gráfico en sí.
class ChartEntry {
  final String title;
  final String description;
  final String family; // p.ej. "Barras", "Líneas", "Dashboard"
  final WidgetBuilder builder;

  const ChartEntry({
    required this.title,
    required this.description,
    required this.family,
    required this.builder,
  });
}
