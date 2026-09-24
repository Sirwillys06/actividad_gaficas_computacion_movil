import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chart_data_models.dart';

class FlChartDataService {
  static const baseUrl = 'https://www.thesportsdb.com/api/v1/json/3';
  final http.Client client;
  FlChartDataService({http.Client? client}) : client = client ?? http.Client();

  Future<ChartDataSet> standings({String leagueId = '4328', String season = '2023-2024'}) async {
    try {
      final response = await client.get(Uri.parse('$baseUrl/lookuptable.php?l=$leagueId&s=$season'));
      if (response.statusCode != 200) return SportsApiMock.getMockStandings();
      final rows = (jsonDecode(response.body)['table'] as List? ?? const []);
      final points = rows.map((row) => ChartDataPoint(
        label: row['strTeam']?.toString() ?? '?', value: row['intPoints'].toSafeDouble(),
        secondaryValue: row['intGoalsFor'].toSafeDouble(),
        extraMetaData: {'against': row['intGoalsAgainst'].toSafeDouble()},
      )).toList();
      return points.isEmpty ? SportsApiMock.getMockStandings() : ChartDataSet(
        title: 'Posiciones $season', xLabel: 'Equipos', yLabel: 'Puntos', points: points);
    } catch (_) { return SportsApiMock.getMockStandings(); }
  }

  Future<ChartDataSet> eventStats({String eventId = '1032718'}) async {
    try {
      final response = await client.get(Uri.parse('$baseUrl/lookupeventstats.php?id=$eventId'));
      if (response.statusCode != 200) return SportsApiMock.getMockMatchStats();
      final rows = (jsonDecode(response.body)['eventstats'] as List? ?? const []);
      final points = rows.map((row) => ChartDataPoint(label: row['strStat'] ?? 'Métrica',
        value: row['intHome'].toSafeDouble(), secondaryValue: row['intAway'].toSafeDouble())).toList();
      return points.isEmpty ? SportsApiMock.getMockMatchStats() : ChartDataSet(
        title: 'Estadísticas del partido', xLabel: 'Métrica', yLabel: 'Valor', points: points);
    } catch (_) { return SportsApiMock.getMockMatchStats(); }
  }
}
