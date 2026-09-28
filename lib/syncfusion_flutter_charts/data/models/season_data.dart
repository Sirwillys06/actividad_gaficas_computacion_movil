import 'event.dart';
import 'team.dart';

/// Conjunto de datos reales descargados para una liga y temporada.
class SeasonData {
  final String leagueId;
  final String season;
  final List<Team> teams;
  final List<SportEvent> events;

  /// Endpoints de los que procede la información (para mostrar la fuente).
  final Set<String> sources;

  const SeasonData({
    required this.leagueId,
    required this.season,
    required this.teams,
    required this.events,
    this.sources = const {},
  });

  int get scoredEvents => events.where((event) => event.hasScore).length;

  SeasonData copyWith({List<SportEvent>? events, Set<String>? sources}) => SeasonData(
    leagueId: leagueId,
    season: season,
    teams: teams,
    events: events ?? this.events,
    sources: sources ?? this.sources,
  );
}
