class LeagueConfig {
  final String id;
  final String name;
  final String country;
  final String flag;

  /// Nombre corto para chips y navegación compacta.
  final String shortName;

  const LeagueConfig({
    required this.id,
    required this.name,
    required this.country,
    required this.flag,
    required this.shortName,
  });
}

/// Datos maestros de un equipo obtenidos desde TheSportsDB.
///
/// [idTeam] es la clave principal. El escudo nunca se relaciona por
/// posición dentro de una lista ni por nombre.
class Team {
  final String idTeam;
  final String name;
  final String? badge;
  final String league;
  final String country;

  const Team({
    required this.idTeam,
    required this.name,
    required this.badge,
    required this.league,
    required this.country,
  });
}

class TeamStandingData {
  final String idTeam;
  final String team;
  final int rank;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;
  final String? badge;

  const TeamStandingData({
    required this.idTeam,
    required this.team,
    required this.rank,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
    this.badge,
  });

  double get winRate => played == 0 ? 0 : wins / played;
  double get goalsPerMatch => played == 0 ? 0 : goalsFor / played;
  double get goalsAgainstPerMatch =>
      played == 0 ? 0 : goalsAgainst / played;
  double get pointsPerMatch => played == 0 ? 0 : points / played;

  TeamStandingData copyWith({
    String? badge,
  }) {
    return TeamStandingData(
      idTeam: idTeam,
      team: team,
      rank: rank,
      played: played,
      wins: wins,
      draws: draws,
      losses: losses,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      goalDifference: goalDifference,
      points: points,
      badge: badge ?? this.badge,
    );
  }
}

class MatchEventData {
  final String id;
  final DateTime? date;
  final String homeTeam;
  final String awayTeam;

  /// idTeam del local y del visitante. Permiten cruzar un partido con la
  /// tabla sin depender del nombre del equipo.
  final String? homeTeamId;
  final String? awayTeamId;
  final int? homeScore;
  final int? awayScore;
  final int? round;

  const MatchEventData({
    required this.id,
    required this.date,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    this.homeTeamId,
    this.awayTeamId,
    this.round,
  });

  bool get hasScore => homeScore != null && awayScore != null;

  int get totalGoals => (homeScore ?? 0) + (awayScore ?? 0);

  bool get isHomeWin => hasScore && homeScore! > awayScore!;

  bool get isAwayWin => hasScore && awayScore! > homeScore!;

  bool get isDraw => hasScore && homeScore == awayScore;

  String get scoreLine =>
      hasScore ? '$homeTeam $homeScore - $awayScore $awayTeam' : '$homeTeam vs $awayTeam';
}

class LeagueDashboardData {
  final LeagueConfig league;
  final List<TeamStandingData> standings;
  final List<MatchEventData> events;
  final String? badge;

  const LeagueDashboardData({
    required this.league,
    required this.standings,
    required this.events,
    this.badge,
  });

  int get totalTeams => standings.length;

  int get totalMatches => events.where((event) => event.hasScore).length;

  int get totalGoals => events
      .where((event) => event.hasScore)
      .fold(0, (sum, event) => sum + event.totalGoals);

  /// Búsqueda por idTeam. Nunca se relaciona un equipo por nombre.
  TeamStandingData? teamById(String? idTeam) {
    if (idTeam == null || idTeam.isEmpty) return null;
    for (final team in standings) {
      if (team.idTeam == idTeam) return team;
    }
    return null;
  }
}

const fiveMajorEuropeanLeagues = [
  LeagueConfig(
    id: '4328',
    name: 'Premier League',
    shortName: 'EPL',
    country: 'Inglaterra',
    // Bandera de Inglaterra (secuencia de subdivisión gbeng).
    flag: '\u{1F3F4}\u{E0067}\u{E0062}\u{E0065}\u{E006E}\u{E0067}\u{E007F}',
  ),
  LeagueConfig(
    id: '4335',
    name: 'La Liga',
    shortName: 'LaLiga',
    country: 'España',
    flag: '🇪🇸',
  ),
  LeagueConfig(
    id: '4332',
    name: 'Serie A',
    shortName: 'Serie A',
    country: 'Italia',
    flag: '🇮🇹',
  ),
  LeagueConfig(
    id: '4331',
    name: 'Bundesliga',
    shortName: 'Bundesliga',
    country: 'Alemania',
    flag: '🇩🇪',
  ),
  LeagueConfig(
    id: '4334',
    name: 'Ligue 1',
    shortName: 'Ligue 1',
    country: 'Francia',
    flag: '🇫🇷',
  ),
];
