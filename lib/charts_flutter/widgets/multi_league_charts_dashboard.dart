import 'package:flutter/material.dart';
import 'package:charts_flutter_updated/charts_flutter_updated.dart'
    as charts;

import '../models/multi_league_dashboard_models.dart';

enum _DashboardChartType {
  bar,
  column,
  line,
  pie,
  grouped,
  stacked,
  scatter,
}

class _ChartDatum {
  final String label;
  final double value;
  final String? teamId;

  const _ChartDatum(
    this.label,
    this.value, {
    this.teamId,
  });
}

class _ScatterDatum {
  final double x;
  final double y;
  final String label;

  const _ScatterDatum(this.x, this.y, this.label);
}

class _ChartSeries {
  final String name;
  final List<_ChartDatum> data;

  const _ChartSeries(this.name, this.data);
}

class _ChartSpec {
  final String title;
  final String description;
  final _DashboardChartType type;
  final LeagueDashboardData league;
  final List<_ChartSeries> series;
  final List<_ScatterDatum> scatter;

  const _ChartSpec({
    required this.title,
    required this.description,
    required this.type,
    required this.league,
    this.series = const [],
    this.scatter = const [],
  });
}

class MultiLeagueChartsDashboard extends StatelessWidget {
  final MultiLeagueApiService apiService;
  final List<LeagueConfig> leagues;

  const MultiLeagueChartsDashboard({
    super.key,
    required this.apiService,
    required this.leagues,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'TheSportsDB · 5 grandes ligas',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: '40 BÁSICOS'),
              Tab(text: '40 AVANZADOS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ChartGallery(
              apiService: apiService,
              leagues: leagues,
              advanced: false,
              subtitle:
                  '8 gráficos por liga × 5 ligas = 40 gráficos básicos.',
            ),
            _ChartGallery(
              apiService: apiService,
              leagues: leagues,
              advanced: true,
              subtitle:
                  '8 gráficos avanzados por liga × 5 ligas = 40 gráficos avanzados.',
            ),
          ],
        ),
      ),
    );
  }

  List<_ChartSpec> _basicCharts(LeagueDashboardData data) {
    final teams = data.standings.toList();
    final prefix = data.league.flag + ' ' + data.league.name + ' · ';

    return [
      _metricChart(prefix + 'Puntos por equipo', 'Puntos actuales de la tabla.',
          teams.map((t) => _ChartDatum(t.team, t.points.toDouble(), teamId: t.idTeam)).toList(),
          _DashboardChartType.bar, data),
      _metricChart(prefix + 'Victorias por equipo', 'Partidos ganados.',
          teams.map((t) => _ChartDatum(t.team, t.wins.toDouble(), teamId: t.idTeam)).toList(),
          _DashboardChartType.column, data),
      _metricChart(prefix + 'Empates por equipo', 'Partidos empatados.',
          teams.map((t) => _ChartDatum(t.team, t.draws.toDouble(), teamId: t.idTeam)).toList(),
          _DashboardChartType.bar, data),
      _metricChart(prefix + 'Derrotas por equipo', 'Partidos perdidos.',
          teams.map((t) => _ChartDatum(t.team, t.losses.toDouble(), teamId: t.idTeam)).toList(),
          _DashboardChartType.column, data),
      _metricChart(prefix + 'Goles a favor', 'Producción ofensiva.',
          teams.map((t) => _ChartDatum(t.team, t.goalsFor.toDouble(), teamId: t.idTeam)).toList(),
          _DashboardChartType.bar, data),
      _metricChart(prefix + 'Goles recibidos', 'Goles encajados.',
          teams.map((t) => _ChartDatum(t.team, t.goalsAgainst.toDouble(), teamId: t.idTeam)).toList(),
          _DashboardChartType.column, data),
      _metricChart(prefix + 'Diferencia de goles', 'GF menos GC.',
          teams.map((t) => _ChartDatum(t.team, t.goalDifference.toDouble(), teamId: t.idTeam)).toList(),
          _DashboardChartType.bar, data),
      _metricChart(prefix + 'Partidos jugados', 'Cantidad de partidos registrados.',
          teams.map((t) => _ChartDatum(t.team, t.played.toDouble(), teamId: t.idTeam)).toList(),
          _DashboardChartType.column, data),
    ];
  }

  _ChartSpec _metricChart(
    String title,
    String description,
    List<_ChartDatum> data,
    _DashboardChartType type,
    LeagueDashboardData league,
  ) {
    return _ChartSpec(
      title: title,
      description: description,
      type: type,
      league: league,
      series: [_ChartSeries(title, data)],
    );
  }

  List<_ChartSpec> _advancedCharts(LeagueDashboardData data) {
    final teams = data.standings.toList();
    final prefix = data.league.flag + ' ' + data.league.name + ' · ';

    final months = <String, List<MatchEventData>>{};
    for (final event in data.events) {
      if (!event.hasScore || event.date == null) continue;
      final key = event.date!.year.toString() + '-' +
          event.date!.month.toString().padLeft(2, '0');
      months.putIfAbsent(key, () => []).add(event);
    }

    final monthKeys = months.keys.toList()..sort();

    final goalsByMonth = monthKeys.map((month) {
      return _ChartDatum(month,
          months[month]!.fold(0, (sum, event) => sum + event.totalGoals).toDouble());
    }).toList();

    final matchesByMonth = monthKeys.map((month) {
      return _ChartDatum(month, months[month]!.length.toDouble());
    }).toList();

    final homeGoals = data.events.where((event) => event.hasScore)
        .fold<int>(0, (sum, event) => sum + (event.homeScore ?? 0));
    final awayGoals = data.events.where((event) => event.hasScore)
        .fold<int>(0, (sum, event) => sum + (event.awayScore ?? 0));

    return [
      _ChartSpec(
        league: data,
        title: prefix + 'Forma W/D/L',
        description: 'Comparación apilada de victorias, empates y derrotas.',
        type: _DashboardChartType.stacked,
        series: [
          _ChartSeries('Victorias',
              teams.map((t) => _ChartDatum(t.team, t.wins.toDouble(), teamId: t.idTeam)).toList()),
          _ChartSeries('Empates',
              teams.map((t) => _ChartDatum(t.team, t.draws.toDouble(), teamId: t.idTeam)).toList()),
          _ChartSeries('Derrotas',
              teams.map((t) => _ChartDatum(t.team, t.losses.toDouble(), teamId: t.idTeam)).toList()),
        ],
      ),
      _ChartSpec(
        league: data,
        title: prefix + 'GF vs GC',
        description: 'Producción ofensiva frente a goles recibidos.',
        type: _DashboardChartType.grouped,
        series: [
          _ChartSeries('GF',
              teams.map((t) => _ChartDatum(t.team, t.goalsFor.toDouble(), teamId: t.idTeam)).toList()),
          _ChartSeries('GC',
              teams.map((t) => _ChartDatum(t.team, t.goalsAgainst.toDouble(), teamId: t.idTeam)).toList()),
        ],
      ),
      _ChartSpec(
        league: data,
        title: prefix + 'Puntos vs diferencia',
        description: 'Relación entre puntos y diferencia de goles.',
        type: _DashboardChartType.scatter,
        scatter: teams.map((t) => _ScatterDatum(
          t.goalDifference.toDouble(), t.points.toDouble(), t.team,
        )).toList(),
      ),
      _ChartSpec(
        league: data,
        title: prefix + 'Eficiencia ofensiva',
        description: 'Porcentaje de victorias frente a goles por partido.',
        type: _DashboardChartType.scatter,
        scatter: teams.map((t) => _ScatterDatum(
          t.winRate * 100, t.goalsPerMatch, t.team,
        )).toList(),
      ),
      _ChartSpec(
        league: data,
        title: prefix + 'Resultado global',
        description: 'Distribución agregada de W, D y L.',
        type: _DashboardChartType.pie,
        series: [
          _ChartSeries('Resultados', [
            _ChartDatum('Victorias',
                data.standings.fold<int>(0, (sum, t) => sum + t.wins).toDouble()),
            _ChartDatum('Empates',
                data.standings.fold<int>(0, (sum, t) => sum + t.draws).toDouble()),
            _ChartDatum('Derrotas',
                data.standings.fold<int>(0, (sum, t) => sum + t.losses).toDouble()),
          ]),
        ],
      ),
      _ChartSpec(
        league: data,
        title: prefix + 'Goles por mes',
        description: 'Goles registrados en los eventos de la temporada.',
        type: _DashboardChartType.line,
        series: [_ChartSeries('Goles', goalsByMonth)],
      ),
      _ChartSpec(
        league: data,
        title: prefix + 'Partidos por mes',
        description: 'Cantidad de partidos con evento registrado.',
        type: _DashboardChartType.line,
        series: [_ChartSeries('Partidos', matchesByMonth)],
      ),
      _ChartSpec(
        league: data,
        title: prefix + 'Local vs visitante',
        description: 'Goles acumulados según condición de local o visitante.',
        type: _DashboardChartType.grouped,
        series: [
          _ChartSeries('Goles', [
            _ChartDatum('Local', homeGoals.toDouble()),
            _ChartDatum('Visitante', awayGoals.toDouble()),
          ]),
          _ChartSeries('Promedio', [
            _ChartDatum('Local',
                data.totalMatches == 0 ? 0 : homeGoals / data.totalMatches),
            _ChartDatum('Visitante',
                data.totalMatches == 0 ? 0 : awayGoals / data.totalMatches),
          ]),
        ],
      ),
    ];
  }
}

class _ChartGallery extends StatefulWidget {
  final MultiLeagueApiService apiService;
  final List<LeagueConfig> leagues;
  final bool advanced;
  final String subtitle;

  const _ChartGallery({
    required this.apiService,
    required this.leagues,
    required this.advanced,
    required this.subtitle,
  });

  @override
  State<_ChartGallery> createState() => _ChartGalleryState();
}

class _ChartGalleryState extends State<_ChartGallery> {
  final Map<String, List<_ChartSpec>> _specCache = {};
  late final MultiLeagueChartsDashboard _builder;

  @override
  void initState() {
    super.initState();
    _builder = MultiLeagueChartsDashboard(
      apiService: widget.apiService,
      leagues: widget.leagues,
    );
  }

  List<_ChartSpec> _buildSpecs(LeagueDashboardData data) {
    final cached = _specCache[data.league.id];
    if (cached != null) return cached;

    final specs = widget.advanced
        ? _builder._advancedCharts(data)
        : _builder._basicCharts(data);

    _specCache[data.league.id] = specs;
    return specs;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1300
            ? 3
            : constraints.maxWidth >= 800
                ? 2
                : 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                widget.subtitle,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 545,
                ),
                itemCount: widget.leagues.length * 8,
                itemBuilder: (context, index) {
                  final leagueIndex = index ~/ 8;
                  final chartIndex = index % 8;

                  return _LazyChartCard(
                    key: ValueKey(
                      (widget.advanced ? 'advanced-' : 'basic-') +
                          widget.leagues[leagueIndex].id +
                          '-' +
                          chartIndex.toString(),
                    ),
                    apiService: widget.apiService,
                    league: widget.leagues[leagueIndex],
                    chartIndex: chartIndex,
                    loadSpecs: _buildSpecs,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LazyChartCard extends StatefulWidget {
  final MultiLeagueApiService apiService;
  final LeagueConfig league;
  final int chartIndex;
  final List<_ChartSpec> Function(LeagueDashboardData data) loadSpecs;

  const _LazyChartCard({
    super.key,
    required this.apiService,
    required this.league,
    required this.chartIndex,
    required this.loadSpecs,
  });

  @override
  State<_LazyChartCard> createState() => _LazyChartCardState();
}

class _LazyChartCardState extends State<_LazyChartCard> {
  late final Future<LeagueDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiService.getLeague(widget.league);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LeagueDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No fue posible cargar ' +
                      widget.league.name +
                      '.\\n' +
                      snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Card(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Cargando ' + widget.league.name + '...',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final specs = widget.loadSpecs(snapshot.data!);
        if (widget.chartIndex >= specs.length) {
          return const SizedBox.shrink();
        }

        return RepaintBoundary(
          child: _ChartCard(spec: specs[widget.chartIndex]),
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  final _ChartSpec spec;

  const _ChartCard({
    required this.spec,
  });

  static const _teamPalette = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.cyan,
    Colors.amber,
    Colors.deepOrange,
    Colors.lightBlue,
    Colors.deepPurple,
    Colors.lightGreen,
    Colors.brown,
    Colors.blueGrey,
    Colors.lime,
    Colors.deepPurpleAccent,
    Colors.redAccent,
    Colors.tealAccent,
  ];

  static const _colors = [
    Colors.blue,
    Colors.red,
    Colors.amber,
    Colors.green,
    Colors.purple,
    Colors.orange,
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spec.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              spec.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            if (spec.type != _DashboardChartType.pie)
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _teamLegend(),
                ),
              ),
            if (spec.type == _DashboardChartType.pie)
              const SizedBox(height: 40)
            else
              const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _axisInfo(),
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.touch_app_outlined,
                  size: 14,
                  color: Colors.black45,
                ),
                const SizedBox(width: 4),
                const Text(
                  'interactivo',
                  style: TextStyle(fontSize: 9, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 26,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _seriesLegend(),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 360,
              child: _buildChart(),
            ),
            const SizedBox(height: 4),
            const Text(
              'Fuente: TheSportsDB · temporada 2026-2027',
              style: TextStyle(
                fontSize: 9,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }


  String _axisInfo() {
    final title = spec.title.toLowerCase();

    if (title.contains('puntos vs diferencia')) {
      return 'X: diferencia de goles · Y: puntos';
    }
    if (title.contains('eficiencia ofensiva')) {
      return 'X: % victorias · Y: goles/partido';
    }
    if (title.contains('goles por mes')) {
      return 'X: mes · Y: goles';
    }
    if (title.contains('partidos por mes')) {
      return 'X: mes · Y: partidos';
    }
    if (title.contains('local vs visitante')) {
      return 'X: condición · Y: goles/promedio';
    }
    if (title.contains('resultado global')) {
      return 'X: resultado · Y: cantidad';
    }
    if (title.contains('forma w/d/l')) {
      return 'X: equipos · Y: partidos';
    }
    if (title.contains('goles')) {
      return 'X: equipos · Y: goles';
    }
    if (title.contains('victorias')) {
      return 'X: equipos · Y: victorias';
    }
    if (title.contains('empates')) {
      return 'X: equipos · Y: empates';
    }
    if (title.contains('derrotas')) {
      return 'X: equipos · Y: derrotas';
    }
    if (title.contains('diferencia')) {
      return 'X: equipos · Y: diferencia';
    }
    if (title.contains('partidos jugados')) {
      return 'X: equipos · Y: partidos';
    }

    return 'X: equipos · Y: puntos';
  }

  Widget _buildChart() {
    switch (spec.type) {
      case _DashboardChartType.bar:
        return charts.BarChart(
          _buildSeries(),
          animate: false,
          behaviors: _interactiveBehaviors<String>(),
          vertical: false,
          domainAxis: _teamAxis(),
          primaryMeasureAxis: _numericAxis(),
        );
      case _DashboardChartType.column:
        return charts.BarChart(
          _buildSeries(),
          animate: false,
          behaviors: _interactiveBehaviors<String>(),
          vertical: true,
          domainAxis: _teamAxis(),
          primaryMeasureAxis: _numericAxis(),
        );
      case _DashboardChartType.grouped:
        return charts.BarChart(
          _buildSeries(),
          animate: false,
          behaviors: _interactiveBehaviors<String>(),
          vertical: true,
          barGroupingType: charts.BarGroupingType.grouped,
          domainAxis: _teamAxis(),
          primaryMeasureAxis: _numericAxis(),
        );
      case _DashboardChartType.stacked:
        return charts.BarChart(
          _buildSeries(),
          animate: false,
          behaviors: _interactiveBehaviors<String>(),
          vertical: false,
          barGroupingType: charts.BarGroupingType.stacked,
          domainAxis: _teamAxis(),
          primaryMeasureAxis: _numericAxis(),
        );
      case _DashboardChartType.line:
        return charts.LineChart(
          _buildLineSeries(),
          animate: false,
          behaviors: _interactiveBehaviors<num>(),
          domainAxis: _numericAxis(),
          primaryMeasureAxis: _numericAxis(),
        );
      case _DashboardChartType.pie:
        return charts.PieChart(
          _buildSeries(),
          animate: false,
          behaviors: _interactiveBehaviors<String>(),
          defaultRenderer: charts.ArcRendererConfig<String>(
            arcWidth: 70,
            strokeWidthPx: 1,
          ),
        );
      case _DashboardChartType.scatter:
        return charts.ScatterPlotChart(
          _buildScatterSeries(),
          animate: false,
          domainAxis: _numericAxis(),
          primaryMeasureAxis: _numericAxis(),
        );
    }
  }


  charts.OrdinalAxisSpec _teamAxis() {
    return charts.OrdinalAxisSpec(
      showAxisLine: true,
      renderSpec: charts.NoneRenderSpec<String>(
        axisLineStyle: charts.LineStyleSpec(thickness: 1),
      ),
    );
  }

  charts.NumericAxisSpec _numericAxis() {
    return charts.NumericAxisSpec(
      renderSpec: charts.GridlineRendererSpec<num>(
        labelStyle: charts.TextStyleSpec(fontSize: 8),
        labelOffsetFromAxisPx: 2,
      ),
    );
  }

  List<charts.ChartBehavior<D>> _interactiveBehaviors<D>() {
    return [
      charts.SelectNearest<D>(
        eventTrigger: charts.SelectionTrigger.hover,
      ),
      charts.DomainHighlighter<D>(),
    ];
  }

  List<charts.Series<_ChartDatum, String>> _buildSeries() {
    return List.generate(spec.series.length, (index) {
      final series = spec.series[index];

      return charts.Series<_ChartDatum, String>(
        id: series.name,
        domainFn: (datum, _) => datum.label,
        measureFn: (datum, _) => datum.value,
        colorFn: (datum, _) {
          if (spec.series.length == 1 && datum.teamId != null) {
            return charts.ColorUtil.fromDartColor(_teamColor(datum.teamId!));
          }
          return charts.ColorUtil.fromDartColor(
            _colors[index % _colors.length],
          );
        },
        data: series.data,
      );
    });
  }


  List<Widget> _seriesLegend() {
    return List.generate(spec.series.length, (index) {
      final color = _colors[index % _colors.length];
      return Container(
        margin: const EdgeInsets.only(right: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              spec.series[index].name,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    });
  }

  Color _teamColor(String idTeam) {
    final index = spec.league.standings.indexWhere(
      (team) => team.idTeam == idTeam,
    );

    if (index < 0) {
      return _teamPalette[idTeam.hashCode.abs() % _teamPalette.length];
    }

    return _teamPalette[index % _teamPalette.length];
  }

  List<Widget> _teamLegend() {
    return spec.league.standings.map((team) {
      final color = _teamColor(team.idTeam);
      return Container(
        margin: const EdgeInsets.only(right: 8, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: color, width: 1.5),
              ),
              child: team.badge == null
                  ? Center(
                      child: Text(
                        _initials(team.team),
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    )
                  : ClipOval(
                      child: Image.network(
                        team.badge!,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        webHtmlElementStrategy:
                            WebHtmlElementStrategy.fallback,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.2,
                                value: progress.expectedTotalBytes == null
                                    ? null
                                    : progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) {
                          debugPrint(
                            '[Badge] Error cargando escudo | idTeam=' +
                                team.idTeam +
                                ' | equipo=' +
                                team.team,
                          );
                          return Center(
                            child: Text(
                              _initials(team.team),
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(width: 5),
            Text(
              team.team,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words.first.substring(0, words.first.length.clamp(0, 2)).toUpperCase();
    }
    return (words.first[0] + words.last[0]).toUpperCase();
  }

  List<charts.Series<_ChartDatum, num>> _buildLineSeries() {
    return List.generate(spec.series.length, (seriesIndex) {
      final series = spec.series[seriesIndex];

      return charts.Series<_ChartDatum, num>(
        id: series.name,
        domainFn: (datum, index) => index ?? 0,
        measureFn: (datum, _) => datum.value,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(
          _colors[seriesIndex % _colors.length],
        ),
        data: series.data,
      );
    });
  }

  List<charts.Series<_ScatterDatum, num>> _buildScatterSeries() {
    return [
      charts.Series<_ScatterDatum, num>(
        id: 'Relación',
        domainFn: (datum, _) => datum.x,
        measureFn: (datum, _) => datum.y,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(
          Colors.blue,
        ),
        data: spec.scatter,
      ),
    ];
  }
}
