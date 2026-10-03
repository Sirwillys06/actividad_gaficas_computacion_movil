import '../../core/utils/json_utils.dart';

class League {
  final String id;
  final String name;
  final String country;
  final String? sport;
  final String? logo;
  final String? currentSeason;

  const League({
    required this.id,
    required this.name,
    required this.country,
    this.sport,
    this.logo,
    this.currentSeason,
  });

  factory League.fromJson(Map<String, dynamic> json) {
    return League(
      id: JsonUtils.stringValue(json['idLeague']) ?? '',
      name: JsonUtils.stringValue(json['strLeague']) ?? '',
      country: JsonUtils.stringValue(json['strCountry']) ?? '',
      sport: JsonUtils.stringValue(json['strSport']),
      logo: JsonUtils.stringValue(json['strBadge']),
      currentSeason: JsonUtils.stringValue(json['strCurrentSeason']),
    );
  }

  /// Combina el listado general con el detalle de `lookupleague.php`.
  League mergeDetails(League details) => League(
    id: id,
    name: name,
    country: country.isNotEmpty ? country : details.country,
    sport: sport ?? details.sport,
    logo: details.logo ?? logo,
    currentSeason: details.currentSeason ?? currentSeason,
  );

  @override
  bool operator ==(Object other) => other is League && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
