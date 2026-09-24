import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chart_data_point.dart';
import '../models/chart_data_set.dart';

class SportsApiService {
  static const String _baseUrl =
      'https://www.thesportsdb.com/api/v1/json/3';

  /// Obtiene la tabla de posiciones de una liga y temporada.
  Future<List<Map<String, dynamic>>> getStandings({
    required String leagueId,
    required String season,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/lookuptable.php?l=$leagueId&s=$season',
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al consultar TheSportsDB: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final table = data['table'];

    if (table == null || table is! List) {
      throw Exception(
        'La API no devolvió datos de clasificación.',
      );
    }

    return List<Map<String, dynamic>>.from(table);
  }

  /// Convierte la tabla de posiciones en nuestro modelo
  /// común ChartDataSet.
  Future<ChartDataSet> getStandingsChartData({
    required String leagueId,
    required String season,
  }) async {
    final standings = await getStandings(
      leagueId: leagueId,
      season: season,
    );

    final points = standings.map((team) {
      final teamName =
          team['strTeam']?.toString() ?? 'Sin nombre';

      final teamPoints =
          double.tryParse(
            team['intPoints']?.toString() ?? '0',
          ) ??
          0;

      return ChartDataPoint(
        label: teamName,
        value: teamPoints,
        extraMetaData: {
          'position': team['intRank'],
          'played': team['intPlayed'],
          'wins': team['intWin'],
          'losses': team['intLoss'],
          'draws': team['intDraw'],
          'goalsFor': team['intGoalsFor'],
          'goalsAgainst': team['intGoalsAgainst'],
          'goalDifference': team['intGoalDifference'],
        },
      );
    }).toList();

    return ChartDataSet(
      title: 'Puntos por equipo',
      xLabel: 'Equipos',
      yLabel: 'Puntos',
      points: points,
    );
  }

  /// Prueba de conexión con TheSportsDB.
  Future<void> testConnection() async {
    final standings = await getStandings(
      leagueId: '4328',
      season: '2023-2024',
    );

    print('======================================');
    print('CONEXIÓN CON THESPORTSDB EXITOSA');
    print('Equipos encontrados: ${standings.length}');
    print('======================================');

    for (final team in standings.take(5)) {
      print(
        '${team['intRank']}. '
        '${team['strTeam']} - '
        '${team['intPoints']} puntos',
      );
    }
  }
}