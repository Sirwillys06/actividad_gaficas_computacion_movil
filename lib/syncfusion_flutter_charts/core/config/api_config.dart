class ApiConfig {
  static const String baseUrl =
      'https://www.thesportsdb.com/api/v1/json';

  static const String apiKey = 'TU_API_KEY';

  static String leagueById(String leagueId) {
    return '$baseUrl/$apiKey/lookupleague.php?id=$leagueId';
  }
}