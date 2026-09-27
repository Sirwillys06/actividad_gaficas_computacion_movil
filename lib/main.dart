import 'package:flutter/material.dart';

import 'charts_flutter/models/multi_league_dashboard_models.dart';
import 'charts_flutter/services/multi_league_api_service.dart';
import 'charts_flutter/widgets/multi_league_charts_dashboard.dart';

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
      title: 'TheSportsDB · 5 grandes ligas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        useMaterial3: true,
      ),
      home: const MultiLeagueHome(),
    );
  }
}

class MultiLeagueHome extends StatefulWidget {
  const MultiLeagueHome({super.key});

  @override
  State<MultiLeagueHome> createState() => _MultiLeagueHomeState();
}

class _MultiLeagueHomeState extends State<MultiLeagueHome> {
  final MultiLeagueApiService _apiService =
      MultiLeagueApiService();

  late Future<List<LeagueDashboardData>> _future;

  @override
  void initState() {
    super.initState();
    _future = _apiService.getAllLeagues();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LeagueDashboardData>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Cargando Premier League, La Liga, Serie A, '
                    'Bundesliga y Ligue 1...',
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'TheSportsDB · 5 grandes ligas',
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No fue posible cargar los datos.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _future =
                              _apiService.getAllLeagues();
                        });
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final data = snapshot.data ?? const [];

        if (data.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text(
                'TheSportsDB no devolvió datos para las ligas.',
              ),
            ),
          );
        }

        return MultiLeagueChartsDashboard(
          leagues: data,
        );
      },
    );
  }
}
