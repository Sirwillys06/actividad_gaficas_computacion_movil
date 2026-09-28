import '../../core/constants/app_constants.dart';
import '../../core/utils/stats_utils.dart';
import 'event.dart';

enum MatchOutcome { win, draw, loss }

/// Un partido desde el punto de vista de un equipo concreto.
class TeamMatch {
  final SportEvent event;
  final bool isHome;
  final int order;
  final int cumulativePoints;
  final int cumulativeGoalsFor;
  final int cumulativeGoalsAgainst;

  const TeamMatch({
    required this.event,
    required this.isHome,
    required this.order,
    required this.cumulativePoints,
    required this.cumulativeGoalsFor,
    required this.cumulativeGoalsAgainst,
  });

  int get goalsFor => isHome ? event.homeScore! : event.awayScore!;
  int get goalsAgainst => isHome ? event.awayScore! : event.homeScore!;
  int get goalDifference => goalsFor - goalsAgainst;
  String get opponent => isHome ? event.awayTeam : event.homeTeam;

  MatchOutcome get outcome => goalsFor > goalsAgainst
      ? MatchOutcome.win
      : goalsFor == goalsAgainst
      ? MatchOutcome.draw
      : MatchOutcome.loss;

  int get points => pointsFor(outcome);

  static int pointsFor(MatchOutcome outcome) => switch (outcome) {
    MatchOutcome.win => AppConstants.pointsPerWin,
    MatchOutcome.draw => AppConstants.pointsPerDraw,
    MatchOutcome.loss => 0,
  };

  String get label => '${isHome ? 'vs' : '@'} $opponent (${event.scoreLabel})';
}

/// Balance agregado de un conjunto de partidos (total, local o visitante).
class SplitRecord {
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;

  const SplitRecord({
    this.played = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
  });

  factory SplitRecord.fromMatches(Iterable<TeamMatch> matches) {
    var played = 0, wins = 0, draws = 0, losses = 0, goalsFor = 0, goalsAgainst = 0;
    for (final match in matches) {
      played++;
      goalsFor += match.goalsFor;
      goalsAgainst += match.goalsAgainst;
      switch (match.outcome) {
        case MatchOutcome.win:
          wins++;
        case MatchOutcome.draw:
          draws++;
        case MatchOutcome.loss:
          losses++;
      }
    }
    return SplitRecord(
      played: played,
      wins: wins,
      draws: draws,
      losses: losses,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
    );
  }

  int get points => wins * AppConstants.pointsPerWin + draws * AppConstants.pointsPerDraw;
  int get goalDifference => goalsFor - goalsAgainst;
  double get pointsPerMatch => StatsUtils.ratio(points, played);
  double get goalsForPerMatch => StatsUtils.ratio(goalsFor, played);
  double get goalsAgainstPerMatch => StatsUtils.ratio(goalsAgainst, played);
  double get winRate => StatsUtils.percent(wins, played);
  double get drawRate => StatsUtils.percent(draws, played);
  double get lossRate => StatsUtils.percent(losses, played);

  /// Porcentaje de puntos obtenidos sobre los puntos posibles.
  double get performance => StatsUtils.percent(points, played * AppConstants.pointsPerWin);
}

/// Estadísticas de temporada de un equipo, calculadas únicamente a partir de
/// partidos reales con marcador.
class TeamStats {
  final String key;
  final String name;
  final String? badge;
  final int rank;
  final List<TeamMatch> matches;
  final SplitRecord overall;
  final SplitRecord home;
  final SplitRecord away;

  TeamStats({required this.key, required this.name, required this.badge, required this.rank, required this.matches})
    : overall = SplitRecord.fromMatches(matches),
      home = SplitRecord.fromMatches(matches.where((match) => match.isHome)),
      away = SplitRecord.fromMatches(matches.where((match) => !match.isHome));

  TeamStats withRank(int value) => TeamStats(key: key, name: name, badge: badge, rank: value, matches: matches);

  int get played => overall.played;
  int get wins => overall.wins;
  int get draws => overall.draws;
  int get losses => overall.losses;
  int get goalsFor => overall.goalsFor;
  int get goalsAgainst => overall.goalsAgainst;
  int get goalDifference => overall.goalDifference;
  int get points => overall.points;
  double get pointsPerMatch => overall.pointsPerMatch;
  double get goalsForPerMatch => overall.goalsForPerMatch;
  double get goalsAgainstPerMatch => overall.goalsAgainstPerMatch;
  double get winRate => overall.winRate;
  double get drawRate => overall.drawRate;
  double get lossRate => overall.lossRate;
  double get performance => overall.performance;

  int get cleanSheets => matches.where((match) => match.goalsAgainst == 0).length;
  int get failedToScore => matches.where((match) => match.goalsFor == 0).length;
  int get bothTeamsScored => matches.where((match) => match.goalsFor > 0 && match.goalsAgainst > 0).length;
  int get overLineMatches => matches.where((match) => match.event.totalGoals > AppConstants.overUnderLine).length;
  double get bothTeamsScoredRate => StatsUtils.percent(bothTeamsScored, played);
  double get goalsPerMatchStdDev => StatsUtils.standardDeviation(matches.map((match) => match.goalsFor));

  /// Diferencia de puntos por partido entre local y visitante.
  double get homeAdvantage => home.pointsPerMatch - away.pointsPerMatch;

  List<TeamMatch> get recentMatches {
    final count = AppConstants.recentFormMatches;
    return matches.length <= count ? matches : matches.sublist(matches.length - count);
  }

  int get recentFormPoints => recentMatches.fold(0, (sum, match) => sum + match.points);
}
