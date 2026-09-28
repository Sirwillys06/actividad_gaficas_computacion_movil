import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/constants/app_constants.dart';

class SportsApiException implements Exception {
  final String message;
  const SportsApiException(this.message);

  @override
  String toString() => message;
}

/// Cliente HTTP de bajo nivel para TheSportsDB. Devuelve JSON sin transformar;
/// la conversión a modelos se hace en `SportsRepository`.
class SportsApiService {
  final http.Client _client;

  SportsApiService({http.Client? client}) : _client = client ?? http.Client();

  static const Map<String, String> _headers = {'Accept': 'application/json'};

  Future<List<Map<String, dynamic>>> _getList(String url, String key) async {
    try {
      final response = await _client.get(Uri.parse(url), headers: _headers).timeout(AppConstants.requestTimeout);
      if (response.statusCode == 429) {
        throw const SportsApiException(
          'Se alcanzó el límite de peticiones de TheSportsDB. Espera un minuto y vuelve a intentarlo.',
        );
      }
      if (response.statusCode != 200) {
        throw SportsApiException('TheSportsDB respondió con HTTP ${response.statusCode}.');
      }
      if (response.body.trim().isEmpty) return const [];

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const SportsApiException('La respuesta JSON no tiene el formato esperado.');
      }

      final raw = decoded[key];
      if (raw == null) return const [];
      if (raw is! List) {
        // La API devuelve p. ej. "events": "No data" cuando no hay resultados.
        if (raw is String) return const [];
        throw SportsApiException('La propiedad $key no contiene una lista.');
      }

      return raw.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    } on TimeoutException {
      throw const SportsApiException('La solicitud tardó demasiado. Comprueba tu conexión.');
    } on FormatException {
      throw const SportsApiException('TheSportsDB devolvió JSON inválido.');
    } on SportsApiException {
      rethrow;
    } catch (error) {
      throw SportsApiException('No fue posible consultar TheSportsDB: $error');
    }
  }

  Future<List<Map<String, dynamic>>> getLeagues() => _getList(ApiConfig.allLeagues, 'leagues');

  Future<List<Map<String, dynamic>>> getLeagueDetails(String leagueId) =>
      _getList(ApiConfig.leagueById(leagueId), 'leagues');

  Future<List<Map<String, dynamic>>> getSeasons(String leagueId) =>
      _getList(ApiConfig.seasonsByLeague(leagueId), 'seasons');

  Future<List<Map<String, dynamic>>> getTeams(String leagueName) =>
      _getList(ApiConfig.teamsByLeague(leagueName), 'teams');

  Future<List<Map<String, dynamic>>> getPastLeagueEvents(String leagueId) =>
      _getList(ApiConfig.pastLeagueEvents(leagueId), 'events');

  Future<List<Map<String, dynamic>>> getNextLeagueEvents(String leagueId) =>
      _getList(ApiConfig.nextLeagueEvents(leagueId), 'events');

  Future<List<Map<String, dynamic>>> getSeasonEvents(String leagueId, String season) =>
      _getList(ApiConfig.seasonEvents(leagueId, season), 'events');

  Future<List<Map<String, dynamic>>> getRoundEvents(String leagueId, int round, String season) =>
      _getList(ApiConfig.roundEvents(leagueId, round, season), 'events');
}
