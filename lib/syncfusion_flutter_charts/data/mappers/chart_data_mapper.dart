import '../models/event.dart';
import '../models/match_result.dart';

class ChartDataMapper {
  static List<MatchResult> goalsByTeam(List<SportEvent> events) {
    final totals = <String, double>{};
    for (final event in events.where((item) => item.hasScore)) {
      totals.update(event.homeTeam, (value) => value + event.homeScore!, ifAbsent: () => event.homeScore!.toDouble());
      totals.update(event.awayTeam, (value) => value + event.awayScore!, ifAbsent: () => event.awayScore!.toDouble());
    }
    final result = totals.entries.map((e) => MatchResult(e.key, e.value)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return result.take(8).toList();
  }

  static List<MatchResult> outcomes(List<SportEvent> events) {
    double homeWins = 0, draws = 0, awayWins = 0;
    for (final event in events.where((item) => item.hasScore)) {
      if (event.homeScore == event.awayScore) {
        draws++;
      } else if (event.homeScore! > event.awayScore!) {
        homeWins++;
      } else {
        awayWins++;
      }
    }
    return [
      MatchResult('Victorias locales', homeWins),
      MatchResult('Empates', draws),
      MatchResult('Victorias visitantes', awayWins),
    ].where((item) => item.value > 0).toList();
  }

  static List<MatchResult> goalsByMatch(List<SportEvent> events) {
    return events.where((item) => item.hasScore).take(12).toList().asMap().entries.map(
      (entry) => MatchResult((entry.key + 1).toString(), entry.value.totalGoals.toDouble()),
    ).toList();
  }
}
