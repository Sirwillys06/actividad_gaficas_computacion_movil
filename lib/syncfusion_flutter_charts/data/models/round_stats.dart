import '../../core/utils/stats_utils.dart';
import 'event.dart';

/// Agregado de una jornada (o de una fecha, si la API no informa jornadas).
class RoundStats {
  final int order;
  final String label;
  final List<SportEvent> events;

  const RoundStats({required this.order, required this.label, required this.events});

  int get matches => events.length;
  int get goals => events.fold(0, (sum, event) => sum + event.totalGoals);
  int get homeGoals => events.fold(0, (sum, event) => sum + event.homeScore!);
  int get awayGoals => events.fold(0, (sum, event) => sum + event.awayScore!);
  int get homeWins => events.where((event) => event.homeScore! > event.awayScore!).length;
  int get awayWins => events.where((event) => event.homeScore! < event.awayScore!).length;
  int get draws => events.where((event) => event.homeScore == event.awayScore).length;
  double get averageGoals => StatsUtils.ratio(goals, matches);
  List<int> get goalsPerMatch => events.map((event) => event.totalGoals).toList();
  int get minGoals => goalsPerMatch.isEmpty ? 0 : goalsPerMatch.reduce((a, b) => a < b ? a : b);
  int get maxGoals => goalsPerMatch.isEmpty ? 0 : goalsPerMatch.reduce((a, b) => a > b ? a : b);
}

/// Posición y puntos de un equipo al cierre de una jornada.
class StandingSnapshot {
  final int roundOrder;
  final String roundLabel;
  final int position;
  final int points;
  final int goalDifference;

  const StandingSnapshot({
    required this.roundOrder,
    required this.roundLabel,
    required this.position,
    required this.points,
    required this.goalDifference,
  });
}
