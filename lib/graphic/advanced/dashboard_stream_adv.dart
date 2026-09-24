import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';

import '../../models/chart_data_point.dart';
import '../../models/sports_chart_mapper.dart';
import '../../services/sports_data_scope.dart';
import '../../widgets/chart_card_wrapper.dart';
import '../../widgets/chart_entry.dart';

/// 12 dashboards combinados y gráficos "en vivo" (streaming simulado) con
/// `graphic`: varios marks/gráficos coordinados y `Timer` + `setState`.
final List<ChartEntry> dashboardStreamAdvEntries = [
  ChartEntry(
    title: '44. Dashboard: Puntos + Tendencia de Goles',
    description: 'Barras de puntos y línea de goles acumulados, lado a lado.',
    family: 'Dashboard',
    builder: (context) {
      final repo = SportsDataScope.of(context);
      final points = SportsChartMapper.standingsPoints(repo.standings);
      final goals = SportsChartMapper.eventsCumulativeGoals(repo.events);
      return ChartCardWrapper(
        title: 'Dashboard de Temporada',
        description: 'Dos vistas coordinadas de la misma temporada.',
        height: 320,
        chart: Row(
          children: [
            Expanded(
              child: Chart(
                data: points.points,
                variables: {
                  'label': Variable(accessor: (ChartDataPoint p) => p.label),
                  'value': Variable(accessor: (ChartDataPoint p) => p.value),
                },
                marks: [IntervalMark(color: ColorEncode(value: Defaults.primaryColor))],
                axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Chart(
                data: goals.points,
                variables: {
                  'time': Variable(accessor: (ChartDataPoint p) => p.timestamp!),
                  'value': Variable(accessor: (ChartDataPoint p) => p.value),
                },
                marks: [
                  AreaMark(color: ColorEncode(value: Defaults.colors10[1].withAlpha(90))),
                  LineMark(color: ColorEncode(value: Defaults.colors10[1])),
                ],
                axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
              ),
            ),
          ],
        ),
      );
    },
  ),
  ChartEntry(
    title: '45. Dashboard: KPIs de la Temporada',
    description: 'Tarjetas resumen + barras de los máximos anotadores.',
    family: 'Dashboard',
    builder: (context) {
      final repo = SportsDataScope.of(context);
      final goals = SportsChartMapper.eventsGoalsByRound(repo.events);
      final attendance = SportsChartMapper.eventsAttendance(repo.events);
      final totalGoals = goals.points.fold<double>(0, (a, p) => a + p.value);
      final avgAttendance = attendance.points.isEmpty
          ? 0.0
          : attendance.points.fold<double>(0, (a, p) => a + p.value) /
              attendance.points.length;
      final topScorers = SportsChartMapper.standingsGoalsForVsAgainst(repo.standings)
          .points
          .take(5)
          .toList();
      return ChartCardWrapper(
        title: 'KPIs de la Temporada',
        description: 'Resumen numérico + top 5 en goles a favor.',
        chart: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _KpiTile(label: 'Goles Totales', value: totalGoals.toStringAsFixed(0)),
                _KpiTile(label: 'Asistencia Prom.', value: avgAttendance.toStringAsFixed(0)),
                _KpiTile(label: 'Jornadas', value: goals.points.length.toString()),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Chart(
                data: topScorers,
                variables: {
                  'label': Variable(accessor: (ChartDataPoint p) => p.label),
                  'value': Variable(accessor: (ChartDataPoint p) => p.value),
                },
                marks: [
                  IntervalMark(color: ColorEncode(variable: 'label', values: Defaults.colors10)),
                ],
                axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
              ),
            ),
          ],
        ),
      );
    },
  ),
  ChartEntry(
    title: '46. Tendencia Combinada: Goles + Asistencia',
    description: 'Área de goles y línea de asistencia normalizada, superpuestas.',
    family: 'Dashboard',
    builder: (context) {
      final repo = SportsDataScope.of(context);
      final events = SportsChartMapper.eventsGoalsVsAttendance(repo.events);
      final combined = events.points
          .map((p) => ChartDataPoint(
                label: p.label,
                value: p.value,
                secondaryValue: (p.secondaryValue ?? 0) / 6000,
                timestamp: p.timestamp,
              ))
          .toList();
      return ChartCardWrapper(
        title: 'Goles (área) vs Asistencia normalizada (línea)',
        description: 'Asistencia dividida entre 6000 para compartir escala.',
        chart: Chart(
          data: combined,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'goals': Variable(accessor: (ChartDataPoint p) => p.value),
            'attendance': Variable(accessor: (ChartDataPoint p) => p.secondaryValue ?? 0),
          },
          marks: [
            AreaMark(
              position: Varset('label') * Varset('goals'),
              color: ColorEncode(value: Defaults.colors10[0].withAlpha(90)),
            ),
            LineMark(
              position: Varset('label') * Varset('attendance'),
              color: ColorEncode(value: Defaults.colors10[8]),
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
        ),
      );
    },
  ),
  ChartEntry(
    title: '47. En Vivo: Goles Simulados',
    description: 'Nueva jornada simulada cada 2 segundos (Timer + setState).',
    family: 'Dashboard',
    builder: (context) => const _LiveLineStream(),
  ),
  ChartEntry(
    title: '48. En Vivo: Medidor de Posesión Oscilante',
    description: 'El medidor oscila entre la posesión local y visitante real.',
    family: 'Dashboard',
    builder: (context) => const _LiveGauge(),
  ),
  ChartEntry(
    title: '49. Dashboard: G/E/P + Posesión',
    description: 'Barras agrupadas de resultados junto a dona de posesión.',
    family: 'Dashboard',
    builder: (context) {
      final repo = SportsDataScope.of(context);
      final wld = SportsChartMapper.standingsWinLossDrawAll(repo.standings, limit: 4);
      final possession = SportsChartMapper.eventStatsPossessionShare(repo.eventStats);
      return ChartCardWrapper(
        title: 'Resultados y Posesión',
        description: 'Dos vistas del rendimiento reciente.',
        chart: Row(
          children: [
            Expanded(
              flex: 3,
              child: Chart(
                data: wld.points,
                variables: {
                  'label': Variable(accessor: (ChartDataPoint p) => p.label),
                  'value': Variable(accessor: (ChartDataPoint p) => p.value),
                  'group': Variable(accessor: (ChartDataPoint p) => p.group ?? '—'),
                },
                marks: [
                  IntervalMark(
                    position: Varset('label') * Varset('value') / Varset('group'),
                    color: ColorEncode(variable: 'group', values: Defaults.colors10),
                    modifiers: [DodgeModifier()],
                  ),
                ],
                axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
              ),
            ),
            Expanded(
              flex: 2,
              child: Chart(
                data: possession.points,
                variables: {
                  'label': Variable(accessor: (ChartDataPoint p) => p.label),
                  'value': Variable(accessor: (ChartDataPoint p) => p.value),
                },
                transforms: [Proportion(variable: 'value', as: 'percent')],
                marks: [
                  IntervalMark(
                    position: Varset('percent') / Varset('label'),
                    color: ColorEncode(variable: 'label', values: Defaults.colors10),
                    modifiers: [StackModifier()],
                  ),
                ],
                coord: PolarCoord(transposed: true, dimCount: 1, startRadius: 0.45),
              ),
            ),
          ],
        ),
      );
    },
  ),
  ChartEntry(
    title: '50. En Vivo: Ventana Móvil de Goles',
    description: 'Muestra los últimos 6 valores, desplazándose cada 2s.',
    family: 'Dashboard',
    builder: (context) => const _LiveMovingWindowBars(),
  ),
  ChartEntry(
    title: '51. Dashboard: Estadios + Estadísticas',
    description: 'Ranking de capacidad junto al radar del partido.',
    family: 'Dashboard',
    builder: (context) {
      final repo = SportsDataScope.of(context);
      final capacity = SportsChartMapper.teamsCapacityRanking(repo.teams).points.take(6).toList();
      final radar = SportsChartMapper.splitPair(
        SportsChartMapper.eventStatsHomeAway(repo.eventStats),
      );
      return ChartCardWrapper(
        title: 'Infraestructura y Estadísticas',
        description: 'Dos dimensiones distintas de los datos deportivos.',
        chart: Row(
          children: [
            Expanded(
              child: Chart(
                data: capacity,
                variables: {
                  'label': Variable(accessor: (ChartDataPoint p) => p.label),
                  'value': Variable(accessor: (ChartDataPoint p) => p.value),
                },
                marks: [IntervalMark(color: ColorEncode(value: Defaults.colors10[6]))],
                coord: RectCoord(transposed: true),
                axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
              ),
            ),
            Expanded(
              child: Chart(
                data: radar.points,
                variables: {
                  'label': Variable(accessor: (ChartDataPoint p) => p.label),
                  'value': Variable(accessor: (ChartDataPoint p) => p.value),
                  'group': Variable(accessor: (ChartDataPoint p) => p.group ?? '—'),
                },
                marks: [
                  LineMark(
                    position: Varset('label') * Varset('value') / Varset('group'),
                    shape: ShapeEncode(value: BasicLineShape(loop: true)),
                    color: ColorEncode(variable: 'group', values: Defaults.colors10),
                  ),
                ],
                coord: PolarCoord(),
              ),
            ),
          ],
        ),
      );
    },
  ),
  ChartEntry(
    title: '52. En Vivo: Carrera de Puntos',
    description: 'Los equipos suben hacia su puntaje final con animación.',
    family: 'Dashboard',
    builder: (context) => const _LiveRaceChart(),
  ),
  ChartEntry(
    title: '53. Dashboard Multi-KPI',
    description: 'Cuatro indicadores clave de la temporada en una vista.',
    family: 'Dashboard',
    builder: (context) {
      final repo = SportsDataScope.of(context);
      final standings = SportsChartMapper.standingsPoints(repo.standings);
      final leader = standings.points.isEmpty
          ? null
          : (standings.points.toList()..sort((a, b) => b.value.compareTo(a.value))).first;
      final goals = SportsChartMapper.eventsGoalsByRound(repo.events);
      final totalGoals = goals.points.fold<double>(0, (a, p) => a + p.value);
      final avgGoals = goals.points.isEmpty ? 0.0 : totalGoals / goals.points.length;
      return ChartCardWrapper(
        title: 'Multi-KPI de la Temporada',
        description: 'Líder, goles totales, promedio y equipos.',
        height: 280,
        chart: GridView.count(
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.4,
          children: [
            _KpiTile(label: 'Líder', value: leader?.label ?? '—'),
            _KpiTile(label: 'Goles Totales', value: totalGoals.toStringAsFixed(0)),
            _KpiTile(label: 'Goles / Jornada', value: avgGoals.toStringAsFixed(1)),
            _KpiTile(label: 'Equipos', value: standings.points.length.toString()),
          ],
        ),
      );
    },
  ),
  ChartEntry(
    title: '54. En Vivo: Radar de Estadísticas',
    description: 'Pequeñas variaciones periódicas alrededor de los valores reales.',
    family: 'Dashboard',
    builder: (context) => const _LiveRadar(),
  ),
  ChartEntry(
    title: '55. Dashboard: Goles + Tendencia Acumulada',
    description: 'Pastel de distribución de goles junto a la línea acumulada.',
    family: 'Dashboard',
    builder: (context) {
      final repo = SportsDataScope.of(context);
      final goalsShare = SportsChartMapper.standingsGoalsForVsAgainst(repo.standings)
          .points
          .take(6)
          .toList();
      final cumulative = SportsChartMapper.eventsCumulativeGoals(repo.events);
      return ChartCardWrapper(
        title: 'Distribución y Tendencia de Goles',
        description: 'Vista circular + vista temporal.',
        chart: Row(
          children: [
            Expanded(
              child: Chart(
                data: goalsShare,
                variables: {
                  'label': Variable(accessor: (ChartDataPoint p) => p.label),
                  'value': Variable(accessor: (ChartDataPoint p) => p.value),
                },
                transforms: [Proportion(variable: 'value', as: 'percent')],
                marks: [
                  IntervalMark(
                    position: Varset('percent') / Varset('label'),
                    color: ColorEncode(variable: 'label', values: Defaults.colors10),
                    modifiers: [StackModifier()],
                  ),
                ],
                coord: PolarCoord(transposed: true, dimCount: 1),
              ),
            ),
            Expanded(
              child: Chart(
                data: cumulative.points,
                variables: {
                  'time': Variable(accessor: (ChartDataPoint p) => p.timestamp!),
                  'value': Variable(accessor: (ChartDataPoint p) => p.value),
                },
                marks: [LineMark(color: ColorEncode(value: Defaults.colors10[4]))],
                axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
              ),
            ),
          ],
        ),
      );
    },
  ),
];

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  const _KpiTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _LiveLineStream extends StatefulWidget {
  const _LiveLineStream();

  @override
  State<_LiveLineStream> createState() => _LiveLineStreamState();
}

class _LiveLineStreamState extends State<_LiveLineStream> {
  final _rnd = Random();
  final List<ChartDataPoint> _data = [];
  Timer? _timer;
  int _round = 0;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 6; i++) {
      _addPoint();
    }
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _addPoint());
  }

  void _addPoint() {
    _round++;
    final value = (2 + _rnd.nextInt(5)).toDouble();
    setState(() {
      _data.add(ChartDataPoint(label: 'J$_round', value: value));
      if (_data.length > 12) _data.removeAt(0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartCardWrapper(
      title: 'Goles Simulados en Vivo',
      description: 'Jornada actual: J$_round · se actualiza cada 2s.',
      chart: Chart(
        data: List.of(_data),
        variables: {
          'label': Variable(accessor: (ChartDataPoint p) => p.label),
          'value': Variable(accessor: (ChartDataPoint p) => p.value),
        },
        marks: [
          LineMark(
            shape: ShapeEncode(value: BasicLineShape(smooth: true)),
            color: ColorEncode(value: Defaults.colors10[2]),
          ),
          PointMark(color: ColorEncode(value: Defaults.colors10[2])),
        ],
        axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      ),
    );
  }
}

class _LiveGauge extends StatefulWidget {
  const _LiveGauge();

  @override
  State<_LiveGauge> createState() => _LiveGaugeState();
}

class _LiveGaugeState extends State<_LiveGauge> {
  Timer? _timer;
  double _home = 50;
  double _away = 50;
  bool _towardHome = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      setState(() {
        final step = 3.0;
        if (_towardHome) {
          _home = (_home + step).clamp(0, 100);
        } else {
          _home = (_home - step).clamp(0, 100);
        }
        if (_home >= 68 || _home <= 32) _towardHome = !_towardHome;
        _away = 100 - _home;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = [
      {'type': '100_percent', 'percent': 100.0},
      {'type': 'actual', 'percent': _home},
    ];
    return ChartCardWrapper(
      title: 'Posesión en Vivo (simulada)',
      description: 'Local ${_home.toStringAsFixed(0)}% · Visitante ${_away.toStringAsFixed(0)}%',
      chart: Chart(
        data: data,
        variables: {
          'type': Variable(accessor: (Map map) => map['type'] as String),
          'percent': Variable(
            accessor: (Map map) => map['percent'] as num,
            scale: LinearScale(min: 0, max: 100),
          ),
        },
        marks: [
          IntervalMark(
            shape: ShapeEncode(
              value: RectShape(borderRadius: const BorderRadius.all(Radius.circular(8))),
            ),
            color: ColorEncode(variable: 'type', values: Defaults.colors10),
          ),
        ],
        coord: PolarCoord(
          transposed: true,
          startAngle: 2.5,
          endAngle: 6.93,
          startRadius: 0.9,
          endRadius: 0.9,
        ),
      ),
    );
  }
}

class _LiveMovingWindowBars extends StatefulWidget {
  const _LiveMovingWindowBars();

  @override
  State<_LiveMovingWindowBars> createState() => _LiveMovingWindowBarsState();
}

class _LiveMovingWindowBarsState extends State<_LiveMovingWindowBars> {
  Timer? _timer;
  List<ChartDataPoint> _base = const [];
  int _offset = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_base.isEmpty) {
      final repo = SportsDataScope.of(context);
      _base = SportsChartMapper.eventsGoalsByRound(repo.events).points;
      _timer = Timer.periodic(const Duration(seconds: 2), (_) {
        setState(() => _offset = (_offset + 1) % max(1, _base.length));
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_base.isEmpty) return const SizedBox.shrink();
    final window = <ChartDataPoint>[];
    for (var i = 0; i < min(6, _base.length); i++) {
      window.add(_base[(_offset + i) % _base.length]);
    }
    return ChartCardWrapper(
      title: 'Ventana Móvil de Goles por Jornada',
      description: 'Desplaza 6 jornadas reales cada 2 segundos.',
      chart: Chart(
        data: window,
        variables: {
          'label': Variable(accessor: (ChartDataPoint p) => p.label),
          'value': Variable(accessor: (ChartDataPoint p) => p.value),
        },
        marks: [IntervalMark(color: ColorEncode(value: Defaults.colors10[5]))],
        axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      ),
    );
  }
}

class _LiveRaceChart extends StatefulWidget {
  const _LiveRaceChart();

  @override
  State<_LiveRaceChart> createState() => _LiveRaceChartState();
}

class _LiveRaceChartState extends State<_LiveRaceChart> {
  Timer? _timer;
  List<ChartDataPoint> _targets = const [];
  final Map<String, double> _current = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_targets.isEmpty) {
      final repo = SportsDataScope.of(context);
      _targets = SportsChartMapper.standingsPoints(repo.standings).points.take(6).toList();
      for (final p in _targets) {
        _current[p.label] = 0;
      }
      _timer = Timer.periodic(const Duration(milliseconds: 600), (_) {
        setState(() {
          var allDone = true;
          for (final p in _targets) {
            final cur = _current[p.label] ?? 0;
            if (cur < p.value) {
              _current[p.label] = min(p.value, cur + p.value / 10);
              allDone = false;
            }
          }
          if (allDone) _timer?.cancel();
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_targets.isEmpty) return const SizedBox.shrink();
    final data = _targets
        .map((p) => ChartDataPoint(label: p.label, value: _current[p.label] ?? 0))
        .toList();
    return ChartCardWrapper(
      title: 'Carrera de Puntos en Vivo',
      description: 'Cada equipo sube hasta su puntaje final real.',
      chart: Chart(
        data: data,
        variables: {
          'label': Variable(accessor: (ChartDataPoint p) => p.label),
          'value': Variable(
            accessor: (ChartDataPoint p) => p.value,
            scale: LinearScale(min: 0),
          ),
        },
        marks: [
          IntervalMark(
            label: LabelEncode(encoder: (tuple) => Label(tuple['value'].toStringAsFixed(0))),
            color: ColorEncode(variable: 'label', values: Defaults.colors10),
          ),
        ],
        coord: PolarCoord(transposed: true),
        axes: [Defaults.radialAxis..label = null, Defaults.circularAxis],
      ),
    );
  }
}

class _LiveRadar extends StatefulWidget {
  const _LiveRadar();

  @override
  State<_LiveRadar> createState() => _LiveRadarState();
}

class _LiveRadarState extends State<_LiveRadar> {
  final _rnd = Random();
  Timer? _timer;
  List<ChartDataPoint> _base = const [];
  int _tick = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_base.isEmpty) {
      final repo = SportsDataScope.of(context);
      _base = SportsChartMapper.splitPair(
        SportsChartMapper.eventStatsHomeAway(repo.eventStats),
      ).points;
      _timer = Timer.periodic(const Duration(seconds: 2), (_) {
        setState(() => _tick++);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_base.isEmpty) return const SizedBox.shrink();
    final jittered = _base
        .map((p) => ChartDataPoint(
              label: p.label,
              value: max(0, p.value + _rnd.nextInt(5) - 2),
              group: p.group,
            ))
        .toList();
    return ChartCardWrapper(
      title: 'Radar en Vivo de Estadísticas (tick $_tick)',
      description: 'Pequeño ruido aleatorio sobre los valores reales.',
      chart: Chart(
        data: jittered,
        variables: {
          'label': Variable(accessor: (ChartDataPoint p) => p.label),
          'value': Variable(accessor: (ChartDataPoint p) => p.value),
          'group': Variable(accessor: (ChartDataPoint p) => p.group ?? '—'),
        },
        marks: [
          LineMark(
            position: Varset('label') * Varset('value') / Varset('group'),
            shape: ShapeEncode(value: BasicLineShape(loop: true)),
            color: ColorEncode(variable: 'group', values: Defaults.colors10),
          ),
        ],
        coord: PolarCoord(),
      ),
    );
  }
}
