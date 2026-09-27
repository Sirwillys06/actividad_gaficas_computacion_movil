import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/multi_league_dashboard_models.dart';
import 'team_repository.dart';

class MultiLeagueApiService {
  static const String _baseUrl =
      'https://www.thesportsdb.com/api/v1/json/3';

  static const String season = '2026-2027';

  final TeamRepository teamRepository;
  final Map<String, LeagueDashboardData> _leagueCache = {};
  final Map<String, Future<LeagueDashboardData>> _inFlight = {};

  MultiLeagueApiService({TeamRepository? teamRepository})
      : teamRepository = teamRepository ?? TeamRepository();

  Future<List<LeagueDashboardData>> getAllLeagues() async {
    final results = await Future.wait(
      fiveMajorEuropeanLeagues.map(_loadLeague),
    );
    return results;
  }

  Future<LeagueDashboardData> _loadLeague(LeagueConfig league) {
    final cached = _leagueCache[league.id];
    if (cached != null) return Future.value(cached);

    final pending = _inFlight[league.id];
    if (pending != null) return pending;

    final future = _fetchLeague(league);
    _inFlight[league.id] = future;

    return future.whenComplete(() {
      _inFlight.remove(league.id);
    });
  }

  Future<LeagueDashboardData> _fetchLeague(LeagueConfig league) async {
    // Solo 3 llamadas por liga: tabla + temporada + catálogo de equipos.
    // Los 40 básicos y 40 avanzados consumen estos mismos datos.
    final results = await Future.wait([
      _getStandings(league),
      _getSeasonEvents(league),
      teamRepository.getTeams(league),
    ]);

    final rawStandings = results[0] as List<TeamStandingData>;
    final teamsById = results[2] as Map<String, Team>;

    final standings = rawStandings.map((standing) {
      final team = teamsById[standing.idTeam];

      if (team == null) {
        debugPrint(
          '[MultiLeagueApiService] SIN MATCH DE EQUIPO | '
          'idTeam=${standing.idTeam} | equipo=${standing.team} | liga=${league.name}',
        );
        return standing;
      }

      if (team.idTeam != standing.idTeam) {
        debugPrint(
          '[MultiLeagueApiService] ERROR DE IDENTIDAD | '
          'standing=${standing.idTeam} | catalogo=${team.idTeam}',
        );
        return standing;
      }

      return standing.copyWith(badge: team.badge);
    }).toList();

    return _cacheLeague(
      LeagueDashboardData(
        league: league,
        standings: standings,
        events: results[1] as List<MatchEventData>,
      ),
    );
  }

  LeagueDashboardData _cacheLeague(LeagueDashboardData data) {
    _leagueCache[data.league.id] = data;
    return data;
  }

  Future<List<TeamStandingData>> _getStandings(LeagueConfig league) async {
    final uri = Uri.parse('$_baseUrl/lookuptable.php').replace(
      queryParameters: {'l': league.id, 's': season},
    );

    final response = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error en tabla ${league.name}: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final table = decoded['table'];
    if (table is! List) return [];

    return table
        .whereType<Map<String, dynamic>>()
        .map((team) {
          final idTeam = _clean(team['idTeam']);
          final name = _clean(team['strTeam']) ?? 'Sin nombre';

          if (idTeam == null) {
            debugPrint(
              '[MultiLeagueApiService] TABLA SIN idTeam | '
              'equipo=$name | liga=${league.name}',
            );
          }

          return TeamStandingData(
            idTeam: idTeam ?? '',
            team: name,
            rank: _toInt(team['intRank']),
            played: _toInt(team['intPlayed']),
            wins: _toInt(team['intWin']),
            draws: _toInt(team['intDraw']),
            losses: _toInt(team['intLoss']),
            goalsFor: _toInt(team['intGoalsFor']),
            goalsAgainst: _toInt(team['intGoalsAgainst']),
            goalDifference: _toInt(team['intGoalDifference']),
            points: _toInt(team['intPoints']),
            badge: _clean(team['strBadge'] ?? team['strTeamBadge']),
          );
        })
        .toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
  }

  Future<List<MatchEventData>> _getSeasonEvents(LeagueConfig league) async {
    final uri = Uri.parse('$_baseUrl/eventsseason.php').replace(
      queryParameters: {'id': league.id, 's': season},
    );

    try {
      final response = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final events = decoded['events'];
      if (events is! List) return [];

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
                event.homeTeam.isNotEmpty && event.awayTeam.isNotEmpty,
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String? _clean(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static int _toInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;

  static int? _parseScore(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return int.tryParse(text);
  }

  static DateTime? _parseDate(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
}
