import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../data/mappers/chart_data_mapper.dart';
import '../../data/models/event.dart';
import '../../data/models/league.dart';
import '../../data/models/team.dart';
import '../../data/repositories/sports_repository.dart';
import '../../data/services/sports_api_service.dart';
import '../charts/goals_by_team_chart.dart';
import '../charts/goals_per_match_chart.dart';
import '../charts/outcomes_doughnut_chart.dart';
import '../widgets/chart_card.dart';
import '../widgets/status_view.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SportsRepository _repository = SportsRepository();

  List<League> _leagues = const [];
  List<Team> _teams = const [];
  List<SportEvent> _events = const [];
  League? _selectedLeague;
  Team? _selectedTeam;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeagues();
  }

  Future<void> _loadLeagues() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final leagues = await _repository.getLeagues();
      if (!mounted) return;
      League? selected;
      for (final league in leagues) {
        if (league.id == AppConstants.defaultLeagueId) {
          selected = league;
          break;
        }
      }
      selected ??= leagues.isEmpty ? null : leagues.first;
      setState(() {
        _leagues = leagues;
        _selectedLeague = selected;
        _loading = selected == null;
        _error = selected == null ? 'TheSportsDB no devolvió ligas disponibles.' : null;
      });
      if (selected != null) await _loadLeagueData(selected);
    } on SportsApiException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.message;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<void> _loadLeagueData(League league) async {
    setState(() {
      _loading = true;
      _error = null;
      _teams = const [];
      _events = const [];
      _selectedTeam = null;
    });
    try {
      final results = await Future.wait([
        _repository.getTeams(league.name),
        _repository.getPastEvents(league.id),
      ]);
      if (!mounted) return;
      setState(() {
        _teams = results[0] as List<Team>;
        _events = results[1] as List<SportEvent>;
        _loading = false;
      });
    } on SportsApiException catch (error) {
      if (mounted) setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (error) {
      if (mounted) setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  List<SportEvent> get _visibleEvents {
    if (_selectedTeam == null) return _events;
    return _events.where((event) => event.homeTeam == _selectedTeam!.name || event.awayTeam == _selectedTeam!.name).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sports Analytics'),
        actions: [
          IconButton(onPressed: _loadLeagues, icon: const Icon(Icons.refresh), tooltip: 'Actualizar'),
        ],
      ),
      body: _loading && _leagues.isEmpty
          ? const LoadingView()
          : _error != null && _leagues.isEmpty
              ? ErrorView(message: _error!, onRetry: _loadLeagues)
              : RefreshIndicator(
                  onRefresh: () async {
                    final league = _selectedLeague;
                    if (league != null) await _loadLeagueData(league);
                  },
                  child: LayoutBuilder(builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    final events = _visibleEvents;
                    final goals = ChartDataMapper.goalsByTeam(events);
                    final outcomes = ChartDataMapper.outcomes(events);
                    final goalsByMatch = ChartDataMapper.goalsByMatch(events);
                    final scored = events.where((item) => item.hasScore).length;
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text('Panel de análisis deportivo', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Datos consultados directamente desde TheSportsDB.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70)),
                        const SizedBox(height: 20),
                        Card(child: Padding(padding: const EdgeInsets.all(16), child: Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
                          SizedBox(width: wide ? 320 : constraints.maxWidth - 72, child: DropdownButtonFormField<League>(
                            initialValue: _selectedLeague,
                            decoration: const InputDecoration(labelText: 'Liga', prefixIcon: Icon(Icons.emoji_events_outlined)),
                            items: _leagues.map((league) => DropdownMenuItem(value: league, child: Text(league.name, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (league) { if (league != null) { setState(() => _selectedLeague = league); _loadLeagueData(league); } },
                          )),
                          SizedBox(width: wide ? 320 : constraints.maxWidth - 72, child: DropdownButtonFormField<Team>(
                            initialValue: _selectedTeam,
                            decoration: const InputDecoration(labelText: 'Equipo', prefixIcon: Icon(Icons.shield_outlined)),
                            items: [const DropdownMenuItem<Team>(value: null, child: Text('Todos los equipos')), ..._teams.map((team) => DropdownMenuItem(value: team, child: Text(team.name, overflow: TextOverflow.ellipsis)))],
                            onChanged: (team) => setState(() => _selectedTeam = team),
                          )),
                        ]))),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [const Icon(Icons.warning_amber_rounded), const SizedBox(width: 10), Expanded(child: Text(_error!))]))),
                        ],
                        const SizedBox(height: 20),
                        if (_loading) const LinearProgressIndicator(),
                        const SizedBox(height: 12),
                        Wrap(spacing: 12, runSpacing: 12, children: [
                          SizedBox(width: wide ? 250 : (constraints.maxWidth - 12) / 2, child: SummaryCard(label: 'Equipos disponibles', value: _teams.length.toString(), icon: Icons.groups_rounded)),
                          SizedBox(width: wide ? 250 : (constraints.maxWidth - 12) / 2, child: SummaryCard(label: 'Partidos analizados', value: events.length.toString(), icon: Icons.sports_soccer_rounded)),
                          SizedBox(width: wide ? 250 : (constraints.maxWidth - 12) / 2, child: SummaryCard(label: 'Con marcador', value: scored.toString(), icon: Icons.scoreboard_rounded)),
                        ]),
                        const SizedBox(height: 20),
                        if (events.isEmpty)
                          const Card(child: EmptyView())
                        else ...[
                          if (goals.isNotEmpty) ChartCard(title: 'Goles por equipo', description: 'Compara los goles registrados en los partidos disponibles para la selección actual.', child: GoalsByTeamChart(data: goals)),
                          const SizedBox(height: 16),
                          if (outcomes.isNotEmpty) ChartCard(title: 'Distribución de resultados', description: 'Muestra cómo se reparten las victorias locales, empates y victorias visitantes.', child: OutcomesDoughnutChart(data: outcomes)),
                          const SizedBox(height: 16),
                          if (goalsByMatch.isNotEmpty) ChartCard(title: 'Goles por partido', description: 'Explora la variación de goles de los partidos recientes. Usa zoom, pan y crosshair para inspeccionar puntos.', child: GoalsPerMatchChart(data: goalsByMatch)),
                        ],
                        const SizedBox(height: 24),
                        Text('Fuente: TheSportsDB', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
                      ],
                    );
                  }),
                ),
    );
  }
}
