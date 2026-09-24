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

const _appBackground = Color(0xff0a0f1e);
const _heroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xff2d6cdf), Color(0xff8b3fd1), Color(0xffff4d8d)],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Actividad Gráficos — graphic',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff2d6cdf),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: _appBackground,
        cardTheme: const CardThemeData(elevation: 0),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
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
        final ready = snapshot.connectionState == ConnectionState.done;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: ready
              ? SportsDataScope(
                  key: const ValueKey('ready'),
                  repository: _repository,
                  child: const HomePage(),
                )
              : const _LoadingScreen(key: ValueKey('loading')),
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _heroGradient),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_graph_rounded, color: Colors.white, size: 60),
              SizedBox(height: 18),
              SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              ),
              SizedBox(height: 18),
              Text(
                'Cargando datos de TheSportsDB…',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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
        backgroundColor: _appBackground,
        appBar: AppBar(
          elevation: 0,
          centerTitle: false,
          automaticallyImplyLeading: false,
          toolbarHeight: 64,
          flexibleSpace: const DecoratedBox(decoration: BoxDecoration(gradient: _heroGradient)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Gráficos con graphic',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '· TheSportsDB',
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                labelColor: const Color(0xff2d6cdf),
                unselectedLabelColor: Colors.white,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.grid_view_rounded, size: 18),
                    text: 'Básicos (${basicEntries.length})',
                    iconMargin: const EdgeInsets.only(bottom: 2),
                    height: 44,
                  ),
                  Tab(
                    icon: const Icon(Icons.bolt_rounded, size: 18),
                    text: 'Avanzados (${advancedEntries.length})',
                    iconMargin: const EdgeInsets.only(bottom: 2),
                    height: 44,
                  ),
                ],
              ),
            ),
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
