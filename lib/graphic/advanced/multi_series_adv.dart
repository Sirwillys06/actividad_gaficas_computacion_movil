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

/// 12 gráficos de series múltiples: varias líneas/barras/áreas compartiendo
/// ejes, comparaciones entre equipos y un explorador interactivo de métricas.
final List<ChartEntry> multiSeriesAdvEntries = [
  ChartEntry(
    title: '68. Multi-línea: Local, Visitante y Total',
    description: 'Tres series de goles superpuestas por jornada.',
    family: 'Series Múltiples',
    builder: (context) {
      final repo = SportsDataScope.of(context);
      final pair = SportsChartMapper.splitPair(
        SportsChartMapper.eventsHomeAwayScores(repo.events),
      );
      final total = SportsChartMapper.eventsGoalsByRound(repo.events)
          .points
          .map((p) => ChartDataPoint(label: p.label, value: p.value, group: 'Total'))
          .toList();
      final combined = [...pair.points, ...total];
      return ChartCardWrapper(
        title: 'Local, Visitante y Total de Goles',
        description: 'Tres grupos nesteados con la misma escala.',
        chart: Chart(
          data: combined,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
            'group': Variable(accessor: (ChartDataPoint p) => p.group ?? '—'),
          },
          marks: [
            LineMark(
              position: Varset('label') * Varset('value') / Varset('group'),
              color: ColorEncode(variable: 'group', values: Defaults.colors10),
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          tooltip: TooltipGuide(multiTuples: true),
        ),
      );
    },
  ),
  ChartEntry(
    title: '69. Barras Agrupadas: Puntos vs Goles a Favor',
    description: 'Dos métricas del mismo equipo, lado a lado.',
    family: 'Series Múltiples',
    builder: (context) {
      final base = SportsChartMapper.standingsPointsAndGoals(
        SportsDataScope.of(context).standings,
      );
      final ds = SportsChartMapper.splitPair(
        base,
        firstGroup: 'Puntos',
        secondGroup: 'Goles a Favor',
      );
      return ChartCardWrapper(
        title: base.title,
        description: 'DodgeModifier separa ambas métricas por equipo.',
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
              modifiers: [DodgeModifier()],
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          tooltip: TooltipGuide(multiTuples: true),
        ),
      );
    },
  ),
  ChartEntry(
    title: '70. Río de G/E/P (Top 6 Equipos)',
    description: 'AreaMark apilada y simétrica por resultado.',
    family: 'Series Múltiples',
    builder: (context) {
      final ds = SportsChartMapper.standingsWinLossDrawAll(
        SportsDataScope.of(context).standings,
        limit: 6,
      );
      return ChartCardWrapper(
        title: 'Río de Ganados/Empatados/Perdidos',
        description: 'Misma data que un stacked bar, en forma de río.',
        chart: Chart(
          data: ds.points,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
            'group': Variable(accessor: (ChartDataPoint p) => p.group ?? '—'),
          },
          marks: [
            AreaMark(
              position: Varset('label') * Varset('value') / Varset('group'),
              shape: ShapeEncode(value: BasicAreaShape(smooth: true)),
              color: ColorEncode(variable: 'group', values: Defaults.colors10),
              modifiers: [StackModifier(), SymmetricModifier()],
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          tooltip: TooltipGuide(multiTuples: true),
        ),
      );
    },
  ),
  ChartEntry(
    title: '71. Barras Multi-métrica de Perfil (Top 3)',
    description: 'Puntos, goles y ganados normalizados de 0 a 1.',
    family: 'Series Múltiples',
    builder: (context) {
      final ds = SportsChartMapper.standingsMultiMetricRadar(
        SportsDataScope.of(context).standings,
        limit: 3,
      );
      final byTeam = <String, List<ChartDataPoint>>{};
      for (final p in ds.points) {
        byTeam.putIfAbsent(p.group ?? '—', () => []).add(
              ChartDataPoint(label: p.label, value: p.value),
            );
      }
      final teams = byTeam.keys.toList();
      return ChartCardWrapper(
        title: ds.title,
        description: 'Todas las métricas comparten la misma escala 0-1.',
        chart: Row(
          children: [
            for (var i = 0; i < teams.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Chart(
                  data: byTeam[teams[i]]!,
                  variables: {
                    'profLabel71_$i': Variable(accessor: (ChartDataPoint p) => p.label),
                    'profValue71_$i': Variable(accessor: (ChartDataPoint p) => p.value),
                  },
                  marks: [
                    IntervalMark(
                      color: ColorEncode(value: Defaults.colors10[i % Defaults.colors10.length]),
                    ),
                  ],
                  axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
                ),
              ),
            ],
          ],
        ),
      );
    },
  ),
  ChartEntry(
    title: '72. Barras Apiladas: Goles Local/Visitante',
    description: 'Cada jornada apila el aporte de local y visitante.',
    family: 'Series Múltiples',
    builder: (context) {
      final base = SportsChartMapper.eventsHomeAwayScores(
        SportsDataScope.of(context).events,
      );
      final ds = SportsChartMapper.splitPair(base);
      return ChartCardWrapper(
        title: base.title,
        description: 'StackModifier en formato de barras (vs. líneas).',
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
          tooltip: TooltipGuide(multiTuples: true),
        ),
      );
    },
  ),
  ChartEntry(
    title: '73. Dispersión Multi-grupo por País',
    description: 'Fundación vs capacidad, coloreado por país del club.',
    family: 'Series Múltiples',
    builder: (context) {
      final ds = SportsChartMapper.teamsCapacityVsYear(
        SportsDataScope.of(context).teams,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Color por grupo/país (strCountry).',
        chart: Chart(
          data: ds.points,
          variables: {
            'year': Variable(accessor: (ChartDataPoint p) => p.value),
            'capacity': Variable(accessor: (ChartDataPoint p) => p.secondaryValue ?? 0),
            'group': Variable(accessor: (ChartDataPoint p) => p.group ?? '—'),
          },
          marks: [
            PointMark(
              position: Varset('year') * Varset('capacity'),
              color: ColorEncode(variable: 'group', values: Defaults.colors10),
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          tooltip: TooltipGuide(),
        ),
      );
    },
  ),
  ChartEntry(
    title: '74. Explorador Multi-serie de Métricas',
    description: 'Elige qué métrica de la tabla graficar como barras.',
    family: 'Series Múltiples',
    builder: (context) => const _MetricExplorer(),
  ),
  ChartEntry(
    title: '75. Barras Agrupadas de G/E/P (Top 3)',
    description: 'Comparación directa entre los 3 primeros equipos.',
    family: 'Series Múltiples',
    builder: (context) {
      final ds = SportsChartMapper.standingsWinLossDrawAll(
        SportsDataScope.of(context).standings,
        limit: 3,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'DodgeModifier, transposedas horizontalmente.',
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
              modifiers: [DodgeModifier()],
            ),
          ],
          coord: RectCoord(transposed: true),
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
        ),
      );
    },
  ),
  ChartEntry(
    title: '76. Río Multi-área: Goles y Asistencia',
    description: 'Dos métricas normalizadas como área simétrica apilada.',
    family: 'Series Múltiples',
    builder: (context) {
      final ge = SportsChartMapper.eventsGoalsVsAttendance(
        SportsDataScope.of(context).events,
      );
      final points = <ChartDataPoint>[];
      for (final p in ge.points) {
        points.add(ChartDataPoint(label: p.label, value: p.value, group: 'Goles'));
        points.add(ChartDataPoint(
          label: p.label,
          value: (p.secondaryValue ?? 0) / 6000,
          group: 'Asistencia (÷6000)',
        ));
      }
      return ChartCardWrapper(
        title: 'Río de Goles y Asistencia Normalizada',
        description: 'Ambas métricas comparten escala aproximada.',
        chart: Chart(
          data: points,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
            'group': Variable(accessor: (ChartDataPoint p) => p.group ?? '—'),
          },
          marks: [
            AreaMark(
              position: Varset('label') * Varset('value') / Varset('group'),
              shape: ShapeEncode(value: BasicAreaShape(smooth: true)),
              color: ColorEncode(variable: 'group', values: Defaults.colors10),
              modifiers: [StackModifier(), SymmetricModifier()],
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          tooltip: TooltipGuide(multiTuples: true),
        ),
      );
    },
  ),
  ChartEntry(
    title: '77. Goles Acumulados: Local vs Visitante',
    description: 'Dos tendencias acumuladas independientes por jornada.',
    family: 'Series Múltiples',
    builder: (context) {
      final ds = SportsChartMapper.eventsCumulativeHomeAway(
        SportsDataScope.of(context).events,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Compara qué tan rápido acumula goles cada condición.',
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
              color: ColorEncode(variable: 'group', values: Defaults.colors10),
              size: SizeEncode(value: 0.8),
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          tooltip: TooltipGuide(multiTuples: true),
          crosshair: CrosshairGuide(),
        ),
      );
    },
  ),
  ChartEntry(
    title: '78. Comparador Multi-serie: 4 Equipos',
    description: 'Puntos, goles a favor y en contra de 4 equipos.',
    family: 'Series Múltiples',
    builder: (context) {
      final repo = SportsDataScope.of(context);
      final rows = repo.standings.take(4).toList();
      final points = <ChartDataPoint>[];
      for (final r in rows) {
        final team = r['strTeam'].toString();
        points.add(ChartDataPoint(label: 'Puntos', value: r['intPoints'].toString().isEmpty ? 0 : double.tryParse(r['intPoints'].toString()) ?? 0, group: team));
        points.add(ChartDataPoint(label: 'Goles a Favor', value: double.tryParse(r['intGoalsFor'].toString()) ?? 0, group: team));
        points.add(ChartDataPoint(label: 'Goles en Contra', value: double.tryParse(r['intGoalsAgainst'].toString()) ?? 0, group: team));
      }
      final data = points.isEmpty
          ? SportsChartMapper.standingsMultiMetricRadar(repo.standings).points
          : points;
      return ChartCardWrapper(
        title: 'Comparador Multi-serie: 4 Equipos',
        description: 'Barras agrupadas por métrica y por equipo.',
        chart: Chart(
          data: data,
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
          tooltip: TooltipGuide(multiTuples: true),
        ),
      );
    },
  ),
  ChartEntry(
    title: '79. Panel Final: Barra + Línea + Radar',
    description: 'Tres tipos de gráfico, tres series, un solo panel.',
    family: 'Series Múltiples',
    builder: (context) {
      final repo = SportsDataScope.of(context);
      final points = SportsChartMapper.standingsPoints(repo.standings);
      final cumulative = SportsChartMapper.eventsCumulativeGoals(repo.events);
      final stats = SportsChartMapper.eventStatsHomeAway(repo.eventStats).points;
      return ChartCardWrapper(
        title: 'Panel de Cierre de Temporada',
        description: 'Puntos, tendencia de goles y estadísticas del partido.',
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
            Expanded(
              child: Chart(
                data: cumulative.points,
                variables: {
                  'time': Variable(
                    accessor: (ChartDataPoint p) => p.timestamp!,
                    scale: TimeScale(formatter: (t) => _dateFormat.format(t)),
                  ),
                  'value': Variable(accessor: (ChartDataPoint p) => p.value),
                },
                marks: [LineMark(color: ColorEncode(value: Defaults.colors10[1]))],
                axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
              ),
            ),
            Expanded(
              child: Chart(
                data: stats,
                variables: {
                  'statLabel79': Variable(accessor: (ChartDataPoint p) => p.label),
                  'statValue79': Variable(accessor: (ChartDataPoint p) => p.value),
                },
                marks: [
                  IntervalMark(color: ColorEncode(value: Defaults.colors10[3])),
                ],
                axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
              ),
            ),
          ],
        ),
      );
    },
  ),
];

class _MetricExplorer extends StatefulWidget {
  const _MetricExplorer();

  @override
  State<_MetricExplorer> createState() => _MetricExplorerState();
}

const _metricFields = {
  'Puntos': 'intPoints',
  'Goles a Favor': 'intGoalsFor',
  'Goles en Contra': 'intGoalsAgainst',
  'Ganados': 'intWin',
  'Perdidos': 'intLoss',
};

class _MetricExplorerState extends State<_MetricExplorer> {
  String _metric = 'Puntos';

  List<ChartDataPoint> _points(SportsRepository repo) {
    final field = _metricFields[_metric]!;
    return repo.standings
        .map((r) => ChartDataPoint(
              label: r['strTeam'].toString(),
              value: double.tryParse(r[field].toString().replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final repo = SportsDataScope.of(context);
    final points = _points(repo);
    return ChartCardWrapper(
      title: 'Explorador de Métricas: $_metric',
      description: 'Cambia la métrica y las barras se recalculan al instante.',
      chart: Column(
        children: [
          Wrap(
            spacing: 8,
            children: _metricFields.keys
                .map((m) => ChoiceChip(
                      label: Text(m),
                      selected: _metric == m,
                      onSelected: (_) => setState(() => _metric = m),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Chart(
              data: points,
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
  }
}
