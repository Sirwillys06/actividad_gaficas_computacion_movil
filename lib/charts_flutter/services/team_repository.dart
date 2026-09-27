import 'package:flutter/foundation.dart';

import '../models/multi_league_dashboard_models.dart';

/// Cache maestro de equipos.
/// La clave siempre es idTeam; los 80 gráficos reutilizan los mismos objetos.
class TeamRepository {
  final Map<String, Map<String, Team>> _cacheByLeagueId = {};

  Map<String, Team> getCachedTeams(LeagueConfig league) =>
      _cacheByLeagueId[league.id] ?? const <String, Team>{};

  /// Alimenta el cache con la tabla completa de la liga.
  ///
  /// lookuptable.php es la fuente de los 20 equipos y, cuando TheSportsDB
  /// entrega el recurso, strBadge queda asociado al mismo idTeam.
  Map<String, Team> cacheFromStandings(
    LeagueConfig league,
    List<TeamStandingData> standings,
  ) {
    final teams = <String, Team>{};

    for (final standing in standings) {
      if (standing.idTeam.isEmpty) {
        debugPrint(
          '[TeamRepository] SIN idTeam | equipo=' +
              standing.team +
              ' | liga=' +
              league.name,
        );
        continue;
      }

      final team = Team(
        idTeam: standing.idTeam,
        name: standing.team,
        badge: _clean(standing.badge),
        league: league.name,
        country: league.country,
      );

      teams[team.idTeam] = team;

      if (team.badge == null) {
        debugPrint(
          '[TeamRepository] SIN ESCUDO | idTeam=' +
              team.idTeam +
              ' | equipo=' +
              team.name +
              ' | liga=' +
              league.name,
        );
      }
    }

    _cacheByLeagueId[league.id] = teams;
    debugPrint(
      '[TeamRepository] ' +
          league.name +
          ': ' +
          teams.length.toString() +
          ' equipos cacheados por idTeam.',
    );
    return teams;
  }

  Team? getTeamById(LeagueConfig league, String idTeam) {
    return _cacheByLeagueId[league.id]?[idTeam];
  }

  static String? _clean(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}