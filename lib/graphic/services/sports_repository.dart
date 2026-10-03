import 'sports_api_service.dart';

/// Carga los 4 endpoints una sola vez al iniciar la app y guarda el JSON
/// crudo, para que los 79 gráficos lean de aquí en vez de golpear la API
/// cada uno (evita el rate-limit 429 de la clave pública).
class SportsRepository {
  SportsRepository({SportsApiService? api}) : _api = api ?? SportsApiService();

  final SportsApiService _api;

  List<Map<String, Object?>> standings = const [];
  List<Map<String, Object?>> events = const [];
  List<Map<String, Object?>> eventStats = const [];
  List<Map<String, Object?>> teams = const [];

  Future<void> loadAll() async {
    final results = await Future.wait([
      _api.fetchStandings(),
      _api.fetchEventsSeason(),
      _api.fetchTeams(),
    ]);
    standings = results[0];
    events = results[1];
    teams = results[2];

    final firstEventId = events.isNotEmpty
        ? events.first['idEvent']?.toString()
        : null;
    eventStats = firstEventId == null
        ? const []
        : await _api.fetchEventStats(eventId: firstEventId);
  }
}
