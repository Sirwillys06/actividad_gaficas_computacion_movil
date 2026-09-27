import 'package:flutter/material.dart';

import 'charts_flutter/basic/goals_for_column_chart.dart';
import 'charts_flutter/basic/standings_bar_chart.dart';
import 'charts_flutter/models/chart_data_set.dart';
import 'charts_flutter/services/sports_api_service.dart';
import 'charts_flutter/widgets/chart_section.dart';

const String _leagueId = '4328';
const String _season = '2026-2027';

enum _ChartFilter {
  all,
  top15,
  top10,
  top5,
}

class _FilterConfig {
  final _ChartFilter value;
  final String label;

  const _FilterConfig(this.value, this.label);
}

const _filterConfigs = [
  _FilterConfig(_ChartFilter.all, 'TODOS · 20'),
  _FilterConfig(_ChartFilter.top15, 'TOP 15'),
  _FilterConfig(_ChartFilter.top10, 'TOP 10'),
  _FilterConfig(_ChartFilter.top5, 'TOP 5'),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Premier League - Charts',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const ChartsFlutterHome(),
    );
  }
}

class ChartsFlutterHome extends StatefulWidget {
  const ChartsFlutterHome({super.key});

  @override
  State<ChartsFlutterHome> createState() => _ChartsFlutterHomeState();
}

class _ChartsFlutterHomeState extends State<ChartsFlutterHome> {
  final SportsApiService _apiService = SportsApiService();

  late Future<ChartDataSet> _standingsFuture;
  late Future<ChartDataSet> _goalsForFuture;
  late Future<String?> _leagueBadgeFuture;

  _ChartFilter _standingsFilter = _ChartFilter.all;
  _ChartFilter _goalsFilter = _ChartFilter.all;

  @override
  void initState() {
    super.initState();

    _standingsFuture = _apiService.getStandingsChartData(
      leagueId: _leagueId,
      season: _season,
    );

    _goalsForFuture = _apiService.getGoalsForChartData(
      leagueId: _leagueId,
      season: _season,
    );

    _leagueBadgeFuture = _apiService.getLeagueBadgeUrl(
      leagueId: _leagueId,
    );
  }

  ChartDataSet _filteredData(
    ChartDataSet data,
    _ChartFilter filter,
  ) {
    final limit = switch (filter) {
      _ChartFilter.all => data.points.length,
      _ChartFilter.top15 => 15,
      _ChartFilter.top10 => 10,
      _ChartFilter.top5 => 5,
    };

    return ChartDataSet(
      title: data.title,
      xLabel: data.xLabel,
      yLabel: data.yLabel,
      points: data.points.take(limit).toList(),
    );
  }

  Widget _buildChartFilter({
    required String title,
    required _ChartFilter selected,
    required ValueChanged<_ChartFilter> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Todos los equipos están disponibles. Elige cuántos quieres '
              'mostrar para facilitar la lectura.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filterConfigs.map((config) {
                return ChoiceChip(
                  label: Text(config.label),
                  selected: selected == config.value,
                  onSelected: (value) {
                    if (value) onChanged(config.value);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Premier League',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: FutureBuilder<ChartDataSet>(
          future: _standingsFuture,
          builder: (context, standingsSnapshot) {
            if (standingsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (standingsSnapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error al cargar la tabla de la Premier League:\n\n'
                    '${standingsSnapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final standingsData = standingsSnapshot.data;

            if (standingsData == null || standingsData.points.isEmpty) {
              return const Center(
                child: Text('No se encontraron datos de la Premier League.'),
              );
            }

            final filteredStandings = _filteredData(
              standingsData,
              _standingsFilter,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String?>(
                  future: _leagueBadgeFuture,
                  builder: (context, badgeSnapshot) {
                    final badge = badgeSnapshot.data;

                    return Row(
                      children: [
                        if (badge != null && badge.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Image.network(
                              badge,
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.sports_soccer,
                                  size: 42,
                                );
                              },
                            ),
                          ),
                        const Expanded(
                          child: Text(
                            'Premier League 2026-2027',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '${standingsData.points.length} equipos cargados desde TheSportsDB',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                ChartSection(
                  title: '1. Puntos por equipo',
                  description:
                      'Los 20 equipos de la Premier League aparecen en la '
                      'gráfica. El filtro solamente controla cuántos se '
                      'visualizan.',
                  chart: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildChartFilter(
                        title: 'Filtro de esta gráfica',
                        selected: _standingsFilter,
                        onChanged: (filter) {
                          setState(() => _standingsFilter = filter);
                        },
                      ),
                      StandingsBarChart(
                        data: filteredStandings,
                      ),
                    ],
                  ),
                ),

                FutureBuilder<ChartDataSet>(
                  future: _goalsForFuture,
                  builder: (context, goalsSnapshot) {
                    if (goalsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const ChartSection(
                        title: '2. Goles a favor por equipo',
                        description:
                            'Cargando los goles anotados por los 20 equipos.',
                        chart: SizedBox(
                          height: 350,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    }

                    if (goalsSnapshot.hasError) {
                      return ChartSection(
                        title: '2. Goles a favor por equipo',
                        description:
                            'No fue posible cargar esta gráfica.',
                        chart: Text(
                          'Error: ${goalsSnapshot.error}',
                        ),
                      );
                    }

                    final goalsData = goalsSnapshot.data;

                    if (goalsData == null || goalsData.points.isEmpty) {
                      return const ChartSection(
                        title: '2. Goles a favor por equipo',
                        description:
                            'No hay datos disponibles.',
                        chart: Text(
                          'No se encontraron datos.',
                        ),
                      );
                    }

                    final filteredGoals = _filteredData(
                      goalsData,
                      _goalsFilter,
                    );

                    return ChartSection(
                      title: '2. Goles a favor por equipo',
                      description:
                          'Los 20 equipos también se muestran aquí de forma '
                          'independiente. Este filtro no modifica la gráfica '
                          'de puntos.',
                      chart: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildChartFilter(
                            title: 'Filtro de esta gráfica',
                            selected: _goalsFilter,
                            onChanged: (filter) {
                              setState(() => _goalsFilter = filter);
                            },
                          ),
                          GoalsForColumnChart(
                            data: filteredGoals,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
