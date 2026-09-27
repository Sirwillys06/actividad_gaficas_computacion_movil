import 'package:flutter/material.dart';

import 'syncfusion_flutter_charts/core/theme/app_theme.dart';
import 'syncfusion_flutter_charts/presentation/screens/dashboard_screen.dart';

void main() {
  runApp(const SportsChartsApp());
}

class SportsChartsApp extends StatelessWidget {
  const SportsChartsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sports Analytics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const DashboardScreen(),
    );
  }
}
