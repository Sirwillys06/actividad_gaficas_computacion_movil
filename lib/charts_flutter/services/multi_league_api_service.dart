import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/multi_league_dashboard_models.dart';

class MultiLeagueApiService {
  static const String _baseUrl =
      'https://www.thesportsdb.com/api/v1/json/3';

  static const String season = '2026-2027';

  Future<List<LeagueDashboardData>> getAllLeagues() async {
    final results = await Future.wait(
      fiveMajorEuropeanLeagues.map(_loadLeague),
    );

    return results;
  }

  Future<LeagueDashboardData> _loadLeague(
    LeagueConfig league,
  ) async {
    final results = await Future.wait([
      _getStandings(league),
      _getSeasonEvents(league),
      _getLeagueBadge(league),
      _getTeamBadges(league),
    ]);

    final standings = (results[0] as List<TeamStandingData>)
        .map(
          (team) => team.copyWith(
            badge: team.badge ?? (results[3] as Map<String, String>)[team.team],
          ),
        )
        .toList();

    return LeagueDashboardData(
      league: league,
      standings: standings,
      events: results[1] as List<MatchEventData>,
      badge: results[2] as String?,
    );
  }

  Future<List<TeamStandingData>> _getStandings(
    LeagueConfig league,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/lookuptable.php',
    ).replace(
      queryParameters: {
        'l': league.id,
        's': season,
      },
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error en tabla ${league.name}: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final table = decoded['table'];

    if (table is! List) {
      return [];
    }

    return table
        .whereType<Map<String, dynamic>>()
        .map(
          (team) => TeamStandingData(
            team: team['strTeam']?.toString() ?? 'Sin nombre',
            rank: int.tryParse(
                  team['intRank']?.toString() ?? '',
                ) ??
                0,
            played: int.tryParse(
                  team['intPlayed']?.toString() ?? '',
                ) ??
                0,
            wins: int.tryParse(
                  team['intWin']?.toString() ?? '',
                ) ??
                0,
            draws: int.tryParse(
                  team['intDraw']?.toString() ?? '',
                ) ??
                0,
            losses: int.tryParse(
                  team['intLoss']?.toString() ?? '',
                ) ??
                0,
            goalsFor: int.tryParse(
                  team['intGoalsFor']?.toString() ?? '',
                ) ??
                0,
            goalsAgainst: int.tryParse(
                  team['intGoalsAgainst']?.toString() ?? '',
                ) ??
                0,
            goalDifference: int.tryParse(
                  team['intGoalDifference']?.toString() ?? '',
                ) ??
                0,
            points: int.tryParse(
                  team['intPoints']?.toString() ?? '',
                ) ??
                0,
            badge: _clean(team['strBadge'] ?? team['strTeamBadge']),
          ),
        )
        .toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
  }

  Future<List<MatchEventData>> _getSeasonEvents(
    LeagueConfig league,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/eventsseason.php',
    ).replace(
      queryParameters: {
        'id': league.id,
        's': season,
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        return [];
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final events = decoded['events'];

      if (events is! List) {
        return [];
      }

      return events
          .whereType<Map<String, dynamic>>()
          .map(
            (event) => MatchEventData(
              id: event['idEvent']?.toString() ?? '',
              date: _parseDate(event['dateEvent']),
              homeTeam: event['strHomeTeam']?.toString() ?? '',
              awayTeam: event['strAwayTeam']?.toString() ?? '',
              homeScore: _parseScore(event['intHomeScore']),
              awayScore: _parseScore(event['intAwayScore']),
            ),
          )
          .where(
            (event) =>
                event.homeTeam.isNotEmpty &&
                event.awayTeam.isNotEmpty,
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, String>> _getTeamBadges(
    LeagueConfig league,
  ) async {
    final leagueNames = <String, String>{
      '4328': 'English Premier League',
      '4335': 'Spanish La Liga',
      '4332': 'Italian Serie A',
      '4331': 'German Bundesliga',
      '4334': 'French Ligue 1',
    };

    final apiLeagueName = leagueNames[league.id];
    if (apiLeagueName == null) {
      return {};
    }

    final uri = Uri.parse(
      '$_baseUrl/search_all_teams.php',
    ).replace(
      queryParameters: {'l': apiLeagueName},
    );

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        return {};
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final teams = decoded['teams'];

      if (teams is! List) {
        return {};
      }

      final badges = <String, String>{};

      for (final item in teams.whereType<Map<String, dynamic>>()) {
        final name = _clean(item['strTeam']);
        final badge = _clean(item['strBadge'] ?? item['strTeamBadge']);

        if (name != null && badge != null) {
          badges[name] = badge;
        }
      }

      return badges;
    } catch (_) {
      return {};
    }
  }

  Future<String?> _getLeagueBadge(
    LeagueConfig league,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/lookupleague.php',
    ).replace(
      queryParameters: {'id': league.id},
    );

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final leagues = decoded['leagues'];

      if (leagues is! List || leagues.isEmpty) {
        return null;
      }

      return _clean(
        leagues.first['strBadge'] ??
            leagues.first['strLogo'],
      );
    } catch (_) {
      return null;
    }
  }

  static String? _clean(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  static int? _parseScore(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return int.tryParse(text);
  }

  static DateTime? _parseDate(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
