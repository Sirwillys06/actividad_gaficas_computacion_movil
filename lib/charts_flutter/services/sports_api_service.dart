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

  /// Consulta los escudos actuales de la liga y completa los equipos
  /// históricos que ya no aparecen en la plantilla de la temporada actual.
  Future<Map<String, String>> getTeamBadges({
    required String leagueName,
    required List<String> teamIds,
  }) async {
    final badges = <String, String>{};
    try {
      final uri = Uri.parse('$_baseUrl/search_all_teams.php')
          .replace(queryParameters: {'l': leagueName});
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final teams = data['teams'];
        if (teams is List) {
          for (final item in teams) {
            if (item is! Map) continue;
            final id = item['idTeam']?.toString();
            final badge = item['strBadge']?.toString();
            if (id != null && badge != null && badge.isNotEmpty) {
              badges[id] = badge;
            }
          }
        }
      }
    } catch (_) {
      // El gráfico sigue disponible aunque la consulta de imágenes falle.
    }

    // Los equipos descendidos pueden no estar en la liga actual.
    final missing = teamIds.toSet().where(
      (id) => id.isNotEmpty && !badges.containsKey(id),
    );
    for (final id in missing) {
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/lookupteam.php?id=$id'),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 5));
        if (response.statusCode != 200) continue;
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final teams = data['teams'];
        if (teams is! List || teams.isEmpty) continue;
        final badge = teams.first['strBadge']?.toString();
        if (badge != null && badge.isNotEmpty) badges[id] = badge;
      } catch (_) {
        // Un escudo faltante no impide visualizar los goles.
      }
    }
    return badges;
  }

  /// Convierte la tabla de posiciones en datos de goles a favor.
  Future<ChartDataSet> getGoalsForChartData({
    required String leagueId,
    required String season,
  }) async {
    final standings = await getStandings(
      leagueId: leagueId,
      season: season,
    );

    final badges = await getTeamBadges(
      leagueName: leagueId == '4328'
          ? 'English Premier League'
          : leagueId == '4335'
              ? 'Spanish La Liga'
              : leagueId,
      teamIds: standings
          .map((team) => team['idTeam']?.toString() ?? '')
          .toList(),
    );

    final points = standings.map((team) {
      final teamName =
          team['strTeam']?.toString() ?? 'Sin nombre';

      final goalsFor =
          double.tryParse(
            team['intGoalsFor']?.toString() ?? '0',
          ) ??
          0;

      return ChartDataPoint(
        label: teamName,
        value: goalsFor,
        extraMetaData: {
          'position': team['intRank'],
          'played': team['intPlayed'],
          'points': team['intPoints'],
          'goalsAgainst': team['intGoalsAgainst'],
          'goalDifference': team['intGoalDifference'],
          'teamBadge': badges[team['idTeam']?.toString()] ??
              team['strTeamBadge'],
        },
      );
    }).toList();

    return ChartDataSet(
      title: 'Goles a favor por equipo',
      xLabel: 'Equipos',
      yLabel: 'Goles',
      points: points,
    );
  }

  /// Obtiene el escudo de la liga.
  Future<String?> getLeagueBadgeUrl({
    required String leagueId,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/lookupleague.php?id=$leagueId',
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al consultar la liga: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final leagues = data['leagues'];

    if (leagues is! List || leagues.isEmpty) {
      return null;
    }

    final badge = leagues.first['strBadge']?.toString();

    return badge == null || badge.isEmpty ? null : badge;
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