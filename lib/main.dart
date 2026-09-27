import 'package:flutter/material.dart';

import 'charts_flutter/models/multi_league_dashboard_models.dart';
import 'charts_flutter/services/multi_league_api_service.dart';
import 'charts_flutter/theme/dashboard_theme.dart';
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
      title: 'The Sports Analytics · 5 grandes ligas',
      theme: DashboardTheme.light(),
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
  final MultiLeagueApiService _apiService = MultiLeagueApiService();

  @override
  Widget build(BuildContext context) {
    // La pantalla ya no espera a que las 5 ligas terminen de cargar.
    // Cada tarjeta solicita su liga cuando entra al viewport y el servicio
    // reutiliza el resultado en caché.
    return MultiLeagueChartsDashboard(
      apiService: _apiService,
      leagues: fiveMajorEuropeanLeagues,
    );
  }
}
