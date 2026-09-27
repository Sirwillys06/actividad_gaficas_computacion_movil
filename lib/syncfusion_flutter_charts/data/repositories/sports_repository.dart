import '../models/event.dart';
import '../models/league.dart';
import '../models/team.dart';
import '../services/sports_api_service.dart';

class SportsRepository {
  final SportsApiService _service;

  SportsRepository({SportsApiService? service}) : _service = service ?? SportsApiService();

  Future<List<League>> getLeagues() async {
    final data = await _service.getLeagues();
    return data.map(League.fromJson).where((item) => item.id.isNotEmpty && item.name.isNotEmpty).toList();
  }

  Future<List<Team>> getTeams(String leagueName) async {
    final data = await _service.getTeams(leagueName);
    return data.map(Team.fromJson).where((item) => item.id.isNotEmpty).toList();
  }

  Future<List<SportEvent>> getPastEvents(String leagueId) async {
    final data = await _service.getPastLeagueEvents(leagueId);
    return data.map(SportEvent.fromJson).where((item) => item.id.isNotEmpty).toList();
  }

  Future<List<SportEvent>> getNextEvents(String leagueId) async {
    final data = await _service.getNextLeagueEvents(leagueId);
    return data.map(SportEvent.fromJson).where((item) => item.id.isNotEmpty).toList();
  }
}
