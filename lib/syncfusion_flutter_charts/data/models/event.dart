import '../../core/utils/json_utils.dart';

/// Partido tal como lo entrega TheSportsDB (`events` en los endpoints de
/// eventos). Los marcadores son opcionales: un partido sin marcador nunca se
/// usa para calcular métricas.
class SportEvent {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final String? homeTeamId;
  final String? awayTeamId;
  final String? homeBadge;
  final String? awayBadge;
  final String? date;
  final String? time;
  final String? timestamp;
  final int? round;
  final String? season;
  final String? venue;
  final int? homeScore;
  final int? awayScore;
  final String? status;
  final bool postponed;

  const SportEvent({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamId,
    this.awayTeamId,
    this.homeBadge,
    this.awayBadge,
    this.date,
    this.time,
    this.timestamp,
    this.round,
    this.season,
    this.venue,
    this.homeScore,
    this.awayScore,
    this.status,
    this.postponed = false,
  });

  factory SportEvent.fromJson(Map<String, dynamic> json) {
    final round = JsonUtils.intValue(json['intRound']);
    return SportEvent(
      id: JsonUtils.stringValue(json['idEvent']) ?? '',
      homeTeam: JsonUtils.stringValue(json['strHomeTeam']) ?? 'Local',
      awayTeam: JsonUtils.stringValue(json['strAwayTeam']) ?? 'Visitante',
      homeTeamId: JsonUtils.stringValue(json['idHomeTeam']),
      awayTeamId: JsonUtils.stringValue(json['idAwayTeam']),
      homeBadge: JsonUtils.stringValue(json['strHomeTeamBadge']),
      awayBadge: JsonUtils.stringValue(json['strAwayTeamBadge']),
      date: JsonUtils.stringValue(json['dateEvent']),
      time: JsonUtils.stringValue(json['strTime']),
      timestamp: JsonUtils.stringValue(json['strTimestamp']),
      // TheSportsDB usa 0 o valores altos (p. ej. 125, 150, 160…) para fases
      // especiales; solo se consideran jornadas los valores positivos.
      round: round != null && round > 0 ? round : null,
      season: JsonUtils.stringValue(json['strSeason']),
      venue: JsonUtils.stringValue(json['strVenue']),
      homeScore: JsonUtils.intValue(json['intHomeScore']),
      awayScore: JsonUtils.intValue(json['intAwayScore']),
      status: JsonUtils.stringValue(json['strStatus']),
      postponed: JsonUtils.stringValue(json['strPostponed'])?.toLowerCase() == 'yes',
    );
  }

  bool get hasScore => !postponed && homeScore != null && awayScore != null;
  int get totalGoals => (homeScore ?? 0) + (awayScore ?? 0);

  /// Identificador estable del equipo: el id de TheSportsDB o, si falta, el nombre.
  String get homeKey => homeTeamId ?? homeTeam;
  String get awayKey => awayTeamId ?? awayTeam;

  bool involves(String teamKey) => homeKey == teamKey || awayKey == teamKey;

  /// Fecha/hora de inicio en UTC si la API la proporciona.
  DateTime? get kickoff {
    final stamp = timestamp;
    if (stamp != null) {
      final parsed = DateTime.tryParse(stamp.endsWith('Z') || stamp.contains('+') ? stamp : '${stamp}Z');
      if (parsed != null) return parsed.toUtc();
    }
    final day = date;
    if (day == null) return null;
    final clock = time;
    return DateTime.tryParse(
      clock == null ? '${day}T00:00:00Z' : '${day}T${clock.length >= 8 ? clock.substring(0, 8) : clock}Z',
    )?.toUtc();
  }

  /// Día natural del partido (sin hora) si hay fecha.
  DateTime? get day {
    final value = date;
    return value == null ? null : DateTime.tryParse(value);
  }

  /// Hora UTC de inicio si la API la informa explícitamente.
  int? get kickoffHourUtc {
    if (time == null && timestamp == null) return null;
    return kickoff?.hour;
  }

  String get scoreLabel => hasScore ? '$homeScore-$awayScore' : 'vs';
  String get matchLabel => '$homeTeam $scoreLabel $awayTeam';
}
