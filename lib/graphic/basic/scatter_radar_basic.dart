import 'package:flutter/widgets.dart';
import 'package:graphic/graphic.dart';

import '../../models/chart_data_point.dart';
import '../../models/sports_chart_mapper.dart';
import '../../services/sports_data_scope.dart';
import '../../widgets/chart_card_wrapper.dart';
import '../../widgets/chart_entry.dart';

/// 10 gráficos de dispersión (PointMark) y radar (LineMark en PolarCoord).
final List<ChartEntry> scatterRadarBasicEntries = [
  ChartEntry(
    title: '34. Dispersión: Goles a Favor vs En Contra',
    description: 'Un punto por equipo, coloreado por grupo.',
    family: 'Dispersión / Radar',
    builder: (context) {
      final ds = SportsChartMapper.standingsGoalsForVsAgainst(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Eje X: ${ds.xLabel} · Eje Y: ${ds.yLabel}',
        chart: Chart(
          data: ds.points,
          variables: {
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
            'secondary': Variable(accessor: (ChartDataPoint p) => p.secondaryValue ?? 0),
            'group': Variable(accessor: (ChartDataPoint p) => p.group ?? '—'),
          },
          marks: [
            PointMark(
              position: Varset('value') * Varset('secondary'),
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
    title: '35. Burbujas: Favor / Contra / Puntos',
    description: 'El tamaño de la burbuja representa los puntos.',
    family: 'Dispersión / Radar',
    builder: (context) {
      final ds = SportsChartMapper.standingsGoalsForVsAgainst(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: 'Burbujas de Goles y Puntos',
        description: 'Tamaño: puntos en la tabla.',
        chart: Chart(
          data: ds.points,
          variables: {
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
            'secondary': Variable(accessor: (ChartDataPoint p) => p.secondaryValue ?? 0),
            'points': Variable(
              accessor: (ChartDataPoint p) =>
                  (p.extraMetaData?['points'] as double?) ?? 0,
            ),
          },
          marks: [
            PointMark(
              position: Varset('value') * Varset('secondary'),
              size: SizeEncode(variable: 'points', values: const [4, 20]),
              color: ColorEncode(value: Defaults.primaryColor.withAlpha(160)),
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          tooltip: TooltipGuide(),
        ),
      );
    },
  ),
  ChartEntry(
    title: '36. Dispersión: Fundación vs Capacidad',
    description: 'search_all_teams.php → intFormedYear vs intCapacity.',
    family: 'Dispersión / Radar',
    builder: (context) {
      final ds = SportsChartMapper.teamsCapacityVsYear(
        SportsDataScope.of(context).teams,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Cada punto es un club de la liga.',
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
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          tooltip: TooltipGuide(),
        ),
      );
    },
  ),
  ChartEntry(
    title: '37. Dispersión Polar de Goles',
    description: 'Mismo dataset de goles, en coordenadas polares.',
    family: 'Dispersión / Radar',
    builder: (context) {
      final ds = SportsChartMapper.standingsGoalsForVsAgainst(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: 'Dispersión Polar de Goles',
        description: 'PointMark sobre PolarCoord.',
        chart: Chart(
          data: ds.points,
          variables: {
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
            'secondary': Variable(accessor: (ChartDataPoint p) => p.secondaryValue ?? 0),
          },
          marks: [
            PointMark(
              position: Varset('value') * Varset('secondary'),
              color: ColorEncode(value: Defaults.colors10[5]),
            ),
          ],
          coord: PolarCoord(),
          axes: [Defaults.circularAxis, Defaults.radialAxis],
        ),
      );
    },
  ),
  ChartEntry(
    title: '38. Dispersión 1D de Puntos',
    description: 'Todos los puntajes proyectados sobre un solo eje.',
    family: 'Dispersión / Radar',
    builder: (context) {
      final ds = SportsChartMapper.standingsPoints(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: 'Distribución 1D de Puntos',
        description: 'coord: RectCoord(dimCount: 1).',
        chart: Chart(
          data: ds.points,
          variables: {
            'value': Variable(
              accessor: (ChartDataPoint p) => p.value,
              scale: LinearScale(min: 0),
            ),
          },
          marks: [PointMark(position: Varset('value'))],
          axes: [Defaults.verticalAxis],
          coord: RectCoord(dimCount: 1),
        ),
      );
    },
  ),
  ChartEntry(
    title: '39. Dispersión con Selección Múltiple',
    description: 'Toca varios puntos para resaltarlos en rojo.',
    family: 'Dispersión / Radar',
    builder: (context) {
      final ds = SportsChartMapper.standingsGoalsForVsAgainst(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: 'Selección Múltiple (Toggle)',
        description: 'PointSelection(toggle: true).',
        chart: Chart(
          data: ds.points,
          variables: {
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
            'secondary': Variable(accessor: (ChartDataPoint p) => p.secondaryValue ?? 0),
          },
          marks: [
            PointMark(
              position: Varset('value') * Varset('secondary'),
              color: ColorEncode(
                value: Defaults.primaryColor,
                updaters: {
                  'choose': {true: (_) => const Color(0xffff4d4f)}
                },
              ),
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          selections: {'choose': PointSelection(toggle: true)},
          tooltip: TooltipGuide(),
        ),
      );
    },
  ),
  ChartEntry(
    title: '40. Dispersión con Zoom / Pan',
    description: 'Pellizca o arrastra para explorar el rango.',
    family: 'Dispersión / Radar',
    builder: (context) {
      final ds = SportsChartMapper.teamsCapacityVsYear(
        SportsDataScope.of(context).teams,
      );
      return ChartCardWrapper(
        title: 'Zoom / Pan: Fundación vs Capacidad',
        description: 'RectCoord con range updaters interactivos.',
        chart: Chart(
          data: ds.points,
          variables: {
            'year': Variable(accessor: (ChartDataPoint p) => p.value),
            'capacity': Variable(accessor: (ChartDataPoint p) => p.secondaryValue ?? 0),
          },
          marks: [
            PointMark(
              position: Varset('year') * Varset('capacity'),
              color: ColorEncode(value: Defaults.colors10[7]),
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          coord: RectCoord(
            horizontalRange: const [0.05, 0.95],
            verticalRange: const [0.05, 0.95],
            horizontalRangeUpdater: Defaults.horizontalRangeEvent,
            verticalRangeUpdater: Defaults.verticalRangeEvent,
          ),
        ),
      );
    },
  ),
  ChartEntry(
    title: '41. Estadísticas del Partido: Local vs Visitante',
    description: 'Comparativa Local vs Visitante en múltiples métricas.',
    family: 'Dispersión / Radar',
    builder: (context) {
      final base = SportsChartMapper.eventStatsHomeAway(
        SportsDataScope.of(context).eventStats,
      );
      final home = base.points
          .map((p) => ChartDataPoint(label: p.label, value: p.value))
          .toList();
      final away = base.points
          .map((p) => ChartDataPoint(label: p.label, value: p.secondaryValue ?? 0))
          .toList();
      return ChartCardWrapper(
        title: 'Estadísticas del Partido',
        description: 'Local (izquierda) vs Visitante (derecha), métrica por métrica.',
        chart: Row(
          children: [
            Expanded(
              child: Chart(
                data: home,
                variables: {
                  'statLabel41a': Variable(accessor: (ChartDataPoint p) => p.label),
                  'statValue41a': Variable(accessor: (ChartDataPoint p) => p.value),
                },
                marks: [IntervalMark(color: ColorEncode(value: Defaults.colors10[0]))],
                axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Chart(
                data: away,
                variables: {
                  'statLabel41b': Variable(accessor: (ChartDataPoint p) => p.label),
                  'statValue41b': Variable(accessor: (ChartDataPoint p) => p.value),
                },
                marks: [IntervalMark(color: ColorEncode(value: Defaults.colors10[7]))],
                axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
              ),
            ),
          ],
        ),
      );
    },
  ),
  ChartEntry(
    title: '42. Comparativa de Resultados por Equipo',
    description: 'G/E/P de varios equipos, uno junto a otro.',
    family: 'Dispersión / Radar',
    builder: (context) {
      final ds = SportsChartMapper.standingsWinLossDrawAll(
        SportsDataScope.of(context).standings,
        limit: 4,
      );
      final byTeam = <String, List<ChartDataPoint>>{};
      for (final p in ds.points) {
        byTeam.putIfAbsent(p.label, () => []).add(
              ChartDataPoint(label: p.group ?? '—', value: p.value),
            );
      }
      final teams = byTeam.keys.toList();
      return ChartCardWrapper(
        title: 'Comparativa de Resultados (G/E/P)',
        description: 'Un mini-gráfico por equipo: ${teams.join(', ')}.',
        chart: Row(
          children: [
            for (var i = 0; i < teams.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Chart(
                  data: byTeam[teams[i]]!,
                  variables: {
                    'resLabel42_$i': Variable(accessor: (ChartDataPoint p) => p.label),
                    'resValue42_$i': Variable(accessor: (ChartDataPoint p) => p.value),
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
    title: '43. Dispersión: Goles vs Asistencia',
    description: 'Relación entre goles anotados y público por jornada.',
    family: 'Dispersión / Radar',
    builder: (context) {
      final ds = SportsChartMapper.eventsGoalsVsAttendance(
        SportsDataScope.of(context).events,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Eje X: ${ds.xLabel} · Eje Y: ${ds.yLabel}',
        chart: Chart(
          data: ds.points,
          variables: {
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
            'secondary': Variable(accessor: (ChartDataPoint p) => p.secondaryValue ?? 0),
          },
          marks: [
            PointMark(
              position: Varset('value') * Varset('secondary'),
              color: ColorEncode(value: Defaults.colors10[9]),
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          tooltip: TooltipGuide(),
        ),
      );
    },
  ),
];
