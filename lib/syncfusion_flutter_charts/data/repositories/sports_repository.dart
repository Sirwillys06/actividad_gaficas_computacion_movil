import 'dart:async';

import '../../core/constants/app_constants.dart';
import '../../core/utils/json_utils.dart';
import '../models/event.dart';
import '../models/league.dart';
import '../models/season_data.dart';
import '../models/team.dart';
import '../services/sports_api_service.dart';

/// Progreso al completar una temporada jornada a jornada.
typedef RoundProgress = void Function(int round, int newEvents);

/// Acceso a datos desacoplado de la UI.
///
/// Mantiene una cache en memoria por URL lógica: cambiar de pestaña, de
/// filtro o de equipo nunca dispara nuevas peticiones HTTP. Las peticiones
/// en curso se comparten (si dos widgets piden lo mismo se hace una llamada).
class SportsRepository {
  final SportsApiService _service;
  final Duration _roundInterval;
  final Map<String, Future<Object>> _cache = {};

  SportsRepository({SportsApiService? service, Duration? roundInterval})
    : _service = service ?? SportsApiService(),
      _roundInterval = roundInterval ?? AppConstants.roundRequestInterval;

  Future<T> _cached<T extends Object>(String key, Future<T> Function() loader) {
    final existing = _cache[key];
    if (existing != null) return existing.then((value) => value as T);
    final future = loader();
    _cache[key] = future;
    // Un error no se cachea: el siguiente intento vuelve a consultar la API.
    future.then<void>(
      (_) {},
      onError: (Object _) {
        _cache.remove(key);
      },
    );
    return future;
  }

  void clearCache() => _cache.clear();

  /// Ligas de fútbol disponibles (las métricas de puntos, goles y empates
  /// solo tienen sentido para este deporte).
  Future<List<League>> getLeagues() => _cached('leagues', () async {
    final data = await _service.getLeagues();
    final leagues =
        data
            .map(League.fromJson)
            .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
            .where((item) => item.sport == null || item.sport == AppConstants.analyzedSport)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return leagues;
  });

  Future<League?> getLeagueDetails(String leagueId) => _cached('league:$leagueId', () async {
    final data = await _service.getLeagueDetails(leagueId);
    final leagues = data.map(League.fromJson).where((item) => item.id.isNotEmpty);
    return leagues.isEmpty ? _NoLeague.instance : leagues.first;
  }).then((value) => value is _NoLeague ? null : value as League);

  /// Temporadas publicadas para la liga, de la más reciente a la más antigua.
  Future<List<String>> getSeasons(String leagueId) => _cached('seasons:$leagueId', () async {
    final data = await _service.getSeasons(leagueId);
    final seasons = data.map((item) => JsonUtils.stringValue(item['strSeason'])).whereType<String>().toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return seasons;
  });

  Future<List<Team>> getTeams(String leagueName) => _cached('teams:$leagueName', () async {
    final data = await _service.getTeams(leagueName);
    return data.map(Team.fromJson).where((item) => item.id.isNotEmpty).toList();
  });

  Future<List<SportEvent>> getPastEvents(String leagueId) =>
      _cached('past:$leagueId', () async => _toEvents(await _service.getPastLeagueEvents(leagueId)));

  Future<List<SportEvent>> getNextEvents(String leagueId) =>
      _cached('next:$leagueId', () async => _toEvents(await _service.getNextLeagueEvents(leagueId)));

  Future<List<SportEvent>> getSeasonEvents(String leagueId, String season) =>
      _cached('season:$leagueId:$season', () async => _toEvents(await _service.getSeasonEvents(leagueId, season)));

  Future<List<SportEvent>> getRoundEvents(String leagueId, int round, String season) => _cached(
    'round:$leagueId:$season:$round',
    () async => _toEvents(await _service.getRoundEvents(leagueId, round, season)),
  );

  /// Descarga en paralelo (2 peticiones) los equipos y los partidos de la
  /// temporada. Si `eventsseason` no devuelve partidos (p. ej. temporada aún
  /// no publicada) se recurre a los últimos partidos de la liga.
  Future<SeasonData> getSeasonData(League league, String season) async {
    final results = await Future.wait<Object>([
      getTeams(league.name).catchError((Object _) => const <Team>[]),
      getSeasonEvents(league.id, season),
    ]);
    final teams = results[0] as List<Team>;
    var events = results[1] as List<SportEvent>;
    final sources = <String>{'search_all_teams', 'eventsseason'};
    if (events.isEmpty) {
      events = (await getPastEvents(
        league.id,
      )).where((event) => event.season == null || event.season == season).toList();
      sources.add('eventspastleague');
    }
    return SeasonData(leagueId: league.id, season: season, teams: teams, events: events, sources: sources);
  }

  /// Completa una temporada descargando jornada a jornada las que faltan.
  ///
  /// El plan gratuito limita la cantidad de partidos que devuelve
  /// `eventsseason`; `eventsround` permite obtener el resto sin inventar
  /// nada. Las llamadas se espacian para respetar el límite de la API y se
  /// detiene tras dos jornadas vacías consecutivas posteriores a la última
  /// conocida.
  Future<SeasonData> completeSeasonByRounds(
    SeasonData data, {
    RoundProgress? onProgress,
    bool Function()? isCancelled,
  }) async {
    final byId = {for (final event in data.events) event.id: event};
    final teamKeys = <String>{
      for (final event in data.events) ...[event.homeKey, event.awayKey],
    };
    final matchesPerRound = teamKeys.length ~/ 2;
    final perRound = <int, int>{};
    for (final event in data.events) {
      final round = event.round;
      if (round != null) perRound[round] = (perRound[round] ?? 0) + 1;
    }
    final lastKnown = perRound.keys.isEmpty ? 0 : perRound.keys.reduce((a, b) => a > b ? a : b);

    var emptyStreak = 0;
    var requests = 0;
    for (var round = 1; round <= AppConstants.maxRoundsToFetch; round++) {
      if (isCancelled?.call() ?? false) break;
      final known = perRound[round] ?? 0;
      if (matchesPerRound > 0 && known >= matchesPerRound) continue;
      if (requests > 0) await Future<void>.delayed(_roundInterval);
      requests++;
      final events = await getRoundEvents(data.leagueId, round, data.season);
      var added = 0;
      for (final event in events) {
        if (byId.putIfAbsent(event.id, () => event) == event) added++;
      }
      onProgress?.call(round, added);
      if (events.isEmpty && round > lastKnown) {
        emptyStreak++;
        if (emptyStreak >= 2) break;
      } else {
        emptyStreak = 0;
      }
    }
    return data.copyWith(events: byId.values.toList(), sources: {...data.sources, 'eventsround'});
  }

  List<SportEvent> _toEvents(List<Map<String, dynamic>> data) =>
      data.map(SportEvent.fromJson).where((item) => item.id.isNotEmpty).toList();
}

class _NoLeague {
  const _NoLeague._();
  static const instance = _NoLeague._();
}
