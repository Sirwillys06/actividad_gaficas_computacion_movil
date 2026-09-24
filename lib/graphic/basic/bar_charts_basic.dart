import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';

import '../../models/chart_data_point.dart';
import '../../models/sports_chart_mapper.dart';
import '../../services/sports_data_scope.dart';
import '../../widgets/chart_card_wrapper.dart';
import '../../widgets/chart_entry.dart';

/// 12 gráficos de barras (IntervalMark) sobre datos reales/mock de la API.
final List<ChartEntry> barChartsBasicEntries = [
  ChartEntry(
    title: '1. Puntos por Equipo',
    description: 'Barras verticales — lookuptable.php → intPoints por strTeam.',
    family: 'Barras',
    builder: (context) {
      final ds = SportsChartMapper.standingsPoints(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Eje X: ${ds.xLabel} · Eje Y: ${ds.yLabel}',
        chart: Chart(
          data: ds.points,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
          },
          marks: [
            IntervalMark(
              color: ColorEncode(value: Defaults.primaryColor),
              label: LabelEncode(
                encoder: (tuple) => Label(tuple['value'].toStringAsFixed(0)),
              ),
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
        ),
      );
    },
  ),
  ChartEntry(
    title: '2. Puntos por Equipo (Horizontal)',
    description: 'Mismo dataset, coordenada transpuesta con degradado.',
    family: 'Barras',
    builder: (context) {
      final ds = SportsChartMapper.standingsPoints(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Barras horizontales (RectCoord transposed).',
        chart: Chart(
          data: ds.points,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
          },
          marks: [
            IntervalMark(
              gradient: GradientEncode(
                value: const LinearGradient(colors: [
                  Color(0x8883bff6),
                  Color(0xcc188df0),
                ]),
              ),
            ),
          ],
          coord: RectCoord(transposed: true),
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
        ),
      );
    },
  ),
  ChartEntry(
    title: '3. Goles a Favor por Equipo',
    description: 'intGoalsFor coloreado por grupo Top/Resto.',
    family: 'Barras',
    builder: (context) {
      final ds = SportsChartMapper.standingsGoalsForVsAgainst(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: 'Goles a Favor por Equipo',
        description: 'Color por grupo (Top 4 vs resto de la tabla).',
        chart: Chart(
          data: ds.points,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
            'group': Variable(accessor: (ChartDataPoint p) => p.group ?? '—'),
          },
          marks: [
            IntervalMark(
              color: ColorEncode(variable: 'group', values: Defaults.colors10),
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          selections: {'tap': PointSelection(dim: Dim.x)},
          tooltip: TooltipGuide(),
        ),
      );
    },
  ),
  ChartEntry(
    title: '4. Ranking de Estadios por Capacidad',
    description: 'search_all_teams.php → intCapacity, orden descendente.',
    family: 'Barras',
    builder: (context) {
      final ds = SportsChartMapper.teamsCapacityRanking(
        SportsDataScope.of(context).teams,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Ordenado de mayor a menor capacidad.',
        chart: Chart(
          data: ds.points,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
          },
          marks: [
            IntervalMark(
              shape: ShapeEncode(
                value: RectShape(borderRadius: BorderRadius.circular(3)),
              ),
              color: ColorEncode(value: Defaults.colors10[6]),
            ),
          ],
          coord: RectCoord(transposed: true),
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
        ),
      );
    },
  ),
  ChartEntry(
    title: '5. G/E/P por Equipo (Apilado)',
    description: 'Ganados, Empatados y Perdidos apilados por equipo.',
    family: 'Barras',
    builder: (context) {
      final ds = SportsChartMapper.standingsWinLossDrawAll(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'StackModifier agrupando por resultado.',
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
          tooltip: TooltipGuide(multiTuples: true),
        ),
      );
    },
  ),
  ChartEntry(
    title: '6. G/E/P por Equipo (Agrupado)',
    description: 'Mismo dataset con DodgeModifier (barras lado a lado).',
    family: 'Barras',
    builder: (context) {
      final ds = SportsChartMapper.standingsWinLossDrawAll(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: 'G/E/P por Equipo (Agrupado)',
        description: 'DodgeModifier separa las 3 series por equipo.',
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
        ),
      );
    },
  ),
  ChartEntry(
    title: '7. Rendimiento del Equipo Líder',
    description: 'Ganados / Empatados / Perdidos de un solo equipo.',
    family: 'Barras',
    builder: (context) {
      final ds = SportsChartMapper.standingsWinLossDraw(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Una barra por resultado.',
        chart: Chart(
          data: ds.points,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
          },
          marks: [
            IntervalMark(
              color: ColorEncode(variable: 'label', values: Defaults.colors10),
              label: LabelEncode(
                encoder: (tuple) => Label(tuple['value'].toStringAsFixed(0)),
              ),
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
        ),
      );
    },
  ),
  ChartEntry(
    title: '8. Goles por Jornada',
    description: 'eventsseason.php → suma de goles local+visitante.',
    family: 'Barras',
    builder: (context) {
      final ds = SportsChartMapper.eventsGoalsByRound(
        SportsDataScope.of(context).events,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Un valor por jornada jugada.',
        chart: Chart(
          data: ds.points,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
          },
          marks: [IntervalMark(color: ColorEncode(value: Defaults.colors10[1]))],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
        ),
      );
    },
  ),
  ChartEntry(
    title: '9. Asistencia por Partido',
    description: 'intSpectators por fecha, con degradado.',
    family: 'Barras',
    builder: (context) {
      final ds = SportsChartMapper.eventsAttendance(
        SportsDataScope.of(context).events,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Cada barra es un partido de la temporada.',
        chart: Chart(
          data: ds.points,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
          },
          marks: [
            IntervalMark(
              gradient: GradientEncode(
                value: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0x886dc8ec), Color(0xff1e9493)],
                ),
              ),
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
        ),
      );
    },
  ),
  ChartEntry(
    title: '10. Estadísticas: Local vs Visitante',
    description: 'lookupeventstats.php, barras agrupadas por métrica.',
    family: 'Barras',
    builder: (context) {
      final base = SportsChartMapper.eventStatsHomeAway(
        SportsDataScope.of(context).eventStats,
      );
      final ds = SportsChartMapper.splitPair(base);
      return ChartCardWrapper(
        title: base.title,
        description: 'Cada métrica compara Local vs Visitante.',
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
          tooltip: TooltipGuide(multiTuples: true),
        ),
      );
    },
  ),
  ChartEntry(
    title: '11. Embudo de Goles a Favor',
    description: 'FunnelShape con los goles a favor de cada equipo.',
    family: 'Barras',
    builder: (context) {
      final ds = SportsChartMapper.standingsGoalsForVsAgainst(
        SportsDataScope.of(context).standings,
      );
      final top = ds.points.take(6).toList();
      return ChartCardWrapper(
        title: 'Embudo de Goles a Favor (Top 6)',
        description: 'SymmetricModifier + FunnelShape.',
        chart: Chart(
          padding: (_) => const EdgeInsets.all(10),
          data: top,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
          },
          marks: [
            IntervalMark(
              shape: ShapeEncode(value: FunnelShape()),
              color: ColorEncode(variable: 'label', values: Defaults.colors10),
              modifiers: [SymmetricModifier()],
            ),
          ],
          coord: RectCoord(transposed: true, verticalRange: [1, 0]),
        ),
      );
    },
  ),
  ChartEntry(
    title: '12. Puntos con Selección y Tooltip',
    description: 'Barra base con crosshair, tooltip y elevación al tocar.',
    family: 'Barras',
    builder: (context) {
      final ds = SportsChartMapper.standingsPoints(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Toca una barra para resaltarla (doble tap limpia).',
        chart: Chart(
          data: ds.points,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
          },
          marks: [
            IntervalMark(
              elevation: ElevationEncode(value: 0, updaters: {
                'tap': {true: (_) => 5}
              }),
              color: ColorEncode(value: Defaults.primaryColor, updaters: {
                'tap': {false: (color) => color.withAlpha(100)}
              }),
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
          selections: {'tap': PointSelection(dim: Dim.x)},
          tooltip: TooltipGuide(),
          crosshair: CrosshairGuide(),
        ),
      );
    },
  ),
];
