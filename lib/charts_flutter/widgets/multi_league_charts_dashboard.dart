import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:charts_flutter_updated/charts_flutter_updated.dart'
    as charts;

import '../models/multi_league_dashboard_models.dart';
import '../services/multi_league_api_service.dart';

enum _DashboardChartType {
  bar,
  column,
  line,
  area,
  timeSeries,
  combo,
  pie,
  grouped,
  stacked,
  scatter,
}

enum _LeagueSection {
  rendimiento,
  goles,
  partidos,
  avanzados,
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

class _TimeSeriesDatum {
  final DateTime date;
  final double value;

  const _TimeSeriesDatum(this.date, this.value);
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
  final List<_TimeSeriesDatum> timeSeries;

  const _ChartSpec({
    required this.title,
    required this.description,
    required this.type,
    required this.league,
    this.series = const [],
    this.scatter = const [],
    this.timeSeries = const [],
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TheSportsDB · 5 grandes ligas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _LeagueAccordion(
        apiService: apiService,
        leagues: leagues,
        builder: this,
      ),
    );
  }

  List<_ChartSpec> _basicCharts(LeagueDashboardData data) {
    final teams = data.standings.toList();
    final prefix = data.league.flag + ' ' + data.league.name + ' · ';

    List<_ChartDatum> ranking(
      double Function(TeamStandingData team) value, {
      bool descending = true,
    }) {
      final rows = teams
          .map(
            (team) => _ChartDatum(
              team.team,
              value(team),
              teamId: team.idTeam,
            ),
          )
          .toList();
      rows.sort(
        (a, b) => descending
            ? b.value.compareTo(a.value)
            : a.value.compareTo(b.value),
      );
      return rows;
    }

    final leader = teams.isEmpty
        ? null
        : teams.reduce((a, b) => a.rank < b.rank ? a : b);

    return [
      _metricChart(
        'Puntos obtenidos por equipo · ' + data.league.name,
        'Puntos obtenidos por cada equipo durante la temporada actual.',
        ranking((team) => team.points.toDouble()),
        _DashboardChartType.bar,
        data,
      ),
      _metricChart(
        'Victorias por equipo · ' + data.league.name,
        'Comparación de partidos ganados entre los equipos de la liga.',
        ranking((team) => team.wins.toDouble()),
        _DashboardChartType.bar,
        data,
      ),
      _metricChart(
        prefix + 'Empates por equipo',
        'Comparación de partidos empatados entre los equipos de la liga.',
        ranking((team) => team.draws.toDouble()),
        _DashboardChartType.column,
        data,
      ),
      _ChartSpec(
        league: data,
        title: prefix + 'Goles a favor vs recibidos',
        description: 'Comparación directa de producción ofensiva y goles encajados.',
        type: _DashboardChartType.grouped,
        series: [
          _ChartSeries(
            'Goles a favor',
            teams.map((t) => _ChartDatum(
              t.team, t.goalsFor.toDouble(), teamId: t.idTeam,
            )).toList(),
          ),
          _ChartSeries(
            'Goles recibidos',
            teams.map((t) => _ChartDatum(
              t.team, t.goalsAgainst.toDouble(), teamId: t.idTeam,
            )).toList(),
          ),
        ],
      ),
      _ChartSpec(
        league: data,
        title: prefix + 'Balance de resultados',
        description: 'Victorias, empates y derrotas apilados por equipo.',
        type: _DashboardChartType.stacked,
        series: [
          _ChartSeries('Victorias', teams.map((t) => _ChartDatum(
            t.team, t.wins.toDouble(), teamId: t.idTeam,
          )).toList()),
          _ChartSeries('Empates', teams.map((t) => _ChartDatum(
            t.team, t.draws.toDouble(), teamId: t.idTeam,
          )).toList()),
          _ChartSeries('Derrotas', teams.map((t) => _ChartDatum(
            t.team, t.losses.toDouble(), teamId: t.idTeam,
          )).toList()),
        ],
      ),
      _ChartSpec(
        league: data,
        title: prefix + 'Resultados del líder',
        description: 'Composición de victorias, empates y derrotas del equipo líder.',
        type: _DashboardChartType.pie,
        series: [
          _ChartSeries('Resultados', [
            if (leader != null) ...[
              _ChartDatum('Victorias', leader.wins.toDouble(), teamId: leader.idTeam),
              _ChartDatum('Empates', leader.draws.toDouble(), teamId: leader.idTeam),
              _ChartDatum('Derrotas', leader.losses.toDouble(), teamId: leader.idTeam),
            ],
          ]),
        ],
      ),
      _ChartSpec(
        league: data,
        title: prefix + 'Puntos vs diferencia de goles',
        description: 'Relación entre la diferencia de goles y los puntos obtenidos.',
        type: _DashboardChartType.scatter,
        scatter: teams.map((t) => _ScatterDatum(
          t.goalDifference.toDouble(),
          t.points.toDouble(),
          t.team,
        )).toList(),
      ),
      _metricChart(
        prefix + 'Diferencia de goles',
        'GF menos GC para cada equipo.',
        ranking((team) => team.goalDifference.toDouble()),
        _DashboardChartType.column,
        data,
      ),
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
      return _ChartDatum(
        month,
        months[month]!
            .fold<int>(0, (sum, event) => sum + event.totalGoals)
            .toDouble(),
      );
    }).toList();

    final matchesByMonth = monthKeys.map((month) {
      return _ChartDatum(month, months[month]!.length.toDouble());
    }).toList();

    final goalsTimeSeries = monthKeys.map((month) {
      final parts = month.split('-');
      return _TimeSeriesDatum(
        DateTime(int.parse(parts[0]), int.parse(parts[1]), 1),
        months[month]!
            .fold<int>(0, (sum, event) => sum + event.totalGoals)
            .toDouble(),
      );
    }).toList();

    final homeGoals = data.events.where((event) => event.hasScore).fold<int>(
      0,
      (sum, event) => sum + (event.homeScore ?? 0),
    );
    final awayGoals = data.events.where((event) => event.hasScore).fold<int>(
      0,
      (sum, event) => sum + (event.awayScore ?? 0),
    );

    final leader = teams.isEmpty
        ? null
        : teams.reduce((a, b) => a.rank < b.rank ? a : b);

    return [
      _ChartSpec(
        league: data,
        title: prefix + 'Forma W/D/L',
        description: 'Comparación apilada de victorias, empates y derrotas.',
        type: _DashboardChartType.stacked,
        series: [
          _ChartSeries('Victorias', teams.map((t) => _ChartDatum(
            t.team, t.wins.toDouble(), teamId: t.idTeam,
          )).toList()),
          _ChartSeries('Empates', teams.map((t) => _ChartDatum(
            t.team, t.draws.toDouble(), teamId: t.idTeam,
          )).toList()),
          _ChartSeries('Derrotas', teams.map((t) => _ChartDatum(
            t.team, t.losses.toDouble(), teamId: t.idTeam,
          )).toList()),
        ],
      ),
      _ChartSpec(
        league: data,
        title: prefix + 'GF vs GC',
        description: 'Producción ofensiva frente a goles recibidos.',
        type: _DashboardChartType.grouped,
        series: [
          _ChartSeries('GF', teams.map((t) => _ChartDatum(
            t.team, t.goalsFor.toDouble(), teamId: t.idTeam,
          )).toList()),
          _ChartSeries('GC', teams.map((t) => _ChartDatum(
            t.team, t.goalsAgainst.toDouble(), teamId: t.idTeam,
          )).toList()),
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
        title: prefix + 'Resultado global del líder',
        description: 'Distribución W/D/L del equipo que ocupa el primer puesto.',
        type: _DashboardChartType.pie,
        series: [
          _ChartSeries('Resultados', [
            if (leader != null) ...[
              _ChartDatum('Victorias', leader.wins.toDouble(), teamId: leader.idTeam),
              _ChartDatum('Empates', leader.draws.toDouble(), teamId: leader.idTeam),
              _ChartDatum('Derrotas', leader.losses.toDouble(), teamId: leader.idTeam),
            ],
          ]),
        ],
      ),
      _ChartSpec(
        league: data,
        title: prefix + 'Goles por mes · serie temporal',
        description: 'Evolución temporal de los goles registrados por mes.',
        type: _DashboardChartType.timeSeries,
        series: [_ChartSeries('Goles', goalsByMonth)],
        timeSeries: goalsTimeSeries,
      ),
      _ChartSpec(
        league: data,
        title: prefix + 'Goles por mes · área',
        description: 'Área bajo la evolución mensual de goles registrados.',
        type: _DashboardChartType.area,
        series: [_ChartSeries('Goles', goalsByMonth)],
      ),
      _ChartSpec(
        league: data,
        title: prefix + 'Goles y partidos por mes',
        description: 'Barras de goles y línea de partidos registrados.',
        type: _DashboardChartType.combo,
        series: [
          _ChartSeries('Goles', goalsByMonth),
          _ChartSeries('Partidos', matchesByMonth),
        ],
      ),
    ];
  }
}

class _LeagueAccordion extends StatefulWidget {
  final MultiLeagueApiService apiService;
  final List<LeagueConfig> leagues;
  final MultiLeagueChartsDashboard builder;

  const _LeagueAccordion({
    required this.apiService,
    required this.leagues,
    required this.builder,
  });

  @override
  State<_LeagueAccordion> createState() => _LeagueAccordionState();
}

class _LeagueAccordionState extends State<_LeagueAccordion> {
  int _openIndex = 0;
  _LeagueSection _selectedSection = _LeagueSection.rendimiento;

  int _sectionCount(_LeagueSection section) {
    switch (section) {
      case _LeagueSection.rendimiento:
        return 4;
      case _LeagueSection.goles:
        return 3;
      case _LeagueSection.partidos:
        return 1;
      case _LeagueSection.avanzados:
        return 8;
    }
  }

  int _sectionChartIndex(_LeagueSection section, int localIndex) {
    switch (section) {
      case _LeagueSection.rendimiento:
        return localIndex;
      case _LeagueSection.goles:
        return localIndex + 4;
      case _LeagueSection.partidos:
        return 7;
      case _LeagueSection.avanzados:
        return localIndex;
    }
  }

  String _sectionTitle(_LeagueSection section) {
    switch (section) {
      case _LeagueSection.rendimiento:
        return 'Rendimiento';
      case _LeagueSection.goles:
        return 'Goles';
      case _LeagueSection.partidos:
        return 'Partidos';
      case _LeagueSection.avanzados:
        return 'Análisis avanzado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Selecciona una liga. Solo la liga abierta solicita y construye sus gráficos.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
        ),
        for (var index = 0; index < widget.leagues.length; index++) ...[
          SliverToBoxAdapter(
            child: _LeagueHeader(
              league: widget.leagues[index],
              expanded: _openIndex == index,
              onTap: () {
                setState(() {
                  if (_openIndex == index) {
                    _openIndex = -1;
                  } else {
                    _openIndex = index;
                    _selectedSection = _LeagueSection.rendimiento;
                  }
                });
              },
            ),
          ),
          if (_openIndex == index) ...[
            SliverToBoxAdapter(
              child: _LeagueSummary(
                apiService: widget.apiService,
                league: widget.leagues[index],
              ),
            ),
            SliverToBoxAdapter(
              child: _LeagueSectionNavigation(
                selected: _selectedSection,
                onSelected: (section) {
                  setState(() {
                    _selectedSection = section;
                  });
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: _sectionTitle(_selectedSection),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 560,
                  mainAxisExtent: 545,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _sectionCount(_selectedSection),
                itemBuilder: (context, localIndex) {
                  final advanced = _selectedSection == _LeagueSection.avanzados;
                  final chartIndex = _sectionChartIndex(
                    _selectedSection,
                    localIndex,
                  );

                  return _LazyChartCard(
                    key: ValueKey(
                      _selectedSection.name +
                          '-' +
                          widget.leagues[index].id +
                          '-' +
                          chartIndex.toString(),
                    ),
                    apiService: widget.apiService,
                    league: widget.leagues[index],
                    chartIndex: chartIndex,
                    advanced: advanced,
                    prototype: !advanced && chartIndex < 2,
                    loadSpecs: (data) => advanced
                        ? widget.builder._advancedCharts(data)
                        : widget.builder._basicCharts(data),
                  );
                },
              ),
            ),
          ],
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

class _LeagueHeader extends StatelessWidget {
  final LeagueConfig league;
  final bool expanded;
  final VoidCallback onTap;

  const _LeagueHeader({
    required this.league,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Material(
        color: expanded
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  league.flag,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    league.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeagueSummary extends StatelessWidget {
  final MultiLeagueApiService apiService;
  final LeagueConfig league;

  const _LeagueSummary({
    required this.apiService,
    required this.league,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LeagueDashboardData>(
      future: apiService.getLeagueData(
        league,
        includeStandings: true,
        includeEvents: false,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }

        final standings = snapshot.data!.standings;
        if (standings.isEmpty) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Datos no disponibles para construir el resumen.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          );
        }

        final leader = standings.reduce(
          (a, b) => a.points >= b.points ? a : b,
        );
        final mostGoals = standings.reduce(
          (a, b) => a.goalsFor >= b.goalsFor ? a : b,
        );
        final mostWins = standings.reduce(
          (a, b) => a.wins >= b.wins ? a : b,
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                league.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Temporada 2026-2027',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 720 ? 3 : 1;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _SummaryMetric(
                        label: 'Mayor cantidad de puntos',
                        value: leader.team,
                        detail: leader.points.toString() + ' puntos',
                        width: columns == 3
                            ? (constraints.maxWidth - 20) / 3
                            : constraints.maxWidth,
                      ),
                      _SummaryMetric(
                        label: 'Mayor cantidad de goles',
                        value: mostGoals.team,
                        detail: mostGoals.goalsFor.toString() + ' goles',
                        width: columns == 3
                            ? (constraints.maxWidth - 20) / 3
                            : constraints.maxWidth,
                      ),
                      _SummaryMetric(
                        label: 'Mayor cantidad de victorias',
                        value: mostWins.team,
                        detail: mostWins.wins.toString() + ' victorias',
                        width: columns == 3
                            ? (constraints.maxWidth - 20) / 3
                            : constraints.maxWidth,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final double width;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeagueSectionNavigation extends StatelessWidget {
  final _LeagueSection selected;
  final ValueChanged<_LeagueSection> onSelected;

  const _LeagueSectionNavigation({
    required this.selected,
    required this.onSelected,
  });

  String _label(_LeagueSection section) {
    switch (section) {
      case _LeagueSection.rendimiento:
        return 'Rendimiento';
      case _LeagueSection.goles:
        return 'Goles';
      case _LeagueSection.partidos:
        return 'Partidos';
      case _LeagueSection.avanzados:
        return 'Avanzados';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _LeagueSection.values.map((section) {
            final active = section == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_label(section)),
                selected: active,
                onSelected: (_) => onSelected(section),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LazyChartCard extends StatefulWidget {
  final MultiLeagueApiService apiService;
  final LeagueConfig league;
  final int chartIndex;
  final bool advanced;
  final bool prototype;
  final List<_ChartSpec> Function(LeagueDashboardData data) loadSpecs;

  const _LazyChartCard({
    super.key,
    required this.apiService,
    required this.league,
    required this.chartIndex,
    required this.advanced,
    this.prototype = false,
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
    _future = widget.apiService.getLeagueData(
      widget.league,
      includeStandings: !widget.advanced || widget.chartIndex < 5,
      includeEvents: widget.advanced && widget.chartIndex >= 5,
    );
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
          child: _ChartCard(
            spec: specs[widget.chartIndex],
            prototype: widget.prototype,
          ),
        );
      },
    );
  }
}

class _NumericAxisMath {
  static const int defaultDivisions = 5;

  static List<double> valuesFromData(
    Iterable<double> values, {
    int divisions = defaultDivisions,
  }) {
    final finite = values.where((value) => value.isFinite).toList();

    if (finite.isEmpty) {
      return List<double>.generate(divisions, (index) => index.toDouble());
    }

    var min = finite.reduce((a, b) => a < b ? a : b);
    var max = finite.reduce((a, b) => a > b ? a : b);

    if (min > 0) {
      min = 0;
    }
    if (max < 0) {
      max = 0;
    }

    if (min == max) {
      max = min == 0 ? 1 : min + 1;
    }

    return List<double>.generate(divisions, (index) {
      final fraction = index / (divisions - 1);
      return min + ((max - min) * fraction);
    });
  }

  static List<charts.TickSpec<num>> tickSpecs(
    Iterable<double> values, {
    int divisions = defaultDivisions,
  }) {
    return valuesFromData(values, divisions: divisions)
        .map((value) => charts.TickSpec<num>(value))
        .toList(growable: false);
  }
}

class NumericAxisLabels extends StatelessWidget {
  final double min;
  final double max;
  final int divisions;
  final Axis axis;
  final double fontSize;
  final List<double>? tickValues;

  const NumericAxisLabels({
    super.key,
    required this.min,
    required this.max,
    this.divisions = _NumericAxisMath.defaultDivisions,
    this.axis = Axis.horizontal,
    this.fontSize = 10,
    this.tickValues,
  });

  List<double> _values() {
    if (tickValues != null && tickValues!.isNotEmpty) {
      return List<double>.from(tickValues!);
    }

    return _NumericAxisMath.valuesFromData(
      <double>[min, max],
      divisions: divisions,
    );
  }

  String _format(double value) {
    if ((value - value.roundToDouble()).abs() < 0.000001) {
      return value.round().toString();
    }

    return value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final values = _values();

    if (axis == Axis.vertical) {
      return SizedBox(
        width: 34,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (var index = 0; index < values.length; index++)
                  Positioned(
                    left: 0,
                    bottom: height * (index / (values.length - 1)) - 7,
                    width: 34,
                    height: 14,
                    child: Text(
                      _format(values[index]),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: fontSize,
                        height: 1,
                        color: Colors.black54,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    return SizedBox(
      height: 18,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < values.length; index++)
                Positioned(
                  left: width * (index / (values.length - 1)) - 18,
                  top: 0,
                  width: 36,
                  height: 18,
                  child: Text(
                    _format(values[index]),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      height: 1,
                      color: Colors.black54,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ChartAxisConfig {
  static charts.NumericAxisSpec numericAxis(Iterable<double> values) {
    return charts.NumericAxisSpec(
      tickProviderSpec: charts.StaticNumericTickProviderSpec(
        _NumericAxisMath.tickSpecs(values),
      ),
      renderSpec: charts.GridlineRendererSpec<num>(
        lineStyle: const charts.LineStyleSpec(
          thickness: 1,
        ),
        labelOffsetFromAxisPx: 1,
        minimumPaddingBetweenLabelsPx: 4,
      ),
      tickFormatterSpec: charts.BasicNumericTickFormatterSpec(
        (_) => '',
      ),
    );
  }
}


class ChartTooltip extends StatelessWidget {
  final String teamName;
  final String metric;
  final String value;
  final String unit;
  final String league;
  final String season;

  const ChartTooltip({
    super.key,
    required this.teamName,
    required this.metric,
    required this.value,
    this.unit = '',
    required this.league,
    required this.season,
  });

  @override
  Widget build(BuildContext context) {
    final valueLine = unit.isEmpty
        ? metric + ': ' + value
        : metric + ': ' + value + ' ' + unit;

    return Material(
      elevation: 8,
      color: Colors.transparent,
      child: Container(
        width: 218,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(
              blurRadius: 16,
              offset: Offset(0, 6),
              color: Color(0x22000000),
            ),
          ],
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.black87),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                teamName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                valueLine,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                league,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
              Text(
                'Temporada ' + season,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TeamBarRow extends StatelessWidget {
  final TeamStandingData? team;
  final _ChartDatum datum;
  final double barLeftFraction;
  final double barWidthFraction;
  final double height;
  final double labelWidth;
  final double valueWidth;
  final Color barColor;
  final bool highlighted;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  const TeamBarRow({
    super.key,
    required this.team,
    required this.datum,
    required this.barLeftFraction,
    required this.barWidthFraction,
    required this.height,
    required this.labelWidth,
    required this.valueWidth,
    required this.barColor,
    required this.highlighted,
    required this.onEnter,
    required this.onExit,
  });

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '';
    if (words.length == 1) {
      final word = words.first;
      return word.substring(0, word.length.clamp(0, 2)).toUpperCase();
    }
    return (words.first[0] + words.last[0]).toUpperCase();
  }

  String _formatValue(double value) {
    if ((value - value.roundToDouble()).abs() < 0.000001) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final badge = team?.badge;
    final nameWidth = math.max(0.0, labelWidth - 29).toDouble();

    return SizedBox(
      height: height,
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 20,
                  child: badge == null
                      ? Center(
                          child: Text(
                            _initials(datum.label),
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: barColor,
                            ),
                          ),
                        )
                      : Image.network(
                          badge,
                          width: 22,
                          height: 18,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          webHtmlElementStrategy:
                              WebHtmlElementStrategy.fallback,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              _initials(datum.label),
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: barColor,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 5),
                SizedBox(
                  width: nameWidth,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      datum.label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight:
                            highlighted ? FontWeight.w800 : FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: SizedBox(
                height: 14,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => onEnter(),
                  onExit: (_) => onExit(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final left = (barLeftFraction.clamp(0.0, 1.0) *
                                constraints.maxWidth)
                            .toDouble();
                        final barWidth = (barWidthFraction.clamp(0.0, 1.0) *
                                constraints.maxWidth)
                            .toDouble();

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            const ColoredBox(
                              color: Color(0x0F000000),
                            ),
                            Positioned(
                              left: left,
                              top: 0,
                              bottom: 0,
                              width: barWidth,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                curve: Curves.easeOut,
                                decoration: BoxDecoration(
                                  color: highlighted
                                      ? barColor
                                      : barColor.withOpacity(0.82),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: valueWidth,
            child: Text(
              _formatValue(datum.value),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: highlighted ? FontWeight.w800 : FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrototypeTeamBarChart extends StatefulWidget {
  final _ChartSpec spec;

  const _PrototypeTeamBarChart({
    required this.spec,
  });

  @override
  State<_PrototypeTeamBarChart> createState() => _PrototypeTeamBarChartState();
}

class _PrototypeTeamBarChartState extends State<_PrototypeTeamBarChart> {
  int? _hoveredIndex;

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

  String _metric() {
    final title = widget.spec.title.toLowerCase();
    if (title.contains('victorias')) return 'Victorias';
    if (title.contains('empates')) return 'Empates';
    if (title.contains('derrotas')) return 'Derrotas';
    if (title.contains('diferencia')) return 'Diferencia de goles';
    if (title.contains('partidos jugados')) return 'Partidos jugados';
    if (title.contains('goles recibidos')) return 'Goles recibidos';
    if (title.contains('goles a favor')) return 'Goles a favor';
    if (title.contains('goles')) return 'Goles';
    return 'Puntos';
  }

  String _unit(String metric) {
    switch (metric) {
      case 'Puntos':
        return 'puntos';
      case 'Victorias':
        return 'victorias';
      case 'Empates':
        return 'empates';
      case 'Derrotas':
        return 'derrotas';
      case 'Diferencia de goles':
        return 'goles';
      case 'Partidos jugados':
        return 'partidos';
      case 'Goles recibidos':
      case 'Goles a favor':
      case 'Goles':
        return 'goles';
      default:
        return '';
    }
  }

  Color _teamColor(String idTeam) {
    final index = widget.spec.league.standings.indexWhere(
      (team) => team.idTeam == idTeam,
    );

    if (index < 0) {
      return _teamPalette[idTeam.hashCode.abs() % _teamPalette.length];
    }

    return _teamPalette[index % _teamPalette.length];
  }

  String _format(double value) {
    if ((value - value.roundToDouble()).abs() < 0.000001) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.spec.series.isEmpty
        ? const <_ChartDatum>[]
        : widget.spec.series.first.data;

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final rawMin = rows
        .map((datum) => datum.value)
        .reduce((a, b) => a < b ? a : b);
    final rawMax = rows
        .map((datum) => datum.value)
        .reduce((a, b) => a > b ? a : b);
    final axisMin = rawMin < 0 ? rawMin : 0.0;
    final axisMax = rawMax <= axisMin ? axisMin + 1.0 : rawMax;
    final axisRange = axisMax - axisMin;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final labelWidth = width < 430
            ? 116.0
            : width < 760
                ? 152.0
                : 178.0;
        final valueWidth = width < 360 ? 28.0 : 34.0;
        final chartWidth = width - labelWidth - valueWidth - 30;
        final ticks = _IntegerAxisMath.ticks(
          axisMin,
          axisMax,
          chartWidth.clamp(140.0, double.infinity).toDouble(),
        );

        const totalHeight = 360.0;
        const axisHeight = 20.0;
        final rowsHeight = totalHeight - axisHeight;
        final rowHeight = rowsHeight / rows.length;

        final hovered = _hoveredIndex == null ||
                _hoveredIndex! < 0 ||
                _hoveredIndex! >= rows.length
            ? null
            : rows[_hoveredIndex!];

        TeamStandingData? hoveredTeam;
        if (hovered?.teamId != null) {
          for (final candidate in widget.spec.league.standings) {
            if (candidate.idTeam == hovered!.teamId) {
              hoveredTeam = candidate;
              break;
            }
          }
        }

        final metric = _metric();

        return SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: labelWidth + 8,
                right: valueWidth + 8,
                top: 0,
                height: rowsHeight,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _PrototypeGridPainter(                       minValue: axisMin,
                       maxValue: axisMax,
                       ticks: ticks,
                      rowCount: rows.length,
                      rowHeight: rowHeight,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: rowsHeight,
                child: Column(
                  children: List.generate(rows.length, (index) {
                    final datum = rows[index];
                    TeamStandingData? team;

                    if (datum.teamId != null) {
                      for (final candidate in widget.spec.league.standings) {
                        if (candidate.idTeam == datum.teamId) {
                          team = candidate;
                          break;
                        }
                      }
                    }

                    return TeamBarRow(
                      team: team,
                      datum: datum,                       barLeftFraction: datum.value >= 0
                           ? (-axisMin / axisRange)
                           : ((-axisMin + datum.value) / axisRange),
                       barWidthFraction: datum.value.abs() / axisRange,
                      height: rowHeight,
                      labelWidth: labelWidth,
                      valueWidth: valueWidth,
                      barColor: datum.teamId == null
                          ? Colors.blue
                          : _teamColor(datum.teamId!),
                      highlighted: _hoveredIndex == index,
                      onEnter: () {
                        setState(() {
                          _hoveredIndex = index;
                        });
                      },
                      onExit: () {
                        setState(() {
                          _hoveredIndex = null;
                        });
                      },
                    );
                  }),
                ),
              ),
              if (hovered != null && hoveredTeam != null)
                Positioned(
                  top: ((_hoveredIndex ?? 0) * rowHeight - 8)
                      .clamp(4.0, math.max(4.0, rowsHeight - 116.0).toDouble())
                      .toDouble(),
                  left: ((hovered.value - axisMin) / axisRange) > 0.62
                      ? math.max(8.0, width - 226).toDouble()
                      : math.min(width - 226, labelWidth + 14).toDouble(),
                  child: IgnorePointer(
                    child: ChartTooltip(
                      teamName: hoveredTeam.team,
                      metric: metric,
                      value: _format(hovered.value),
                      unit: _unit(metric),
                      league: widget.spec.league.league.name,
                      season: '2026-2027',
                    ),
                  ),
                ),
              Positioned(
                left: labelWidth + 8,
                right: valueWidth + 8,
                top: rowsHeight,
                height: axisHeight,
                child: NumericAxisLabels(
                  min: axisMin,
                   max: axisMax,
                   tickValues: ticks,
                  divisions: ticks.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IntegerAxisMath {
  static List<double> ticks(double minValue, double maxValue, double width) {
    final min = minValue.isFinite ? minValue : 0.0;
    final max = maxValue.isFinite ? maxValue : 1.0;
    final safeMax = max <= min ? min + 1.0 : max;
    final range = safeMax - min;
    final targetCount = width < 220 ? 4 : width < 340 ? 5 : 6;

    if (range <= 3 &&
        min.floorToDouble() == min &&
        safeMax.ceilToDouble() == safeMax) {
      final values = <double>[];
      for (var value = min; value <= safeMax; value += 1) {
        values.add(value);
      }
      if (values.length >= 2) return values;
    }

    final rawStep = range / (targetCount - 1);
    final power = math.pow(
      10,
      (math.log(rawStep) / math.ln10).floor(),
    ).toDouble();

    const multipliers = <double>[1, 2, 3, 4, 5, 6, 8, 10];
    var step = multipliers.first * power;
    var bestDistance = double.infinity;

    for (final multiplier in multipliers) {
      final candidate = multiplier * power;
      final distance = (math.log(candidate / rawStep)).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        step = candidate;
      }
    }

    step = step < 1 ? 1 : step.roundToDouble();

    final startTick = (min / step).floor() * step;
    final endTick = (safeMax / step).ceil() * step;
    final ticks = <double>[];

    for (var value = startTick;
        value <= endTick + step * 0.001;
        value += step) {
      ticks.add(value);
    }

    if (!ticks.contains(0.0) && min <= 0 && safeMax >= 0) {
      ticks.add(0.0);
      ticks.sort();
    }

    if (ticks.length < 2) {
      ticks
        ..clear()
        ..add(min)
        ..add(safeMax);
    }

    return ticks;
  }
}

class _PrototypeGridPainter extends CustomPainter {
  final double minValue;
  final double maxValue;
  final List<double> ticks;
  final int rowCount;
  final double rowHeight;

  const _PrototypeGridPainter({
    required this.minValue,
    required this.maxValue,
    required this.ticks,
    required this.rowCount,
    required this.rowHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;

    final range = maxValue - minValue;
    if (range <= 0) return;

    for (final tick in ticks) {
      final x = ((tick - minValue) / range) * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, rowCount * rowHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PrototypeGridPainter oldDelegate) {
    return oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.ticks != ticks ||
        oldDelegate.rowCount != rowCount ||
        oldDelegate.rowHeight != rowHeight;
  }
}

class _ChartCard extends StatelessWidget {
  final _ChartSpec spec;
  final bool prototype;

  const _ChartCard({
    required this.spec,
    this.prototype = false,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    spec.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (prototype)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.bar_chart_rounded,
                      size: 18,
                      color: Colors.black45,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            const Text(
              'Temporada 2026-2027',
              style: TextStyle(
                fontSize: 10,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              spec.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _axisInfo(),
              style: const TextStyle(
                fontSize: 9,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (spec.series.length > 1) ...[
              const SizedBox(height: 4),
              SizedBox(
                height: 22,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _seriesLegend(),
                ),
              ),
            ],
            const SizedBox(height: 3),
            SizedBox(
              height: 360,
              child: _hasTeamRows()
                  ? _buildTeamChart(context)
                  : _buildChart(context),
            ),
            const SizedBox(height: 5),
            Text(
              'Fuente: TheSportsDB · Temporada 2026-2027',
              style: const TextStyle(
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
    if (title.contains('goles y partidos')) {
      return 'X: mes · Y: goles y partidos';
    }
    if (title.contains('goles por mes')) {
      return 'X: tiempo · Y: goles';
    }
    if (title.contains('resultado global')) {
      return 'X: resultado · Y: cantidad';
    }
    if (title.contains('forma w/d/l')) {
      return 'Y: Equipos · X: Partidos';
    }
    if (title.contains('goles')) {
      return 'Y: Equipos · X: Goles marcados';
    }
    if (title.contains('victorias')) {
      return 'Y: Equipos · X: Victorias';
    }
    if (title.contains('empates')) {
      return 'Y: Equipos · X: Empates';
    }
    if (title.contains('derrotas')) {
      return 'Y: Equipos · X: Derrotas';
    }
    if (title.contains('diferencia')) {
      return 'Y: Equipos · X: Diferencia de goles';
    }
    if (title.contains('partidos jugados')) {
      return 'X: equipos · Y: partidos';
    }

    return 'Y: Equipos · X: Puntos';
  }

  Widget _buildChart(BuildContext context) {
    final body = _buildChartBody();
    final measureValues = _measureValues();
    final domainValues = _domainValues();

    switch (spec.type) {
      case _DashboardChartType.bar:
      case _DashboardChartType.stacked:
        return Column(
          children: [
            Expanded(child: body),
            NumericAxisLabels(
              min: _min(measureValues),
              max: _max(measureValues),
            ),
          ],
        );
      case _DashboardChartType.column:
      case _DashboardChartType.grouped:
        return Row(
          children: [
            NumericAxisLabels(
              min: _min(measureValues),
              max: _max(measureValues),
              axis: Axis.vertical,
            ),
            Expanded(child: body),
          ],
        );
      case _DashboardChartType.line:
      case _DashboardChartType.area:
      case _DashboardChartType.scatter:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  NumericAxisLabels(
                    min: _min(measureValues),
                    max: _max(measureValues),
                    axis: Axis.vertical,
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
            NumericAxisLabels(
              min: _min(domainValues),
              max: _max(domainValues),
            ),
          ],
        );
      case _DashboardChartType.timeSeries:
        return Row(
          children: [
            NumericAxisLabels(
              min: _min(spec.timeSeries.map((datum) => datum.value)),
              max: _max(spec.timeSeries.map((datum) => datum.value)),
              axis: Axis.vertical,
            ),
            Expanded(child: body),
          ],
        );
      case _DashboardChartType.combo:
        return Row(
          children: [
            NumericAxisLabels(
              min: _min(measureValues),
              max: _max(measureValues),
              axis: Axis.vertical,
            ),
            Expanded(child: body),
          ],
        );
      case _DashboardChartType.pie:
        return body;
    }
  }

  double _min(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a < b ? a : b);
  }

  double _max(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 1;
    return list.reduce((a, b) => a > b ? a : b);
  }

  List<double> _measureValues() {
    return spec.series
        .expand((series) => series.data.map((datum) => datum.value))
        .toList(growable: false);
  }

  List<double> _domainValues() {
    if (spec.type == _DashboardChartType.scatter) {
      return spec.scatter.map((datum) => datum.x).toList(growable: false);
    }

    if (spec.type == _DashboardChartType.line ||
        spec.type == _DashboardChartType.area) {
      final count = spec.series
          .map((series) => series.data.length)
          .fold<int>(0, (current, length) => current > length ? current : length);
      if (count <= 1) return <double>[0, 1];
      return List<double>.generate(count, (index) => index.toDouble());
    }

    return const <double>[0, 1];
  }

  Widget _buildChartBody() {
    switch (spec.type) {
      case _DashboardChartType.bar:
        return charts.BarChart(
          _buildSeries(),
          animate: false,
          behaviors: _interactiveBehaviors<String>(),
          vertical: false,
          domainAxis: _teamAxis(),
          primaryMeasureAxis: _numericAxis(_measureValues()),
        );
      case _DashboardChartType.column:
        return charts.BarChart(
          _buildSeries(),
          animate: false,
          behaviors: _interactiveBehaviors<String>(),
          vertical: true,
          domainAxis: _teamAxis(),
          primaryMeasureAxis: _numericAxis(_measureValues()),
        );
      case _DashboardChartType.grouped:
        return charts.BarChart(
          _buildSeries(),
          animate: false,
          behaviors: _interactiveBehaviors<String>(),
          vertical: true,
          barGroupingType: charts.BarGroupingType.grouped,
          domainAxis: _teamAxis(),
          primaryMeasureAxis: _numericAxis(_measureValues()),
        );
      case _DashboardChartType.stacked:
        return charts.BarChart(
          _buildSeries(),
          animate: false,
          behaviors: _interactiveBehaviors<String>(),
          vertical: false,
          barGroupingType: charts.BarGroupingType.stacked,
          domainAxis: _teamAxis(),
          primaryMeasureAxis: _numericAxis(_measureValues()),
        );
      case _DashboardChartType.line:
        return charts.LineChart(
          _buildLineSeries(),
          animate: false,
          behaviors: _interactiveBehaviors<num>(),
          domainAxis: _numericAxis(_domainValues()),
          primaryMeasureAxis: _numericAxis(_measureValues()),
        );
      case _DashboardChartType.area:
        return charts.LineChart(
          _buildLineSeries(),
          animate: false,
          behaviors: _interactiveBehaviors<num>(),
          domainAxis: _numericAxis(_domainValues()),
          primaryMeasureAxis: _numericAxis(_measureValues()),
          defaultRenderer: charts.LineRendererConfig<num>(
            includePoints: true,
            includeArea: true,
            areaOpacity: 0.22,
          ),
        );
      case _DashboardChartType.timeSeries:
        return charts.TimeSeriesChart(
          _buildTimeSeries(),
          animate: false,
          behaviors: _interactiveBehaviors<DateTime>(),
          domainAxis: const charts.DateTimeAxisSpec(),
          primaryMeasureAxis: _numericAxis(
            spec.timeSeries.map((datum) => datum.value),
          ),
        );
      case _DashboardChartType.combo:
        return charts.OrdinalComboChart(
          _buildComboSeries(),
          animate: false,
          behaviors: _interactiveBehaviors<String>(),
          domainAxis: _teamAxis(),
          primaryMeasureAxis: _numericAxis(_measureValues()),
          defaultRenderer: charts.BarRendererConfig<String>(),
          customSeriesRenderers: [
            charts.LineRendererConfig<String>(
              customRendererId: 'comboLine',
              includePoints: true,
            ),
          ],
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
          domainAxis: _numericAxis(_domainValues()),
          primaryMeasureAxis: _numericAxis(_measureValues()),
        );
    }
  }


  charts.OrdinalAxisSpec _teamAxis() {
    return charts.OrdinalAxisSpec(
      showAxisLine: true,
      renderSpec: charts.SmallTickRendererSpec<String>(
        labelRotation: 45,
        labelOffsetFromAxisPx: 8,
        minimumPaddingBetweenLabelsPx: 4,
      ),
    );
  }

  charts.NumericAxisSpec _numericAxis(Iterable<double> values) {
    return _ChartAxisConfig.numericAxis(values);
  }

  bool _hasTeamRows() {
    if (spec.type != _DashboardChartType.bar &&
        spec.type != _DashboardChartType.grouped &&
        spec.type != _DashboardChartType.stacked) {
      return false;
    }

    return spec.series.any(
      (series) => series.data.any((datum) => datum.teamId != null),
    );
  }

  Widget _buildTeamChart(BuildContext context) {
    if (prototype) {
      return _PrototypeTeamBarChart(spec: spec);
    }

    return _buildChart(context);
  }

  Widget _buildLegacyTeamChart(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final rows = spec.series.isEmpty
        ? const <_ChartDatum>[]
        : spec.series.first.data;
    final showDirectValues = prototype &&
        spec.type == _DashboardChartType.bar &&
        rows.isNotEmpty;
    const chartHeight = 360.0;
    const numericAxisHeight = 18.0;
    final rowHeight = rows.isEmpty
        ? 0.0
        : (chartHeight - numericAxisHeight) / rows.length;
    final labelWidth = width < 420
        ? 118.0
        : width < 800
            ? 145.0
            : 175.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: labelWidth,
          child: Column(
            children: rows.map((datum) {
              TeamStandingData? team;
              if (datum.teamId != null) {
                for (final candidate in spec.league.standings) {
                  if (candidate.idTeam == datum.teamId) {
                    team = candidate;
                    break;
                  }
                }
              }

              return SizedBox(
                height: rowHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 18,
                      child: team?.badge == null
                          ? Center(
                              child: Text(
                                _initials(datum.label),
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                  color: datum.teamId == null
                                      ? Colors.black45
                                      : _teamColor(datum.teamId!),
                                ),
                              ),
                            )
                          : Image.network(
                              team!.badge!,
                              width: 22,
                              height: 18,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                              webHtmlElementStrategy:
                                  WebHtmlElementStrategy.fallback,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  _initials(datum.label),
                                  style: TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                    color: _teamColor(datum.teamId!),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            datum.label,
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _buildChart(context),
        ),
        if (showDirectValues) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: 38,
            child: Column(
              children: [
                ...rows.map(
                  (datum) => SizedBox(
                    height: rowHeight,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatDirectValue(datum.value),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: numericAxisHeight),
              ],
            ),
          ),
        ],
      ],
    );
  }


  String _formatDirectValue(double value) {
    if ((value - value.roundToDouble()).abs() < 0.000001) {
      return value.round().toString();
    }

    return value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
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
        colorFn: (datum, datumIndex) {
          if (spec.type == _DashboardChartType.pie) {
            return charts.ColorUtil.fromDartColor(
              _colors[(datumIndex ?? 0) % _colors.length],
            );
          }

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

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));

    if (words.isEmpty || words.first.isEmpty) {
      return '';
    }

    if (words.length == 1) {
      final word = words.first;
      return word
          .substring(0, word.length.clamp(0, 2))
          .toUpperCase();
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

  List<charts.Series<_TimeSeriesDatum, DateTime>> _buildTimeSeries() {
    return [
      charts.Series<_TimeSeriesDatum, DateTime>(
        id: 'Goles',
        domainFn: (datum, _) => datum.date,
        measureFn: (datum, _) => datum.value,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(Colors.blue),
        data: spec.timeSeries,
      ),
    ];
  }

  List<charts.Series<_ChartDatum, String>> _buildComboSeries() {
    if (spec.series.length < 2) {
      return _buildSeries();
    }

    final bars = charts.Series<_ChartDatum, String>(
      id: spec.series[0].name,
      domainFn: (datum, _) => datum.label,
      measureFn: (datum, _) => datum.value,
      colorFn: (_, __) => charts.ColorUtil.fromDartColor(Colors.blue),
      data: spec.series[0].data,
    );

    final line = charts.Series<_ChartDatum, String>(
      id: spec.series[1].name,
      domainFn: (datum, _) => datum.label,
      measureFn: (datum, _) => datum.value,
      colorFn: (_, __) => charts.ColorUtil.fromDartColor(Colors.red),
      data: spec.series[1].data,
    )..setAttribute(charts.rendererIdKey, 'comboLine');

    return [bars, line];
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
