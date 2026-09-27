class League {
  final String id;
  final String name;
  final String country;
  final String? logo;

  League({
    required this.id,
    required this.name,
    required this.country,
    this.logo,
  });

  factory League.fromJson(Map<String, dynamic> json) {
    return League(
      id: json['idLeague']?.toString() ?? '',
      name: json['strLeague']?.toString() ?? '',
      country: json['strCountry']?.toString() ?? '',
      logo: json['strBadge']?.toString(),
    );
  }
}