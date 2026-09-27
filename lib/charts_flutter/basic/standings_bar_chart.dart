import 'package:flutter/material.dart';
import 'package:charts_flutter_updated/charts_flutter_updated.dart'
    as charts;

import '../models/chart_data_point.dart';
import '../models/chart_data_set.dart';

class StandingsBarChart extends StatelessWidget {
  final ChartDataSet data;

  const StandingsBarChart({
    super.key,
    required this.data,
  });

  static const List<Color> _barColors = [
    Colors.blue,
    Colors.red,
    Colors.amber,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.cyan,
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final chartHeight = width < 600 ? 240.0 : 280.0;

    final series = [
      charts.Series<ChartDataPoint, String>(
        id: 'Puntos',
        domainFn: (ChartDataPoint point, _) => point.label,
        measureFn: (ChartDataPoint point, _) => point.value,
        colorFn: (_, index) {
          final color = _barColors[
            (index ?? 0) % _barColors.length
          ];
          return charts.ColorUtil.fromDartColor(color);
        },
        data: data.points,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: chartHeight,
          width: double.infinity,
          child: charts.BarChart(
            series,
            animate: true,
            vertical: false,
            domainAxis: charts.OrdinalAxisSpec(
              renderSpec: charts.NoneRenderSpec(),
            ),
            primaryMeasureAxis: charts.NumericAxisSpec(
              renderSpec: charts.GridlineRendererSpec(
                labelStyle: charts.TextStyleSpec(
                  fontSize: 1,
                ),
              ),
              tickProviderSpec:
                  charts.BasicNumericTickProviderSpec(
                desiredTickCount: 6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 600
                    ? 3
                    : 2;
            final itemWidth =
                (constraints.maxWidth - ((columns - 1) * 8)) /
                    columns;

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data.points.map((point) {
                final badge = point.extraMetaData?['teamBadge']
                    ?.toString();

                return SizedBox(
                  width: itemWidth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade100,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: badge != null && badge.isNotEmpty
                              ? Image.network(
                                  badge,
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.shield,
                                      size: 19,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.shield,
                                  size: 19,
                                ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            point.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          point.value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
