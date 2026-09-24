class ChartDataPoint {
  final String label;
  final double value;
  final double? secondaryValue;
  final String? group;
  final DateTime? timestamp;
  final Map<String, dynamic>? extraMetaData;

  const ChartDataPoint({
    required this.label,
    required this.value,
    this.secondaryValue,
    this.group,
    this.timestamp,
    this.extraMetaData,
  });
}