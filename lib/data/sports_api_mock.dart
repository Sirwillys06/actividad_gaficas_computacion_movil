import '../models/chart_data_point.dart';

/// Generador estático de datos cuando la API falla (429, timeout, vacío).
class SportsApiMock {
  SportsApiMock._();

  static ChartDataSet getMockStandings() {
    return const ChartDataSet(
      title: 'Posiciones Temporada (Mock)',
      xLabel: 'Equipos',
      yLabel: 'Puntos',
      points: [
        ChartDataPoint(label: 'ARS', value: 89, secondaryValue: 91, group: 'Top'),
        ChartDataPoint(label: 'MCI', value: 91, secondaryValue: 96, group: 'Top'),
        ChartDataPoint(label: 'LIV', value: 82, secondaryValue: 86, group: 'Top'),
        ChartDataPoint(label: 'AVL', value: 68, secondaryValue: 76, group: 'Mid'),
        ChartDataPoint(label: 'TOT', value: 66, secondaryValue: 74, group: 'Mid'),
        ChartDataPoint(label: 'CHE', value: 63, secondaryValue: 77, group: 'Mid'),
        ChartDataPoint(label: 'NEW', value: 60, secondaryValue: 85, group: 'Mid'),
        ChartDataPoint(label: 'MUN', value: 60, secondaryValue: 57, group: 'Low'),
      ],
    );
  }

  static ChartDataSet getMockMatchStats() {
    return const ChartDataSet(
      title: 'Estadísticas de Partido (Mock)',
      xLabel: 'Métrica',
      yLabel: 'Cantidad',
      points: [
        ChartDataPoint(label: 'Tiros a Puerta', value: 8, secondaryValue: 3, group: 'Match'),
        ChartDataPoint(label: 'Posesión %', value: 62, secondaryValue: 38, group: 'Match'),
        ChartDataPoint(label: 'Faltas', value: 11, secondaryValue: 14, group: 'Match'),
        ChartDataPoint(label: 'Córners', value: 7, secondaryValue: 2, group: 'Match'),
        ChartDataPoint(label: 'Tarjetas Amarillas', value: 1, secondaryValue: 4, group: 'Match'),
      ],
    );
  }

  /// Goles totales por jornada de una temporada, útil para líneas/áreas.
  static ChartDataSet getMockEventsSeason() {
    final base = DateTime(2023, 8, 12);
    final goalsByRound = [3, 5, 2, 4, 6, 1, 5, 4, 3, 7, 2, 6];
    final attendance = [60250, 54000, 41000, 73500, 61200, 39000, 58000, 62000, 45000, 51000, 39500, 60000];

    return ChartDataSet(
      title: 'Goles y Asistencia por Jornada (Mock)',
      xLabel: 'Jornada',
      yLabel: 'Goles',
      points: List.generate(goalsByRound.length, (i) {
        return ChartDataPoint(
          label: 'J${i + 1}',
          value: goalsByRound[i].toDouble(),
          secondaryValue: attendance[i].toDouble(),
          group: 'Liga',
          timestamp: base.add(Duration(days: i * 7)),
        );
      }),
    );
  }

  /// Datos técnicos de equipos, para dispersión / ranking.
  static ChartDataSet getMockTeams() {
    return const ChartDataSet(
      title: 'Equipos Premier League (Mock)',
      xLabel: 'Año de Fundación',
      yLabel: 'Capacidad Estadio',
      points: [
        ChartDataPoint(label: 'Arsenal', value: 1886, secondaryValue: 60704, group: 'England'),
        ChartDataPoint(label: 'Man City', value: 1880, secondaryValue: 53400, group: 'England'),
        ChartDataPoint(label: 'Liverpool', value: 1892, secondaryValue: 61276, group: 'England'),
        ChartDataPoint(label: 'Man United', value: 1878, secondaryValue: 74310, group: 'England'),
        ChartDataPoint(label: 'Chelsea', value: 1905, secondaryValue: 40341, group: 'England'),
        ChartDataPoint(label: 'Tottenham', value: 1882, secondaryValue: 62850, group: 'England'),
        ChartDataPoint(label: 'Newcastle', value: 1892, secondaryValue: 52305, group: 'England'),
        ChartDataPoint(label: 'Aston Villa', value: 1874, secondaryValue: 42682, group: 'England'),
      ],
    );
  }
}
