import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:actividad_graficos/syncfusion_flutter_charts/core/config/api_config.dart';
import 'package:actividad_graficos/syncfusion_flutter_charts/data/models/league.dart';

class SportsApiService {
  Future<League?> getLeague(String leagueId) async {
    final url = Uri.parse(
      ApiConfig.leagueById(leagueId),
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Error al consultar TheSportsDB: ${response.statusCode}',
      );
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    final List<dynamic>? leagues = data['leagues'] as List<dynamic>?;

    if (leagues == null || leagues.isEmpty) {
      return null;
    }

    return League.fromJson(
      leagues.first as Map<String, dynamic>,
    );
  }
}