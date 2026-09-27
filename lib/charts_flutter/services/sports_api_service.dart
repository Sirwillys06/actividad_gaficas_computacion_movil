import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chart_data_point.dart';
import '../models/chart_data_set.dart';

class SportsApiService {
  static const String _baseUrl =
      'https://www.thesportsdb.com/api/v1/json/3';

  final Map<String, Map<String, String>> _badgeCache = {};

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

    final badges = await getTeamBadges(
      leagueId: leagueId,
      season: season,
      leagueName: standings.isNotEmpty
          ? standings.first['strLeague']?.toString() ??
              'English Premier League'
          : 'English Premier League',
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
          'teamBadge': _badgeForTeam(
            team,
            badges,
          ),
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

  /// Busca los escudos reales de los equipos.
  ///
  /// Se combinan dos fuentes de TheSportsDB:
  /// 1. search_all_teams.php, que devuelve los equipos de la liga.
  /// 2. eventsseason.php, que incluye strHomeTeamBadge y
  ///    strAwayTeamBadge para los partidos de la temporada.
  ///
  /// También se normalizan los nombres para evitar que una diferencia
  /// de formato entre endpoints impida encontrar el escudo.
  Future<Map<String, String>> getTeamBadges({
    required String leagueId,
    required String season,
    required String leagueName,
  }) async {
    final cacheKey = '$leagueId|$season';

    if (_badgeCache.containsKey(cacheKey)) {
      return _badgeCache[cacheKey]!;
    }

    final badges = <String, String>{};

    // Fuente 1: lista de equipos de la liga.
    try {
      final normalizedLeague = leagueName.replaceAll(' ', '_');

      final uri = Uri.parse(
        '$_baseUrl/search_all_teams.php',
      ).replace(
        queryParameters: {
          'l': normalizedLeague,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final teams = data['teams'];

        if (teams is List) {
          for (final item in teams) {
            if (item is! Map<String, dynamic>) continue;

            _addBadge(
              badges,
              item['strTeam'],
              item['strBadge'] ?? item['strTeamBadge'],
            );
          }
        }
      }
    } catch (_) {
      // Continuamos con la fuente de eventos.
    }

    // Fuente 2: partidos de la temporada.
    // Es especialmente útil cuando la lista de equipos gratuita
    // está limitada o cuando los nombres no coinciden exactamente.
    try {
      final uri = Uri.parse(
        '$_baseUrl/eventsseason.php',
      ).replace(
        queryParameters: {
          'id': leagueId,
          's': season,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final events = data['events'];

        if (events is List) {
          for (final item in events) {
            if (item is! Map<String, dynamic>) continue;

            _addBadge(
              badges,
              item['strHomeTeam'],
              item['strHomeTeamBadge'],
            );

            _addBadge(
              badges,
              item['strAwayTeam'],
              item['strAwayTeamBadge'],
            );
          }
        }
      }
    } catch (_) {
      // Un escudo faltante no impide mostrar el gráfico.
    }

    _badgeCache[cacheKey] = badges;
    return badges;
  }

  void _addBadge(
    Map<String, String> badges,
    dynamic teamName,
    dynamic badge,
  ) {
    final name = teamName?.toString().trim();
    final url = badge?.toString().trim();

    if (name == null ||
        name.isEmpty ||
        url == null ||
        url.isEmpty) {
      return;
    }

    badges[_normalizeTeamName(name)] = url;
  }

  String _normalizeTeamName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(
          RegExp(r'\b(fc|football club)\b'),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _badgeForTeam(
    Map<String, dynamic> team,
    Map<String, String> badges,
  ) {
    final directBadge =
        (team['strBadge'] ?? team['strTeamBadge'])
            ?.toString()
            .trim();

    if (directBadge != null && directBadge.isNotEmpty) {
      return directBadge;
    }

    final teamName = team['strTeam']?.toString() ?? '';
    return badges[_normalizeTeamName(teamName)];
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
      leagueId: leagueId,
      season: season,
      leagueName: standings.isNotEmpty
          ? standings.first['strLeague']?.toString() ??
              'English Premier League'
          : 'English Premier League',
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
          'teamBadge': _badgeForTeam(
            team,
            badges,
          ),
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