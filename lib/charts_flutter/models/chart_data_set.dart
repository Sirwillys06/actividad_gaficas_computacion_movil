import 'chart_data_point.dart';

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
}