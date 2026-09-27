import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/multi_league_dashboard_models.dart';

/// Repositorio único de equipos y escudos.
///
/// La clave del cache siempre es idTeam. Cada liga se consulta una sola vez
/// por instancia del repositorio y los mismos objetos se reutilizan en los
/// 80 gráficos.
class TeamRepository {
  static const String _baseUrl =
      'https://www.thesportsdb.com/api/v1/json/3';

  static const Map<String, String> _apiLeagueNames = {
    '4328': 'English Premier League',
    '4335': 'Spanish La Liga',
    '4332': 'Italian Serie A',
    '4331': 'German Bundesliga',
    '4334': 'French Ligue 1',
  };

  final Map<String, Map<String, Team>> _cacheByLeagueId = {};
  final Map<String, Future<Map<String, Team>>> _inFlight = {};

  Future<Map<String, Team>> getTeams(LeagueConfig league) {
    final cached = _cacheByLeagueId[league.id];
    if (cached != null) return Future.value(cached);

    final pending = _inFlight[league.id];
    if (pending != null) return pending;

    final future = _fetchTeams(league);
    _inFlight[league.id] = future;

    return future.whenComplete(() {
      _inFlight.remove(league.id);
    });
  }

  Future<Map<String, Team>> _fetchTeams(LeagueConfig league) async {
    final apiLeagueName = _apiLeagueNames[league.id];
    if (apiLeagueName == null) return {};

    final uri = Uri.parse(
      '$_baseUrl/search_all_teams.php',
    ).replace(
      queryParameters: {'l': apiLeagueName},
    );

    try {
      final response = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        debugPrint('[TeamRepository] ' + league.name + ': HTTP ' + response.statusCode.toString());
        return {};
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return {};

      final rawTeams = decoded['teams'];
      if (rawTeams is! List) return {};

      final teams = <String, Team>{};

      for (final raw in rawTeams.whereType<Map<String, dynamic>>()) {
        final idTeam = _clean(raw['idTeam']);
        if (idTeam == null) {
          debugPrint('[TeamRepository] ' + league.name + ': equipo sin idTeam.');
          continue;
        }

        final name = _clean(raw['strTeam']) ?? 'Sin nombre';
        final badge = _clean(raw['strBadge'] ?? raw['strTeamBadge']);

        teams[idTeam] = Team(
          idTeam: idTeam,
          name: name,
          badge: badge,
          league: _clean(raw['strLeague']) ?? league.name,
          country: _clean(raw['strCountry']) ?? league.country,
        );

        if (badge == null) {
          debugPrint(
            '[TeamRepository] SIN ESCUDO | '
            'idTeam=\\$idTeam | equipo=\\$name | liga=\\${league.name}',
          );
        }
      }

      _cacheByLeagueId[league.id] = teams;
      debugPrint(
        '[TeamRepository] ' + league.name + ': ' + teams.length.toString() + ' equipos cacheados por idTeam.',
      );
      return teams;
    } catch (error) {
      debugPrint('[TeamRepository] Error cargando ' + league.name + ': ' + error.toString());
      return {};
    }
  }

  static String? _clean(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}
