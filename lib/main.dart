import 'package:flutter/material.dart';

import 'graphic/advanced/dashboard_stream_adv.dart';
import 'graphic/advanced/interactive_charts_adv.dart';
import 'graphic/advanced/multi_series_adv.dart';
import 'graphic/basic/bar_charts_basic.dart';
import 'graphic/basic/line_charts_basic.dart';
import 'graphic/basic/pie_charts_basic.dart';
import 'graphic/basic/scatter_radar_basic.dart';
import 'services/sports_data_scope.dart';
import 'services/sports_repository.dart';
import 'widgets/chart_entry.dart';
import 'widgets/graphic_gallery.dart';

void main() {
  runApp(const MyApp());
}

final List<ChartEntry> basicEntries = [
  ...barChartsBasicEntries,
  ...lineChartsBasicEntries,
  ...pieChartsBasicEntries,
  ...scatterRadarBasicEntries,
];

final List<ChartEntry> advancedEntries = [
  ...dashboardStreamAdvEntries,
  ...interactiveChartsAdvEntries,
  ...multiSeriesAdvEntries,
];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Actividad Gráficos — graphic',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      home: const _AppLoader(),
    );
  }
}

class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  late final SportsRepository _repository;
  late final Future<void> _loading;

  @override
  void initState() {
    super.initState();
    _repository = SportsRepository();
    _loading = _repository.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return SportsDataScope(
          repository: _repository,
          child: const HomePage(),
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gráficos con graphic — TheSportsDB'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Básicos (${basicEntries.length})'),
              Tab(text: 'Avanzados (${advancedEntries.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            GraphicGalleryPage(entries: basicEntries),
            GraphicGalleryPage(entries: advancedEntries),
          ],
        ),
      ),
    );
  }
}
