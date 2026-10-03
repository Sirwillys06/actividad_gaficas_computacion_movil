/// Punto único de configuración de TheSportsDB (API REST v1).
///
/// Ningún widget construye URLs: todas pasan por aquí y se consumen desde
/// `SportsApiService`.
class ApiConfig {
  static const String baseUrl = 'https://www.thesportsdb.com/api/v1/json';
  static const String apiKey = '123';

  static String _endpoint(String path) => '$baseUrl/$apiKey/$path';

  static String _query(String path, Map<String, String> params) {
    final query = params.entries.map((entry) => '${entry.key}=${Uri.encodeQueryComponent(entry.value)}').join('&');
    return '${_endpoint(path)}?$query';
  }

  static String get allLeagues => _endpoint('all_leagues.php');

  static String teamsByLeague(String leagueName) => _query('search_all_teams.php', {'l': leagueName});

  static String pastLeagueEvents(String leagueId) => _query('eventspastleague.php', {'id': leagueId});

  static String nextLeagueEvents(String leagueId) => _query('eventsnextleague.php', {'id': leagueId});

  static String leagueById(String leagueId) => _query('lookupleague.php', {'id': leagueId});

  static String seasonsByLeague(String leagueId) => _query('search_all_seasons.php', {'id': leagueId});

  static String seasonEvents(String leagueId, String season) =>
      _query('eventsseason.php', {'id': leagueId, 's': season});

  static String roundEvents(String leagueId, int round, String season) =>
      _query('eventsround.php', {'id': leagueId, 'r': '$round', 's': season});
}
