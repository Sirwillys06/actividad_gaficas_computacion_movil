import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/sports_ids.dart';

/// Cliente HTTP de TheSportsDB. Devuelve listas crudas (JSON) y una lista
/// vacía ante 429 / timeout / error / respuesta vacía, para que la capa de
/// mapeo decida usar [SportsApiMock] como fallback.
class SportsApiService {
  SportsApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = 'https://www.thesportsdb.com/api/v1/json/3/';

  final http.Client _client;

  Future<List<Map<String, Object?>>> fetchStandings({
    String leagueId = SportsIds.premierLeague,
    String season = SportsIds.recentSeason,
  }) {
    return _getList('lookuptable.php?l=$leagueId&s=$season', 'table');
  }

  Future<List<Map<String, Object?>>> fetchEventsSeason({
    String leagueId = SportsIds.premierLeague,
    String season = SportsIds.recentSeason,
  }) {
    return _getList('eventsseason.php?id=$leagueId&s=$season', 'events');
  }

  Future<List<Map<String, Object?>>> fetchEventStats({
    required String eventId,
  }) {
    return _getList('lookupeventstats.php?id=$eventId', 'eventstats');
  }

  Future<List<Map<String, Object?>>> fetchTeams({
    String leagueName = SportsIds.premierLeagueName,
  }) {
    return _getList(
      'search_all_teams.php?l=${Uri.encodeQueryComponent(leagueName)}',
      'teams',
    );
  }

  Future<List<Map<String, Object?>>> _getList(String path, String key) async {
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return const [];
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return const [];

      final list = decoded[key];
      if (list is! List) return const [];

      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => Map<String, Object?>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  void dispose() => _client.close();
}
