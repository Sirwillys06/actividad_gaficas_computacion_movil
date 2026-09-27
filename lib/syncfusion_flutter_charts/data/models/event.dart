import '../../core/utils/json_utils.dart';

class SportEvent {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final String? date;
  final int? homeScore;
  final int? awayScore;
  final String? status;

  const SportEvent({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.date,
    this.homeScore,
    this.awayScore,
    this.status,
  });

  factory SportEvent.fromJson(Map<String, dynamic> json) {
    return SportEvent(
      id: JsonUtils.stringValue(json['idEvent']) ?? '',
      homeTeam: JsonUtils.stringValue(json['strHomeTeam']) ?? 'Local',
      awayTeam: JsonUtils.stringValue(json['strAwayTeam']) ?? 'Visitante',
      date: JsonUtils.stringValue(json['dateEvent']),
      homeScore: JsonUtils.intValue(json['intHomeScore']),
      awayScore: JsonUtils.intValue(json['intAwayScore']),
      status: JsonUtils.stringValue(json['strStatus']),
    );
  }

  bool get hasScore => homeScore != null && awayScore != null;
  int get totalGoals => (homeScore ?? 0) + (awayScore ?? 0);
}
