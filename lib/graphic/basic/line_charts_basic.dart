import 'package:graphic/graphic.dart';
import 'package:intl/intl.dart';

import '../../models/chart_data_point.dart';
import '../../models/sports_chart_mapper.dart';
import '../../services/sports_data_scope.dart';
import '../../widgets/chart_card_wrapper.dart';
import '../../widgets/chart_entry.dart';

final _dateFormat = DateFormat('dd MMM');

/// 11 gráficos de líneas y áreas (LineMark / AreaMark) sobre datos de la API.
final List<ChartEntry> lineChartsBasicEntries = [
  ChartEntry(
    title: '13. Goles por Jornada (Línea)',
    description: 'eventsseason.php, escala temporal en el eje X.',
    family: 'Líneas',
    builder: (context) {
      final ds = SportsChartMapper.eventsGoalsByRound(
        SportsDataScope.of(context).events,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Eje X: fecha del partido · Eje Y: goles.',
        chart: Chart(
          data: ds.points,
          variables: {
            'time': Variable(
              accessor: (ChartDataPoint p) => p.timestamp!,
              scale: TimeScale(formatter: (t) => _dateFormat.format(t)),
            ),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
          },
          marks: [LineMark(color: ColorEncode(value: Defaults.primaryColor))],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
        ),
      );
    },
  ),
  ChartEntry(
    title: '14. Goles por Jornada (Suavizada)',
    description: 'Misma serie con BasicLineShape(smooth: true).',
    family: 'Líneas',
    builder: (context) {
      final ds = SportsChartMapper.eventsGoalsByRound(
        SportsDataScope.of(context).events,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Curva suavizada (spline).',
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
            LineMark(shape: ShapeEncode(value: BasicLineShape(smooth: true))),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
        ),
      );
    },
  ),
  ChartEntry(
    title: '15. Goles por Jornada (Escalonada)',
    description: 'BasicLineShape(stepped: true).',
    family: 'Líneas',
    builder: (context) {
      final ds = SportsChartMapper.eventsGoalsByRound(
        SportsDataScope.of(context).events,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Línea tipo escalón, útil para cambios discretos.',
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
            LineMark(shape: ShapeEncode(value: BasicLineShape(stepped: true))),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
        ),
      );
    },
  ),
  ChartEntry(
    title: '16. Goles Acumulados (Punteada)',
    description: 'Tendencia acumulada con línea discontinua.',
    family: 'Líneas',
    builder: (context) {
      final ds = SportsChartMapper.eventsCumulativeGoals(
        SportsDataScope.of(context).events,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Suma progresiva de goles jornada a jornada.',
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
              shape: ShapeEncode(value: BasicLineShape(dash: [5, 2])),
              color: ColorEncode(value: Defaults.colors10[4]),
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
        ),
      );
    },
  ),
  ChartEntry(
    title: '17. Área de Goles por Jornada',
    description: 'AreaMark con degradado + línea superior.',
    family: 'Líneas',
    builder: (context) {
      final ds = SportsChartMapper.eventsGoalsByRound(
        SportsDataScope.of(context).events,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Área rellena bajo la curva de goles.',
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
            AreaMark(
              color: ColorEncode(value: Defaults.colors10.first.withAlpha(80)),
            ),
            LineMark(size: SizeEncode(value: 0.5)),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
        ),
      );
    },
  ),
  ChartEntry(
    title: '18. Asistencia por Partido (Línea + Puntos)',
    description: 'Combina LineMark y PointMark sobre la asistencia.',
    family: 'Líneas',
    builder: (context) {
      final ds = SportsChartMapper.eventsAttendance(
        SportsDataScope.of(context).events,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Cada punto es un partido de la temporada.',
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
            LineMark(color: ColorEncode(value: Defaults.colors10[2])),
            PointMark(color: ColorEncode(value: Defaults.colors10[2])),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
        ),
      );
    },
  ),
  ChartEntry(
    title: '19. Goles Local vs Visitante (Multi-línea)',
    description: 'Dos series (Local/Visitante) sobre las mismas jornadas.',
    family: 'Líneas',
    builder: (context) {
      final base = SportsChartMapper.eventsHomeAwayScores(
        SportsDataScope.of(context).events,
      );
      final ds = SportsChartMapper.splitPair(base);
      return ChartCardWrapper(
        title: base.title,
        description: 'Nesteado por grupo con Varset (/).',
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
              size: SizeEncode(value: 0.7),
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
    title: '20. Río de Goles Local vs Visitante',
    description: 'AreaMark apilada y simétrica (stream graph).',
    family: 'Líneas',
    builder: (context) {
      final base = SportsChartMapper.eventsHomeAwayScores(
        SportsDataScope.of(context).events,
      );
      final ds = SportsChartMapper.splitPair(base);
      return ChartCardWrapper(
        title: 'Río de Goles Local vs Visitante',
        description: 'StackModifier + SymmetricModifier centrado.',
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
    title: '21. Ranking de Estadios (Línea)',
    description: 'Capacidad de estadios ordenada, como tendencia.',
    family: 'Líneas',
    builder: (context) {
      final ds = SportsChartMapper.teamsCapacityRanking(
        SportsDataScope.of(context).teams,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Line + Point sobre el ranking ordenado.',
        chart: Chart(
          data: ds.points,
          variables: {
            'label': Variable(accessor: (ChartDataPoint p) => p.label),
            'value': Variable(accessor: (ChartDataPoint p) => p.value),
          },
          marks: [
            LineMark(color: ColorEncode(value: Defaults.colors10[6])),
            PointMark(color: ColorEncode(value: Defaults.colors10[6])),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
        ),
      );
    },
  ),
  ChartEntry(
    title: '22. Asistencia con Selección Táctil',
    description: 'Punto seleccionado se sigue con el dedo/mouse.',
    family: 'Líneas',
    builder: (context) {
      final ds = SportsChartMapper.eventsAttendance(
        SportsDataScope.of(context).events,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Arrastra sobre la línea para ver el tooltip.',
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
          crosshair: CrosshairGuide(followPointer: [false, true]),
        ),
      );
    },
  ),
  ChartEntry(
    title: '23. Goles por Jornada (Área Escalonada)',
    description: 'AreaMark escalonada para resaltar cambios bruscos.',
    family: 'Líneas',
    builder: (context) {
      final ds = SportsChartMapper.eventsGoalsByRound(
        SportsDataScope.of(context).events,
      );
      return ChartCardWrapper(
        title: ds.title,
        description: 'Variante de área con forma escalonada.',
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
            AreaMark(
              shape: ShapeEncode(value: BasicAreaShape(stepped: true)),
              color: ColorEncode(value: Defaults.colors10[8].withAlpha(120)),
            ),
          ],
          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
        ),
      );
    },
  ),
];
