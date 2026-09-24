import 'package:flutter/widgets.dart';
import 'package:graphic/graphic.dart';

import '../../models/chart_data_point.dart';
import '../../models/sports_chart_mapper.dart';
import '../../services/sports_data_scope.dart';
import '../../widgets/chart_card_wrapper.dart';
import '../../widgets/chart_entry.dart';

/// 10 gráficos circulares (PolarCoord + IntervalMark): pastel, dona, rosa,
/// carrera y medidor, todos alimentados por la API de fútbol.
final List<ChartEntry> pieChartsBasicEntries = [
  ChartEntry(
    title: '24. Pastel: Rendimiento del Líder',
    description: 'Proportion transform + PolarCoord de una vuelta.',
    family: 'Circulares',
    builder: (context) {
      final ds = SportsChartMapper.standingsWinLossDraw(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Ganados / Empatados / Perdidos como pastel.',
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
              label: LabelEncode(
                encoder: (tuple) => Label(tuple['value'].toString()),
              ),
              color: ColorEncode(variable: 'label', values: Defaults.colors10),
              modifiers: [StackModifier()],
            ),
          ],
          coord: PolarCoord(transposed: true, dimCount: 1, dimFill: 1.05),
        ),
      );
    },
  ),
  ChartEntry(
    title: '25. Dona: Rendimiento del Líder',
    description: 'Mismo pastel con un radio interno (startRadius).',
    family: 'Circulares',
    builder: (context) {
      final ds = SportsChartMapper.standingsWinLossDraw(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: 'Dona: ${ds.title}',
        description: 'PolarCoord con startRadius para el hueco central.',
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
              modifiers: [StackModifier()],
            ),
          ],
          coord: PolarCoord(
            transposed: true,
            dimCount: 1,
            dimFill: 1.05,
            startRadius: 0.4,
          ),
        ),
      );
    },
  ),
  ChartEntry(
    title: '26. Pastel: Goles a Favor (Top 6)',
    description: 'Distribución proporcional de goles anotados.',
    family: 'Circulares',
    builder: (context) {
      final full = SportsChartMapper.standingsGoalsForVsAgainst(
        SportsDataScope.of(context).standings,
      );
      final top = full.points.take(6).toList();
      return ChartCardWrapper(
        title: 'Goles a Favor (Top 6)',
        description: 'Cada porción es la cuota de goles del equipo.',
        chart: Chart(
          data: top,
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
          selections: {'tap': PointSelection(variable: 'label')},
          tooltip: TooltipGuide(),
        ),
      );
    },
  ),
  ChartEntry(
    title: '27. Dona: Goles a Favor (Top 6)',
    description: 'Mismo dataset con hueco central.',
    family: 'Circulares',
    builder: (context) {
      final full = SportsChartMapper.standingsGoalsForVsAgainst(
        SportsDataScope.of(context).standings,
      );
      final top = full.points.take(6).toList();
      return ChartCardWrapper(
        title: 'Dona: Goles a Favor (Top 6)',
        description: 'startRadius: 0.45 para el efecto dona.',
        chart: Chart(
          data: top,
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
      );
    },
  ),
  ChartEntry(
    title: '28. Rosa de Puntos por Equipo',
    description: 'IntervalMark en coordenada polar con radio inicial.',
    family: 'Circulares',
    builder: (context) {
      final ds = SportsChartMapper.standingsPoints(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: 'Rosa de ${ds.title}',
        description: 'Con bordes redondeados y sombra (elevation).',
        chart: Chart(
          data: ds.points,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
          },
          marks: [
            IntervalMark(
              shape: ShapeEncode(
                value: RectShape(
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                ),
              ),
              color: ColorEncode(variable: 'label', values: Defaults.colors10),
              elevation: ElevationEncode(value: 3),
            ),
          ],
          coord: PolarCoord(startRadius: 0.15),
        ),
      );
    },
  ),
  ChartEntry(
    title: '29. Distribución Apilada de G/E/P',
    description: 'Barras apiladas por equipo y resultado.',
    family: 'Circulares',
    builder: (context) {
      final ds = SportsChartMapper.standingsWinLossDrawAll(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'StackModifier agrupado por equipo.',
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
    title: '30. Carrera Circular de Puntos',
    description: 'Barras dispuestas como carriles circulares (race chart).',
    family: 'Circulares',
    builder: (context) {
      final ds = SportsChartMapper.standingsPoints(
        SportsDataScope.of(context).standings,
      );
      return ChartCardWrapper(
        title: 'Carrera de ${ds.title}',
        description: 'Cada carril circular representa un equipo.',
        chart: Chart(
          data: ds.points,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(
              accessor: (ChartDataPoint p) => p.value,
              scale: LinearScale(min: 0),
            ),
          },
          marks: [
            IntervalMark(
              label: LabelEncode(
                encoder: (tuple) => Label(tuple['value'].toString()),
              ),
              color: ColorEncode(variable: 'label', values: Defaults.colors10),
            ),
          ],
          coord: PolarCoord(transposed: true),
          axes: [Defaults.radialAxis..label = null, Defaults.circularAxis],
        ),
      );
    },
  ),
  ChartEntry(
    title: '31. Medidor de Posesión Local',
    description: 'Gauge circular con la posesión del equipo local.',
    family: 'Circulares',
    builder: (context) {
      final possession = SportsChartMapper.eventStatsPossessionShare(
        SportsDataScope.of(context).eventStats,
      );
      final homePercent = possession.points.first.value;
      final data = [
        {'type': '100_percent', 'percent': 100.0},
        {'type': 'actual', 'percent': homePercent},
      ];
      return ChartCardWrapper(
        title: 'Medidor de Posesión Local',
        description: 'Local: ${homePercent.toStringAsFixed(0)}%.',
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
              label: LabelEncode(
                encoder: (tuple) => Label('${tuple['percent'].toStringAsFixed(0)}%'),
              ),
              shape: ShapeEncode(
                value: RectShape(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
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
    },
  ),
  ChartEntry(
    title: '32. Dona de Posesión Local vs Visitante',
    description: 'lookupeventstats.php → fila "Possession".',
    family: 'Circulares',
    builder: (context) {
      final ds = SportsChartMapper.eventStatsPossessionShare(
        SportsDataScope.of(context).eventStats,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Comparación directa de la posesión del balón.',
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
              label: LabelEncode(
                encoder: (tuple) =>
                    Label('${tuple['value'].toStringAsFixed(0)}%'),
              ),
              color: ColorEncode(variable: 'label', values: Defaults.colors10),
              modifiers: [StackModifier()],
            ),
          ],
          coord: PolarCoord(transposed: true, dimCount: 1, startRadius: 0.5),
        ),
      );
    },
  ),
  ChartEntry(
    title: '33. Pastel: Estadísticas del Local',
    description: 'Cuota de cada métrica dentro del total del equipo local.',
    family: 'Circulares',
    builder: (context) {
      final ds = SportsChartMapper.eventStatsHomeAway(
        SportsDataScope.of(context).eventStats,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Proporción de cada estadística (valor del local).',
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
              modifiers: [StackModifier()],
            ),
          ],
          coord: PolarCoord(transposed: true, dimCount: 1),
          tooltip: TooltipGuide(),
        ),
      );
    },
  ),
];
