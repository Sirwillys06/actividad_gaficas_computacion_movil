class ApiConfig {
  static const String baseUrl = 'https://www.thesportsdb.com/api/v1/json';
  static const String apiKey = '123';

  static String _endpoint(String path) => baseUrl + '/' + apiKey + '/' + path;

  static String get allLeagues => _endpoint('all_leagues.php');

  static String teamsByLeague(String leagueName) =>
      _endpoint('search_all_teams.php') + '?l=' + Uri.encodeQueryComponent(leagueName);

  static String pastLeagueEvents(String leagueId) =>
      _endpoint('eventspastleague.php') + '?id=' + leagueId;

  static String nextLeagueEvents(String leagueId) =>
      _endpoint('eventsnextleague.php') + '?id=' + leagueId;

  static String leagueById(String leagueId) =>
      _endpoint('lookupleague.php') + '?id=' + leagueId;
}
