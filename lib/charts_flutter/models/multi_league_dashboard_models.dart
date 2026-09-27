class LeagueConfig {
  final String id;
  final String name;
  final String country;
  final String flag;

  const LeagueConfig({
    required this.id,
    required this.name,
    required this.country,
    required this.flag,
  });
}

class TeamStandingData {
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

  TeamStandingData copyWith({String? badge}) {
    return TeamStandingData(
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
  final int? homeScore;
  final int? awayScore;

  const MatchEventData({
    required this.id,
    required this.date,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
  });

  bool get hasScore => homeScore != null && awayScore != null;
  int get totalGoals =>
      (homeScore ?? 0) + (awayScore ?? 0);
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
}

const fiveMajorEuropeanLeagues = [
  LeagueConfig(
    id: '4328',
    name: 'Premier League',
    country: 'Inglaterra',
    flag: '🏴',
  ),
  LeagueConfig(
    id: '4335',
    name: 'La Liga',
    country: 'España',
    flag: '🇪🇸',
  ),
  LeagueConfig(
    id: '4332',
    name: 'Serie A',
    country: 'Italia',
    flag: '🇮🇹',
  ),
  LeagueConfig(
    id: '4331',
    name: 'Bundesliga',
    country: 'Alemania',
    flag: '🇩🇪',
  ),
  LeagueConfig(
    id: '4334',
    name: 'Ligue 1',
    country: 'Francia',
    flag: '🇫🇷',
  ),
];
