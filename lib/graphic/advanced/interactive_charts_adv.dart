import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';
import 'package:intl/intl.dart';

import '../../models/chart_data_point.dart';
import '../../models/sports_chart_mapper.dart';
import '../../services/sports_data_scope.dart';
import '../../services/sports_repository.dart';
import '../../widgets/chart_card_wrapper.dart';
import '../../widgets/chart_entry.dart';

final _dateFormat = DateFormat('dd MMM');

/// 12 gráficos interactivos: selección, tooltip/crosshair a medida,
/// anotaciones, brushing, hover por grupo y controles Flutter que
/// re-consultan los datos de la API.
final List<ChartEntry> interactiveChartsAdvEntries = [
  ChartEntry(
    title: '56. Selector de Equipo → Rendimiento',
    description: 'Un Dropdown de Flutter recalcula la dona de G/E/P.',
    family: 'Interactivos',
    builder: (context) => const _TeamPerformanceSelector(),
  ),
  ChartEntry(
    title: '57. Comparador de Dos Equipos (Radar)',
    description: 'Elige dos equipos y compara su G/E/P en un radar.',
    family: 'Interactivos',
    builder: (context) => const _TeamComparatorRadar(),
  ),
  ChartEntry(
    title: '58. Barras Apiladas con Tooltip Anclado',
    description: 'Tooltip multi-variable fijo en la esquina inferior derecha.',
    family: 'Interactivos',
    builder: (context) {
      final ds = SportsChartMapper.standingsWinLossDrawAll(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Toca un equipo: el tooltip no sigue al dedo.',
        chart: Chart(
          data: ds.points,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
            'group': Variable(accessor: (ChartDataPoint p) => p.group ?? '—'),
          },
          marks: [
            IntervalMark(
              position: Varset('label') * Varset('value') / Varset('group'),
              color: ColorEncode(variable: 'group', values: Defaults.colors10),
              modifiers: [StackModifier()],
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          selections: {'tap': PointSelection(variable: 'label')},
          tooltip: TooltipGuide(
            multiTuples: true,
            anchor: (_) => Offset.zero,
            align: Alignment.bottomRight,
          ),
        ),
      );
    },
  ),
  ChartEntry(
    title: '59. Dispersión con Selección de Intervalo',
    description: 'Arrastra para seleccionar una región (brushing).',
    family: 'Interactivos',
    builder: (context) {
      final ds = SportsChartMapper.teamsCapacityVsYear(
        SportsDataScope.of(context).teams,
      );
      return ChartCardWrapper(
        title: 'Brushing: ${ds.title}',
        description: 'IntervalSelection sobre fundación vs capacidad.',
        chart: Chart(
          data: ds.points,
          variables: {
            'year': Variable(accessor: (ChartDataPoint p) => p.value),
            'capacity': Variable(accessor: (ChartDataPoint p) => p.secondaryValue ?? 0),
          },
          marks: [
            PointMark(
              position: Varset('year') * Varset('capacity'),
              color: ColorEncode(value: Defaults.colors10[3]),
            ),
          ],
          axes: [
            Defaults.horizontalAxis
              ..position = 0.5
              ..grid = null
              ..line = Defaults.strokeStyle,
            Defaults.verticalAxis
              ..position = 0.5
              ..grid = null
              ..line = Defaults.strokeStyle,
          ],
          coord: RectCoord(
            horizontalRange: const [0.05, 0.95],
            verticalRange: const [0.05, 0.95],
          ),
          selections: {'choose': IntervalSelection()},
          tooltip: TooltipGuide(
            anchor: (_) => Offset.zero,
            align: Alignment.bottomRight,
            multiTuples: true,
          ),
        ),
      );
    },
  ),
  ChartEntry(
    title: '60. Zona de Champions League',
    description: 'RegionAnnotation resalta el rango de puntos del Top 4.',
    family: 'Interactivos',
    builder: (context) {
      final ds = SportsChartMapper.standingsPoints(
        SportsDataScope.of(context).standings,
      );
      final sorted = ds.points.toList()..sort((a, b) => b.value.compareTo(a.value));
      final maxValue = sorted.isEmpty ? 100.0 : sorted.first.value;
      final threshold = sorted.length >= 4 ? sorted[3].value : 0.0;
      return ChartCardWrapper(
        title: 'Zona de Champions League',
        description: 'Región verde: puntaje del Top 4 en adelante.',
        chart: Chart(
          data: ds.points,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
          },
          marks: [IntervalMark(color: ColorEncode(value: Defaults.primaryColor))],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          annotations: [
            RegionAnnotation(
              dim: Dim.y,
              variable: 'value',
              values: [threshold, maxValue],
              color: const Color(0x3300c853),
            ),
          ],
        ),
      );
    },
  ),
  ChartEntry(
    title: '61. Interacción de Grupo Local/Visitante',
    description: 'Pasar el mouse sobre una serie atenúa la otra.',
    family: 'Interactivos',
    builder: (context) {
      final ds = SportsChartMapper.splitPair(
        SportsChartMapper.eventsHomeAwayScores(
          SportsDataScope.of(context).events,
        ),
      );
      return ChartCardWrapper(
        title: 'Hover por Grupo: Local vs Visitante',
        description: 'Distinta interacción para mouse y touch.',
        chart: Chart(
          data: ds.points,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
            'group': Variable(accessor: (ChartDataPoint p) => p.group ?? '—'),
          },
          marks: [
            LineMark(
              position: Varset('label') * Varset('value') / Varset('group'),
              color: ColorEncode(
                variable: 'group',
                values: Defaults.colors10,
                updaters: {
                  'groupMouse': {false: (color) => color.withAlpha(90)},
                  'groupTouch': {false: (color) => color.withAlpha(90)},
                },
              ),
            ),
            PointMark(
              color: ColorEncode(
                variable: 'group',
                values: Defaults.colors10,
                updaters: {
                  'groupMouse': {false: (color) => color.withAlpha(90)},
                  'groupTouch': {false: (color) => color.withAlpha(90)},
                },
              ),
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          selections: {
            'tooltipMouse': PointSelection(
              on: {GestureType.hover},
              devices: {PointerDeviceKind.mouse},
            ),
            'groupMouse': PointSelection(
              on: {GestureType.hover},
              variable: 'group',
              devices: {PointerDeviceKind.mouse},
            ),
            'tooltipTouch': PointSelection(
              on: {
                GestureType.scaleUpdate,
                GestureType.tapDown,
                GestureType.longPressMoveUpdate,
              },
              devices: {PointerDeviceKind.touch},
            ),
            'groupTouch': PointSelection(
              on: {
                GestureType.scaleUpdate,
                GestureType.tapDown,
                GestureType.longPressMoveUpdate,
              },
              variable: 'group',
              devices: {PointerDeviceKind.touch},
            ),
          },
          tooltip: TooltipGuide(
            selections: {'tooltipTouch', 'tooltipMouse'},
            variables: ['label', 'group', 'value'],
          ),
        ),
      );
    },
  ),
  ChartEntry(
    title: '62. Barras con Resaltado de Métrica',
    description: 'Toca una métrica para resaltarla en rojo.',
    family: 'Interactivos',
    builder: (context) {
      final ds = SportsChartMapper.eventStatsHomeAway(
        SportsDataScope.of(context).eventStats,
      );
      return ChartCardWrapper(
        title: 'Barras con Selección de Métrica',
        description: 'PointSelection con color de resalte (valor local).',
        chart: Chart(
          data: ds.points,
          variables: {
            'statLabel62': Variable(accessor: (ChartDataPoint p) => p.label),
            'statValue62': Variable(accessor: (ChartDataPoint p) => p.value),
          },
          marks: [
            IntervalMark(
              color: ColorEncode(
                value: Defaults.colors10[2],
                updaters: {
                  'tap': {true: (_) => const Color(0xffff4d4f)}
                },
              ),
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          selections: {'tap': PointSelection(variable: 'statLabel62')},
          tooltip: TooltipGuide(),
        ),
      );
    },
  ),
  ChartEntry(
    title: '63. Asistencia con Rango Horizontal',
    description: 'Pellizca o arrastra para recorrer todas las jornadas.',
    family: 'Interactivos',
    builder: (context) {
      final ds = SportsChartMapper.eventsAttendance(
        SportsDataScope.of(context).events,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'coord.horizontalRangeUpdater habilita el pan/zoom.',
        chart: Chart(
          data: ds.points,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
          },
          marks: [IntervalMark(color: ColorEncode(value: Defaults.colors10[2]))],
          coord: RectCoord(horizontalRangeUpdater: Defaults.horizontalRangeEvent),
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          tooltip: TooltipGuide(),
        ),
      );
    },
  ),
  ChartEntry(
    title: '64. Dona Interactiva con Elevación',
    description: 'La porción tocada se eleva con una sombra.',
    family: 'Interactivos',
    builder: (context) {
      final ds = SportsChartMapper.standingsWinLossDraw(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'ElevationEncode + PointSelection por porción.',
        chart: Chart(
          data: ds.points,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
          },
          transforms: [Proportion(variable: 'value', as: 'percent')],
          marks: [
            IntervalMark(
              position: Varset('percent') / Varset('label'),
              color: ColorEncode(variable: 'label', values: Defaults.colors10),
              elevation: ElevationEncode(value: 0, updaters: {
                'tap': {true: (_) => 10}
              }),
              modifiers: [StackModifier()],
            ),
          ],
          coord: PolarCoord(transposed: true, dimCount: 1, startRadius: 0.4),
          selections: {'tap': PointSelection(variable: 'label')},
        ),
      );
    },
  ),
  ChartEntry(
    title: '65. Dispersión con Etiqueta de Alerta',
    description: 'TagAnnotation marca al equipo con peor diferencia de gol.',
    family: 'Interactivos',
    builder: (context) {
      final ds = SportsChartMapper.standingsGoalsForVsAgainst(
        SportsDataScope.of(context).standings,
      );
      final worst = ds.points.isEmpty
          ? null
          : ds.points.reduce(
              (a, b) => (a.value - (a.secondaryValue ?? 0)) < (b.value - (b.secondaryValue ?? 0))
                  ? a
                  : b,
            );
      return ChartCardWrapper(
        title: ds.title,
        description: worst == null ? 'Sin datos' : 'Peor defensa: ${worst.label}.',
        chart: Chart(
          data: ds.points,
          variables: {
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
            'secondary': Variable(accessor: (ChartDataPoint p) => p.secondaryValue ?? 0),
          },
          marks: [
            PointMark(
              position: Varset('value') * Varset('secondary'),
              color: ColorEncode(value: Defaults.colors10[4]),
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          annotations: worst == null
              ? []
              : [
                  TagAnnotation(
                    label: Label(
                      'PEOR DEFENSA',
                      LabelStyle(
                        textStyle: const TextStyle(color: Color(0xffff4d4f), fontSize: 11),
                      ),
                    ),
                    values: [worst.value, worst.secondaryValue ?? 0],
                  ),
                ],
        ),
      );
    },
  ),
  ChartEntry(
    title: '66. Línea con Crosshair de Dos Estilos',
    description: 'Estilo distinto para la guía antes/después de seleccionar.',
    family: 'Interactivos',
    builder: (context) {
      final ds = SportsChartMapper.eventsAttendance(
        SportsDataScope.of(context).events,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'CrosshairGuide.styles personalizado por dimensión.',
        chart: Chart(
          data: ds.points,
          variables: {
            'time': Variable(
              accessor: (ChartDataPoint p) => p.timestamp!,
              scale: TimeScale(formatter: (t) => _dateFormat.format(t)),
            ),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
          },
          marks: [
            LineMark(
              selected: {
                'touchMove': {1}
              },
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          selections: {
            'touchMove': PointSelection(
              on: {
                GestureType.scaleUpdate,
                GestureType.tapDown,
                GestureType.longPressMoveUpdate,
              },
              dim: Dim.x,
            ),
          },
          tooltip: TooltipGuide(followPointer: [false, true]),
          crosshair: CrosshairGuide(
            followPointer: [false, true],
            styles: [
              PaintStyle(strokeColor: const Color(0xffbfbfbf)),
              PaintStyle(strokeColor: const Color(0x00bfbfbf)),
            ],
          ),
        ),
      );
    },
  ),
  ChartEntry(
    title: '67. Dashboard Interactivo por Equipo',
    description: 'Un solo selector controla la dona y la barra de goles.',
    family: 'Interactivos',
    builder: (context) => const _TeamDashboardSelector(),
  ),
];

class _TeamPerformanceSelector extends StatefulWidget {
  const _TeamPerformanceSelector();

  @override
  State<_TeamPerformanceSelector> createState() => _TeamPerformanceSelectorState();
}

class _TeamPerformanceSelectorState extends State<_TeamPerformanceSelector> {
  String? _team;

  @override
  Widget build(BuildContext context) {
    final repo = SportsDataScope.of(context);
    final teams = repo.standings.map((r) => r['strTeam'].toString()).toList();
    final selected = _team ?? (teams.isNotEmpty ? teams.first : null);
    final ds = SportsChartMapper.standingsWinLossDraw(repo.standings, teamName: selected);

    return ChartCardWrapper(
      title: ds.title,
      description: 'Elige un equipo de la tabla de posiciones.',
      chart: Column(
        children: [
          if (teams.isNotEmpty)
            DropdownButton<String>(
                    dropdownColor: Colors.white,
              value: selected,
              isExpanded: true,
              items: teams
                  .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.black87))))
                  .toList(),
              onChanged: (value) => setState(() => _team = value),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: Chart(
              data: ds.points,
              variables: {
                'label': Variable(accessor: (ChartDataPoint p) => p.label),
                'value': Variable(accessor: (ChartDataPoint p) => p.value),
              },
              transforms: [Proportion(variable: 'value', as: 'percent')],
              marks: [
                IntervalMark(
                  position: Varset('percent') / Varset('label'),
                  label: LabelEncode(
                    encoder: (tuple) => Label(tuple['value'].toString()),
                  ),
                  color: ColorEncode(variable: 'label', values: Defaults.colors10),
                  modifiers: [StackModifier()],
                ),
              ],
              coord: PolarCoord(transposed: true, dimCount: 1, startRadius: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamComparatorRadar extends StatefulWidget {
  const _TeamComparatorRadar();

  @override
  State<_TeamComparatorRadar> createState() => _TeamComparatorRadarState();
}

class _TeamComparatorRadarState extends State<_TeamComparatorRadar> {
  String? _teamA;
  String? _teamB;

  List<ChartDataPoint> _radarPoints(SportsRepository repo, String? teamA, String? teamB) {
    final points = <ChartDataPoint>[];
    for (final team in [teamA, teamB]) {
      if (team == null) continue;
      final ds = SportsChartMapper.standingsWinLossDraw(repo.standings, teamName: team);
      for (final p in ds.points) {
        points.add(ChartDataPoint(label: p.label, value: p.value, group: team));
      }
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final repo = SportsDataScope.of(context);
    final teams = repo.standings.map((r) => r['strTeam'].toString()).toList();
    final teamA = _teamA ?? (teams.isNotEmpty ? teams.first : null);
    final teamB = _teamB ?? (teams.length > 1 ? teams[1] : teamA);
    final points = _radarPoints(repo, teamA, teamB);

    return ChartCardWrapper(
      title: 'Comparador de Equipos (Barras)',
      description: 'G/E/P de dos equipos superpuestos.',
      chart: Column(
        children: [
          if (teams.length > 1)
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    dropdownColor: Colors.white,
                    value: teamA,
                    isExpanded: true,
                    items: teams
                        .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.black87))))
                        .toList(),
                    onChanged: (value) => setState(() => _teamA = value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    dropdownColor: Colors.white,
                    value: teamB,
                    isExpanded: true,
                    items: teams
                        .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.black87))))
                        .toList(),
                    onChanged: (value) => setState(() => _teamB = value),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Chart(
                    data: points.where((p) => p.group == teamA).toList(),
                    variables: {
                      'cmpLabelA78': Variable(accessor: (ChartDataPoint p) => p.label),
                      'cmpValueA78': Variable(accessor: (ChartDataPoint p) => p.value),
                    },
                    marks: [IntervalMark(color: ColorEncode(value: Defaults.colors10[0]))],
                    axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Chart(
                    data: points.where((p) => p.group == teamB).toList(),
                    variables: {
                      'cmpLabelB78': Variable(accessor: (ChartDataPoint p) => p.label),
                      'cmpValueB78': Variable(accessor: (ChartDataPoint p) => p.value),
                    },
                    marks: [IntervalMark(color: ColorEncode(value: Defaults.colors10[7]))],
                    axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamDashboardSelector extends StatefulWidget {
  const _TeamDashboardSelector();

  @override
  State<_TeamDashboardSelector> createState() => _TeamDashboardSelectorState();
}

class _TeamDashboardSelectorState extends State<_TeamDashboardSelector> {
  String? _team;

  @override
  Widget build(BuildContext context) {
    final repo = SportsDataScope.of(context);
    final teams = repo.standings.map((r) => r['strTeam'].toString()).toList();
    final selected = _team ?? (teams.isNotEmpty ? teams.first : null);
    final row = repo.standings.firstWhere(
      (r) => r['strTeam'].toString() == selected,
      orElse: () => repo.standings.isNotEmpty ? repo.standings.first : {},
    );
    final donut = SportsChartMapper.standingsWinLossDraw(repo.standings, teamName: selected);
    final goalsBar = [
      ChartDataPoint(label: 'A Favor', value: row['intGoalsFor'] == null ? 0 : double.tryParse(row['intGoalsFor'].toString()) ?? 0),
      ChartDataPoint(label: 'En Contra', value: row['intGoalsAgainst'] == null ? 0 : double.tryParse(row['intGoalsAgainst'].toString()) ?? 0),
    ];

    return ChartCardWrapper(
      title: 'Dashboard de ${selected ?? '—'}',
      description: 'Un selector, dos vistas coordinadas.',
      chart: Column(
        children: [
          if (teams.isNotEmpty)
            DropdownButton<String>(
                    dropdownColor: Colors.white,
              value: selected,
              isExpanded: true,
              items: teams
                  .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.black87))))
                  .toList(),
              onChanged: (value) => setState(() => _team = value),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Chart(
                    data: donut.points,
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
                    coord: PolarCoord(transposed: true, dimCount: 1, startRadius: 0.4),
                  ),
                ),
                Expanded(
                  child: Chart(
                    data: goalsBar,
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
          ),
        ],
      ),
    );
  }
}
