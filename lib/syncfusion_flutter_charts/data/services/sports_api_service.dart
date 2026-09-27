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

class SportsApiService {
  final http.Client _client;

  SportsApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Map<String, dynamic>>> _getList(Uri uri, String key) async {
    try {
      final response = await _client.get(uri).timeout(AppConstants.requestTimeout);
      if (response.statusCode != 200) {
        throw SportsApiException('TheSportsDB respondió con HTTP ' + response.statusCode.toString() + '.');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const SportsApiException('La respuesta JSON no tiene el formato esperado.');
      }

      final raw = decoded[key];
      if (raw == null) return const [];
      if (raw is! List) {
        throw SportsApiException('La propiedad ' + key + ' no contiene una lista.');
      }

      return raw.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    } on TimeoutException {
      throw const SportsApiException('La solicitud tardó demasiado. Comprueba tu conexión.');
    } on FormatException {
      throw const SportsApiException('TheSportsDB devolvió JSON inválido.');
    } on SportsApiException {
      rethrow;
    } catch (error) {
      throw SportsApiException('No fue posible consultar TheSportsDB: ' + error.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getLeagues() =>
      _getList(Uri.parse(ApiConfig.allLeagues), 'leagues');

  Future<List<Map<String, dynamic>>> getTeams(String leagueName) =>
      _getList(Uri.parse(ApiConfig.teamsByLeague(leagueName)), 'teams');

  Future<List<Map<String, dynamic>>> getPastLeagueEvents(String leagueId) =>
      _getList(Uri.parse(ApiConfig.pastLeagueEvents(leagueId)), 'events');

  Future<List<Map<String, dynamic>>> getNextLeagueEvents(String leagueId) =>
      _getList(Uri.parse(ApiConfig.nextLeagueEvents(leagueId)), 'events');
}
