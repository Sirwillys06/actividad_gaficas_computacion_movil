import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:actividad_graficos/syncfusion_flutter_charts/data/models/event.dart';

/// Cliente HTTP falso que responde con la misma forma JSON que TheSportsDB.
/// Registra las URLs solicitadas para verificar el uso de la cache.
class FakeSportsApi {
  FakeSportsApi({required this.events, this.failSeason = false});

  final List<SportEvent> events;
  final bool failSeason;
  final List<Uri> requests = [];

  late final http.Client client = MockClient((request) async {
    requests.add(request.url);
    final path = request.url.pathSegments.last;
    switch (path) {
      case 'all_leagues.php':
        return _json({
          'leagues': [
            {'idLeague': '4328', 'strLeague': 'English Premier League', 'strSport': 'Soccer'},
            {'idLeague': '4387', 'strLeague': 'NBA', 'strSport': 'Basketball'},
          ],
        });
      case 'lookupleague.php':
        return _json({
          'leagues': [
            {'idLeague': '4328', 'strLeague': 'English Premier League', 'strCurrentSeason': '2025-2026'},
          ],
        });
      case 'search_all_seasons.php':
        return _json({
          'seasons': [
            {'strSeason': '2024-2025'},
            {'strSeason': '2025-2026'},
          ],
        });
      case 'search_all_teams.php':
        return _json({'teams': null});
      case 'eventsseason.php':
        if (failSeason) return http.Response('error', 500);
        return _json({'events': events.map(_toJson).toList()});
      default:
        return _json({'events': null});
    }
  });

  static http.Response _json(Object body) =>
      http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

  static Map<String, dynamic> _toJson(SportEvent e) => {
    'idEvent': e.id,
    'strHomeTeam': e.homeTeam,
    'strAwayTeam': e.awayTeam,
    'idHomeTeam': e.homeTeamId,
    'idAwayTeam': e.awayTeamId,
    'intHomeScore': e.homeScore?.toString(),
    'intAwayScore': e.awayScore?.toString(),
    'intRound': e.round?.toString(),
    'dateEvent': e.date,
    'strTime': e.time,
    'strSeason': e.season,
  };
}
