/// Punto de datos genérico para alimentar cualquier librería gráfica.
class ChartDataPoint {
  final String label; // Categoría o etiqueta en eje X / Leyenda
  final double value; // Valor numérico principal (Eje Y)
  final double? secondaryValue; // Valor secundario opcional (Eje Y2, radios, etc)
  final String? group; // Nombre de la serie/grupo (ej. "Local", "Visitante")
  final DateTime? timestamp; // Para series temporales
  final Map<String, dynamic>? extraMetaData; // Info para tooltips personalizados

  const ChartDataPoint({
    required this.label,
    required this.value,
    this.secondaryValue,
    this.group,
    this.timestamp,
    this.extraMetaData,
  });
}

/// Contenedor de series de datos.
class ChartDataSet {
  final String title;
  final String xLabel;
  final String yLabel;
  final List<ChartDataPoint> points;

  const ChartDataSet({
    required this.title,
    required this.xLabel,
    required this.yLabel,
    required this.points,
  });

  /// Grupos distintos presentes en los puntos (útil para series/leyendas).
  List<String> get groups =>
      points.map((p) => p.group).whereType<String>().toSet().toList();
}
