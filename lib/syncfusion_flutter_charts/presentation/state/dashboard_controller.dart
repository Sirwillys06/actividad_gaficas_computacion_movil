import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../data/mappers/season_analytics.dart';
import '../../data/models/league.dart';
import '../../data/models/ranking_filter.dart';
import '../../data/models/season_data.dart';
import '../../data/models/team_stats.dart';
import '../../data/repositories/sports_repository.dart';
import '../../data/services/sports_api_service.dart';
import '../charts/catalog/chart_definition.dart';

/// Estado de la pantalla principal. Descarga los datos una vez por
/// liga/temporada y deriva localmente todo lo que consumen los 80 gráficos.
class DashboardController extends ChangeNotifier {
  DashboardController({SportsRepository? repository}) : _repository = repository ?? SportsRepository();

  final SportsRepository _repository;

  List<League> leagues = const [];
  League? league;
  List<String> seasons = const [];
  String? season;
  SeasonData? data;
  SeasonAnalytics analytics = SeasonAnalytics.empty;

  RankingFilter filter = RankingFilter.all;
  String? _teamKey;
  List<String> _comparedKeys = const [];

  bool loadingLeagues = false;
  bool loadingSeason = false;
  String? error;

  bool completing = false;
  bool completed = false;
  String? completionStatus;
  int _loadToken = 0;
  bool _disposed = false;

  TeamStats? get team => analytics.team(_teamKey);

  List<TeamStats> get compared => _comparedKeys.map(analytics.team).whereType<TeamStats>().toList();

  bool get hasData => !analytics.isEmpty;

  ChartContext get chartContext => ChartContext(analytics: analytics, filter: filter, team: team, compared: compared);

  Future<void> init() => loadLeagues();

  Future<void> loadLeagues() async {
    loadingLeagues = true;
    error = null;
    _notify();
    try {
      final result = await _repository.getLeagues();
      leagues = result;
      if (result.isEmpty) {
        error = 'TheSportsDB no devolvió ligas de fútbol disponibles.';
        loadingLeagues = false;
        _notify();
        return;
      }
      final initial = result.firstWhere((item) => item.id == AppConstants.defaultLeagueId, orElse: () => result.first);
      loadingLeagues = false;
      _notify();
      await selectLeague(initial);
    } on SportsApiException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail(e.toString());
    }
  }

  Future<void> selectLeague(League value) async {
    final token = ++_loadToken;
    league = value;
    seasons = const [];
    season = null;
    _resetSeason();
    loadingSeason = true;
    error = null;
    _notify();
    try {
      // Detalle (temporada actual y escudo) y temporadas: 2 peticiones.
      final results = await Future.wait<Object?>([
        _repository.getLeagueDetails(value.id).catchError((Object _) => null),
        _repository.getSeasons(value.id).catchError((Object _) => const <String>[]),
      ]);
      if (token != _loadToken) return;
      final details = results[0] as League?;
      if (details != null) league = value.mergeDetails(details);
      final available = [...results[1] as List<String>];
      final current = league?.currentSeason;
      if (current != null && !available.contains(current)) available.insert(0, current);
      seasons = available;
      if (available.isEmpty) {
        loadingSeason = false;
        error = 'TheSportsDB no publica temporadas para ${value.name}.';
        _notify();
        return;
      }
      await selectSeason(current ?? available.first);
    } on SportsApiException catch (e) {
      if (token == _loadToken) _fail(e.message);
    } catch (e) {
      if (token == _loadToken) _fail(e.toString());
    }
  }

  Future<void> selectSeason(String value) async {
    final current = league;
    if (current == null) return;
    final token = ++_loadToken;
    season = value;
    _resetSeason();
    loadingSeason = true;
    error = null;
    _notify();
    try {
      final result = await _repository.getSeasonData(current, value);
      if (token != _loadToken) return;
      _applyData(result);
      loadingSeason = false;
      if (result.events.isEmpty) {
        error = 'TheSportsDB no devolvió partidos para ${current.name} $value.';
      }
      _notify();
    } on SportsApiException catch (e) {
      if (token == _loadToken) _fail(e.message);
    } catch (e) {
      if (token == _loadToken) _fail(e.toString());
    }
  }

  Future<void> refresh() async {
    _repository.clearCache();
    final current = league;
    if (current == null) return loadLeagues();
    final currentSeason = season;
    if (currentSeason == null) return selectLeague(current);
    return selectSeason(currentSeason);
  }

  /// Descarga jornada a jornada los partidos que `eventsseason` no devolvió.
  Future<void> completeSeason() async {
    final current = data;
    if (current == null || completing) return;
    final token = _loadToken;
    completing = true;
    completionStatus = 'Consultando jornadas…';
    _notify();
    try {
      var added = 0;
      final result = await _repository.completeSeasonByRounds(
        current,
        isCancelled: () => token != _loadToken || _disposed,
        onProgress: (round, newEvents) {
          added += newEvents;
          completionStatus = 'Jornada $round consultada · $added partidos nuevos';
          _notify();
        },
      );
      if (token != _loadToken) return;
      _applyData(result);
      completed = true;
      completionStatus = added == 0
          ? 'La temporada ya estaba completa: no faltaban partidos.'
          : 'Se añadieron $added partidos reales desde eventsround.';
    } on SportsApiException catch (e) {
      completionStatus = 'No se pudo completar: ${e.message}';
    } catch (e) {
      completionStatus = 'No se pudo completar: $e';
    } finally {
      completing = false;
      _notify();
    }
  }

  void setFilter(RankingFilter value) {
    filter = value;
    _notify();
  }

  void selectTeam(String? key) {
    _teamKey = key;
    _notify();
  }

  void setCompared(List<String> keys) {
    _comparedKeys = List.unmodifiable(keys);
    _notify();
  }

  void _applyData(SeasonData value) {
    data = value;
    analytics = SeasonAnalytics.fromEvents(value.events, teams: value.teams);
    final standings = analytics.standings;
    // Valores por defecto razonables: líder como equipo foco y top 3 para comparar.
    if (analytics.team(_teamKey) == null) {
      _teamKey = standings.isEmpty ? null : standings.first.key;
    }
    final keptCompared = _comparedKeys.where((key) => analytics.team(key) != null).toList();
    _comparedKeys = keptCompared.length >= 2 ? keptCompared : standings.take(3).map((team) => team.key).toList();
  }

  void _resetSeason() {
    data = null;
    analytics = SeasonAnalytics.empty;
    completed = false;
    completing = false;
    completionStatus = null;
  }

  void _fail(String message) {
    loadingLeagues = false;
    loadingSeason = false;
    error = message;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
