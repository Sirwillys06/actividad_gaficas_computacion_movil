import '../../core/utils/json_utils.dart';

class Team {
  final String id;
  final String name;
  final String? badge;
  final String? stadium;
  final String? country;

  const Team({
    required this.id,
    required this.name,
    this.badge,
    this.stadium,
    this.country,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: JsonUtils.stringValue(json['idTeam']) ?? '',
      name: JsonUtils.stringValue(json['strTeam']) ?? 'Equipo sin nombre',
      badge: JsonUtils.stringValue(json['strBadge']),
      stadium: JsonUtils.stringValue(json['strStadium']),
      country: JsonUtils.stringValue(json['strCountry']),
    );
  }
}
