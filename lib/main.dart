import 'package:flutter/material.dart';

import 'charts_flutter/services/sports_api_service.dart';
import 'charts_flutter/basic/standings_bar_chart.dart';
import 'charts_flutter/widgets/chart_section.dart';

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
      title: 'Charts Flutter',
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
  State<ChartsFlutterHome> createState() =>
      _ChartsFlutterHomeState();
}

class _ChartsFlutterHomeState extends State<ChartsFlutterHome> {
  final SportsApiService _apiService = SportsApiService();

  late Future<dynamic> _standingsFuture;

  @override
  void initState() {
    super.initState();

    _standingsFuture = _apiService.getStandingsChartData(
      leagueId: '4328',
      season: '2023-2024',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Charts Flutter',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: FutureBuilder(
          future: _standingsFuture,

          builder: (context, snapshot) {
            // Cargando
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Error
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

            // Sin datos
            final chartData = snapshot.data;

            if (chartData == null) {
              return const Center(
                child: Text(
                  'No se encontraron datos.',
                ),
              );
            }

            // Datos cargados correctamente
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                // Título de la liga
                const Text(
                  'Premier League 2023-2024',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Primer gráfico
                ChartSection(
                  title: 'Puntos por equipo',
                  description:
                      'Comparación de los puntos obtenidos '
                      'por los equipos de la Premier League.',

                  chart: StandingsBarChart(
                    data: chartData,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}