import 'package:actividad_graficos/syncfusion_flutter_charts/data/models/event.dart';

/// Fixture de pruebas con la forma exacta de los eventos de TheSportsDB.
/// Solo se usa en tests; la aplicación nunca genera partidos.
List<SportEvent> buildSeasonFixture({int teams = 10, int rounds = 6}) {
  final events = <SportEvent>[];
  var id = 1;
  for (var round = 1; round <= rounds; round++) {
    for (var match = 0; match < teams ~/ 2; match++) {
      final home = (match + round) % teams;
      final away = (teams - 1 - match + round) % teams;
      final day = round * 7 + match % 3;
      events.add(
        SportEvent(
          id: '${id++}',
          homeTeam: 'Team $home',
          awayTeam: 'Team $away',
          homeTeamId: 'T$home',
          awayTeamId: 'T$away',
          date: '2025-08-${(day % 28 + 1).toString().padLeft(2, '0')}',
          time: '${14 + match % 3}:00:00',
          round: round,
          season: '2025-2026',
          homeScore: (home * 3 + round) % 4,
          awayScore: (away + round * 2) % 3,
        ),
      );
    }
  }
  return events;
}

Map<String, dynamic> eventJson({
  String id = '1',
  String home = 'Arsenal',
  String away = 'Chelsea',
  Object? homeScore = '2',
  Object? awayScore = '1',
  Object? round = '1',
}) => {
  'idEvent': id,
  'strHomeTeam': home,
  'strAwayTeam': away,
  'idHomeTeam': '1$home'.hashCode.toString(),
  'idAwayTeam': '1$away'.hashCode.toString(),
  'intHomeScore': homeScore,
  'intAwayScore': awayScore,
  'intRound': round,
  'dateEvent': '2025-08-16',
  'strTime': '14:00:00',
  'strTimestamp': '2025-08-16T14:00:00',
  'strSeason': '2025-2026',
};
