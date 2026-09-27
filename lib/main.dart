import 'package:flutter/material.dart';

import 'charts_flutter/basic/goals_for_column_chart.dart';
import 'charts_flutter/basic/standings_bar_chart.dart';
import 'charts_flutter/models/chart_data_point.dart';
import 'charts_flutter/models/chart_data_set.dart';
import 'charts_flutter/services/sports_api_service.dart';
import 'charts_flutter/widgets/chart_section.dart';

const String _leagueId = '4328';
const String _season = '2026-2027';

enum _StandingsFilter {
  all,
  top15,
  top10,
  top5,
}

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
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

  _StandingsFilter _selectedFilter = _StandingsFilter.all;

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
    _StandingsFilter filter,
  ) {
    final limit = switch (filter) {
      _StandingsFilter.all => data.points.length,
      _StandingsFilter.top15 => 15,
      _StandingsFilter.top10 => 10,
      _StandingsFilter.top5 => 5,
    };

    return ChartDataSet(
      title: data.title,
      xLabel: data.xLabel,
      yLabel: data.yLabel,
      points: data.points.take(limit).toList(),
    );
  }

  String _filterLabel(_StandingsFilter filter) {
    return switch (filter) {
      _StandingsFilter.all => 'TODOS',
      _StandingsFilter.top15 => 'TOP 15',
      _StandingsFilter.top10 => 'TOP 10',
      _StandingsFilter.top5 => 'TOP 5',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Premier League',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<ChartDataSet>(
          future: _standingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error al cargar los datos:\n\n'
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final standingsData = snapshot.data;

            if (standingsData == null || standingsData.points.isEmpty) {
              return const Center(
                child: Text('No se encontraron datos.'),
              );
            }

            final filteredStandings = _filteredData(
              standingsData,
              _selectedFilter,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String?>(
                  future: _leagueBadgeFuture,
                  builder: (context, snapshot) {
                    final badge = snapshot.data;

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
                  '${standingsData.points.length} equipos en la tabla general',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 16),

                _buildFilterCard(),

                const SizedBox(height: 16),

                _buildStandingsTable(standingsData),

                const SizedBox(height: 20),

                ChartSection(
                  title: 'Puntos por equipo',
                  description:
                      'Visualización de los equipos seleccionados mediante '
                      'el filtro de clasificación.',
                  chart: StandingsBarChart(
                    data: filteredStandings,
                  ),
                ),

                FutureBuilder<ChartDataSet>(
                  future: _goalsForFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const ChartSection(
                        title: 'Goles a favor',
                        description:
                            'Cargando los goles anotados por cada equipo.',
                        chart: SizedBox(
                          height: 350,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return ChartSection(
                        title: 'Goles a favor',
                        description:
                            'No fue posible cargar este gráfico.',
                        chart: Text(
                          'Error: ${snapshot.error}',
                        ),
                      );
                    }

                    final goalsData = snapshot.data;

                    if (goalsData == null || goalsData.points.isEmpty) {
                      return const ChartSection(
                        title: 'Goles a favor',
                        description:
                            'No hay datos disponibles.',
                        chart: Text(
                          'No se encontraron datos.',
                        ),
                      );
                    }

                    final filteredGoals = _filteredData(
                      goalsData,
                      _selectedFilter,
                    );

                    return ChartSection(
                      title: 'Goles a favor',
                      description:
                          'Cantidad de goles anotados por los equipos '
                          'seleccionados.',
                      chart: GoalsForColumnChart(
                        data: filteredGoals,
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

  Widget _buildFilterCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrar gráficas',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Selecciona cuántos equipos quieres visualizar.',
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _StandingsFilter.values.map((filter) {
                return ChoiceChip(
                  label: Text(_filterLabel(filter)),
                  selected: _selectedFilter == filter,
                  onSelected: (selected) {
                    if (!selected) return;

                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandingsTable(ChartDataSet data) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tabla general',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Clasificación completa de los 20 equipos.',
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(
                  Colors.grey.shade100,
                ),
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('Equipo')),
                  DataColumn(label: Text('PJ')),
                  DataColumn(label: Text('PG')),
                  DataColumn(label: Text('PE')),
                  DataColumn(label: Text('PP')),
                  DataColumn(label: Text('GF')),
                  DataColumn(label: Text('GC')),
                  DataColumn(label: Text('DG')),
                  DataColumn(label: Text('PTS')),
                ],
                rows: data.points.map((point) {
                  final meta = point.extraMetaData ?? {};
                  final badge = meta['teamBadge']?.toString();

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          _asInt(meta['position']).toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TeamBadge(
                              url: badge,
                              size: 30,
                            ),
                            const SizedBox(width: 8),
                            Text(point.label),
                          ],
                        ),
                      ),
                      DataCell(Text(_asInt(meta['played']).toString())),
                      DataCell(Text(_asInt(meta['wins']).toString())),
                      DataCell(Text(_asInt(meta['draws']).toString())),
                      DataCell(Text(_asInt(meta['losses']).toString())),
                      DataCell(Text(_asInt(meta['goalsFor']).toString())),
                      DataCell(
                        Text(_asInt(meta['goalsAgainst']).toString()),
                      ),
                      DataCell(
                        Text(_asInt(meta['goalDifference']).toString()),
                      ),
                      DataCell(
                        Text(
                          _asInt(meta['points'] ?? point.value).toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

class _TeamBadge extends StatelessWidget {
  final String? url;
  final double size;

  const _TeamBadge({
    required this.url,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: const Icon(
          Icons.shield_outlined,
          size: 20,
          color: Colors.grey,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Image.network(
        url!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.shield_outlined,
            size: 20,
            color: Colors.grey,
          );
        },
      ),
    );
  }
}
