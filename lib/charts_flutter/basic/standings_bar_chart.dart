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

  @override
  Widget build(BuildContext context) {
    final series = [
      charts.Series<ChartDataPoint, String>(
        id: 'Puntos',
        domainFn: (ChartDataPoint point, _) => point.label,
        measureFn: (ChartDataPoint point, _) => point.value,
        data: data.points,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 350,
          child: charts.BarChart(
            series,
            animate: true,
            vertical: false,

            // Ocultamos las etiquetas problemáticas
            // del eje de equipos.
            domainAxis: charts.OrdinalAxisSpec(
              renderSpec: charts.NoneRenderSpec(),
            ),

            // Ocultamos las etiquetas numéricas problemáticas.
            // Las líneas de referencia siguen siendo útiles.
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

        const SizedBox(height: 12),

        // Información de los equipos fuera del renderizador
        // de charts_flutter.
        Column(
          children: data.points.map((point) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      point.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${point.value.toInt()} puntos',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}