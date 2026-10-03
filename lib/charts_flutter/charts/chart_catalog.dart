import 'dart:math' as math;

import 'package:flutter/painting.dart' show Color;

import '../models/multi_league_dashboard_models.dart';
import '../theme/dashboard_theme.dart';
import 'chart_models.dart';

/// Matriz de gráficos del dashboard.
///
/// Cada liga muestra las mismas 16 definiciones (8 básicas + 8 avanzadas)
/// construidas con sus propios datos: 5 ligas × 16 = 80 gráficos.
/// Ninguna definición repite la combinación datos + tipo de otra.
///
/// | Nº | Sección     | Gráfico                         | Tipo            | Fuente   |
/// |----|-------------|---------------------------------|-----------------|----------|
/// | 1  | Rendimiento | Puntos por equipo               | Barra horiz.    | tabla    |
/// | 2  | Rendimiento | Balance V/E/D                   | Apiladas        | tabla    |
/// | 3  | Rendimiento | Victorias por equipo            | Columnas        | tabla    |
/// | 4  | Rendimiento | Resultados de un equipo         | Donut           | tabla    |
/// | 5  | Goles       | Goles a favor vs en contra      | Agrupadas       | tabla    |
/// | 6  | Goles       | Diferencia de goles             | Divergentes     | tabla    |
/// | 7  | Goles       | Ataque vs defensa               | Dispersión      | tabla    |
/// | 8  | Goles       | Goles según posición            | Líneas          | tabla    |
/// | 9  | Partidos    | Goles por fecha                 | Serie temporal  | eventos  |
/// | 10 | Partidos    | Goles y partidos por mes        | Combo           | eventos  |
/// | 11 | Partidos    | Local / empate / visitante      | Pie             | eventos  |
/// | 12 | Partidos    | Goles acumulados                | Área temporal   | eventos  |
/// | 13 | Avanzado    | Puntos como local y visitante   | Apiladas        | ambos    |
/// | 14 | Avanzado    | Puntos vs diferencia de goles   | Dispersión      | tabla    |
/// | 15 | Avanzado    | Goles por partido (distribución)| Columnas        | eventos  |
/// | 16 | Avanzado    | Carrera por el título (top 5)   | Serie temporal  | ambos    |
class ChartCatalog {
  ChartCatalog._();

  static List<ChartDefinition> forSection(DashboardSection section) =>
      all.where((definition) => definition.section == section).toList();

  static final List<ChartDefinition> all = [
    // ------------------------------------------------------------------
    // RENDIMIENTO (básicos)
    // ------------------------------------------------------------------
    ChartDefinition(
      id: 'points',
      section: DashboardSection.rendimiento,
      kind: ChartKind.horizontalBar,
      title: 'Puntos por equipo',
      description: 'Clasificación ordenada por puntos. Pasa el cursor sobre '
          'una barra para ver el detalle.',
      axisHint: 'Filas: equipos · Eje X: puntos',
      source: ChartDataSource.standings,
      advanced: false,
      build: (data) => _teamMetric(
        data,
        metric: 'Puntos',
        unit: 'pts',
        color: DashboardColors.points,
        value: (t) => t.points.toDouble(),
      ),
    ),
    ChartDefinition(
      id: 'wdl_stacked',
      section: DashboardSection.rendimiento,
      kind: ChartKind.stacked,
      title: 'Balance de resultados',
      description: 'Victorias, empates y derrotas apilados: la longitud total '
          'son los partidos jugados.',
      axisHint: 'Filas: equipos (orden de la tabla) · Eje X: partidos',
      source: ChartDataSource.standings,
      advanced: false,
      build: (data) {
        final teams = _byRank(data);
        return CategoryChartData(
          metric: 'Partidos',
          unit: 'partidos',
          categories: teams.map(_teamItem).toList(),
          series: [
            CategorySeries(
              name: 'Victorias',
              color: DashboardColors.win,
              values: teams.map((t) => t.wins.toDouble()).toList(),
            ),
            CategorySeries(
              name: 'Empates',
              color: DashboardColors.draw,
              values: teams.map((t) => t.draws.toDouble()).toList(),
            ),
            CategorySeries(
              name: 'Derrotas',
              color: DashboardColors.loss,
              values: teams.map((t) => t.losses.toDouble()).toList(),
            ),
          ],
        );
      },
    ),
    ChartDefinition(
      id: 'wins_column',
      section: DashboardSection.rendimiento,
      kind: ChartKind.column,
      title: 'Victorias por equipo',
      description: 'Partidos ganados, de más a menos. El escudo bajo cada '
          'columna identifica al equipo.',
      axisHint: 'Eje X: equipos · Eje Y: victorias',
      source: ChartDataSource.standings,
      advanced: false,
      build: (data) => _teamMetric(
        data,
        metric: 'Victorias',
        unit: 'victorias',
        color: DashboardColors.win,
        value: (t) => t.wins.toDouble(),
      ),
    ),
    ChartDefinition(
      id: 'team_donut',
      section: DashboardSection.rendimiento,
      kind: ChartKind.donut,
      title: 'Resultados de un equipo',
      description: 'Composición de victorias, empates y derrotas. Elige el '
          'equipo en el selector (por defecto, el líder).',
      axisHint: 'Porciones: % de partidos jugados',
      source: ChartDataSource.standings,
      advanced: false,
      build: (data) => PieChartData(
        unit: 'partidos',
        selectorLabel: 'Equipo',
        options: _byRank(data)
            .map(
              (t) => PieOption(
                label: t.team,
                teamId: t.idTeam,
                centerCaption: '${t.played} PJ',
                slices: [
                  PieSlice('Victorias', t.wins.toDouble(), DashboardColors.win),
                  PieSlice('Empates', t.draws.toDouble(), DashboardColors.draw),
                  PieSlice('Derrotas', t.losses.toDouble(), DashboardColors.loss),
                ],
              ),
            )
            .toList(),
      ),
    ),

    // ------------------------------------------------------------------
    // GOLES (básicos)
    // ------------------------------------------------------------------
    ChartDefinition(
      id: 'gf_ga_grouped',
      section: DashboardSection.goles,
      kind: ChartKind.grouped,
      title: 'Goles a favor vs en contra',
      description: 'Dos barras por equipo: lo que marca (azul) frente a lo '
          'que recibe (naranja).',
      axisHint: 'Eje X: equipos (orden de la tabla) · Eje Y: goles',
      source: ChartDataSource.standings,
      advanced: false,
      build: (data) {
        final teams = _byRank(data);
        return CategoryChartData(
          metric: 'Goles',
          unit: 'goles',
          categories: teams.map(_teamItem).toList(),
          series: [
            CategorySeries(
              name: 'Goles a favor',
              color: DashboardColors.goalsFor,
              values: teams.map((t) => t.goalsFor.toDouble()).toList(),
            ),
            CategorySeries(
              name: 'Goles en contra',
              color: DashboardColors.goalsAgainst,
              values: teams.map((t) => t.goalsAgainst.toDouble()).toList(),
            ),
          ],
        );
      },
    ),
    ChartDefinition(
      id: 'goal_difference',
      section: DashboardSection.goles,
      kind: ChartKind.divergingBar,
      title: 'Diferencia de goles',
      description: 'Goles a favor menos goles en contra. Las barras crecen '
          'desde el cero: verde positivo, rojo negativo.',
      axisHint: 'Filas: equipos · Eje X: diferencia de goles (±)',
      source: ChartDataSource.standings,
      advanced: false,
      build: (data) => _teamMetric(
        data,
        metric: 'Diferencia de goles',
        unit: 'goles',
        color: DashboardColors.win,
        value: (t) => t.goalDifference.toDouble(),
      ),
    ),
    ChartDefinition(
      id: 'attack_defense_scatter',
      section: DashboardSection.goles,
      kind: ChartKind.scatter,
      title: 'Ataque vs defensa',
      description: 'Cada punto es un equipo. Abajo a la derecha: mucho gol y '
          'pocos goles recibidos.',
      axisHint: 'Eje X: goles a favor · Eje Y: goles en contra',
      source: ChartDataSource.standings,
      advanced: false,
      build: (data) => ScatterChartData(
        xLabel: 'Goles a favor',
        yLabel: 'Goles en contra',
        color: DashboardColors.goalsFor,
        points: _byRank(data)
            .map(
              (t) => ScatterPoint(
                x: t.goalsFor.toDouble(),
                y: t.goalsAgainst.toDouble(),
                label: t.team,
                teamId: t.idTeam,
                details: ['Posición ${t.rank}º · ${t.points} pts'],
              ),
            )
            .toList(),
      ),
    ),
    ChartDefinition(
      id: 'goals_by_position_line',
      section: DashboardSection.goles,
      kind: ChartKind.line,
      title: 'Goles según la posición',
      description: 'Cómo cambian los goles marcados y recibidos al bajar en '
          'la tabla, del 1º al último.',
      axisHint: 'Eje X: posición en la tabla · Eje Y: goles',
      source: ChartDataSource.standings,
      advanced: false,
      build: (data) {
        final teams = _byRank(data);
        return CategoryChartData(
          metric: 'Goles',
          unit: 'goles',
          categories: teams
              .map(
                (t) => CategoryItem(
                  label: t.team,
                  shortLabel: '${t.rank}º',
                  teamId: t.idTeam,
                  details: ['Posición ${t.rank}º · ${t.points} pts'],
                ),
              )
              .toList(),
          series: [
            CategorySeries(
              name: 'Goles a favor',
              color: DashboardColors.goalsFor,
              values: teams.map((t) => t.goalsFor.toDouble()).toList(),
            ),
            CategorySeries(
              name: 'Goles en contra',
              color: DashboardColors.goalsAgainst,
              values: teams.map((t) => t.goalsAgainst.toDouble()).toList(),
            ),
          ],
        );
      },
    ),

    // ------------------------------------------------------------------
    // PARTIDOS (avanzados, eventos)
    // ------------------------------------------------------------------
    ChartDefinition(
      id: 'goals_by_date_ts',
      section: DashboardSection.partidos,
      kind: ChartKind.timeSeries,
      title: 'Goles por fecha',
      description: 'Goles marcados en cada día con partidos. El tooltip '
          'muestra el partido con más goles de ese día.',
      axisHint: 'Eje X: fecha real del partido · Eje Y: goles',
      source: ChartDataSource.events,
      advanced: true,
      emptyMessage: 'No hay partidos finalizados en esta temporada todavía.',
      build: (data) {
        final byDay = _finishedByDay(data);
        final notes = <DateTime, List<String>>{};
        final points = <TimePoint>[];
        byDay.forEach((day, matches) {
          final goals = matches.fold<int>(0, (s, e) => s + e.totalGoals);
          points.add(TimePoint(day, goals.toDouble()));
          final top = matches.reduce(
            (a, b) => b.totalGoals > a.totalGoals ? b : a,
          );
          notes[day] = [
            '${matches.length} ${matches.length == 1 ? 'partido' : 'partidos'}',
            'Más goles: ${top.scoreLine}',
          ];
        });
        return TimeChartData(
          metric: 'Goles',
          unit: 'goles',
          notes: notes,
          series: [
            TimeSeriesLine(
              name: 'Goles del día',
              color: DashboardColors.goalsFor,
              points: points,
            ),
          ],
        );
      },
    ),
    ChartDefinition(
      id: 'goals_matches_combo',
      section: DashboardSection.partidos,
      kind: ChartKind.combo,
      title: 'Goles y partidos por mes',
      description: 'Barras: goles del mes. Línea: partidos disputados. Ambas '
          'series son conteos y comparten el eje.',
      axisHint: 'Eje X: mes · Eje Y: cantidad (goles / partidos)',
      source: ChartDataSource.events,
      advanced: true,
      emptyMessage: 'No hay partidos finalizados en esta temporada todavía.',
      build: (data) {
        final months = <DateTime, List<MatchEventData>>{};
        for (final event in _finished(data)) {
          final month = DateTime(event.date!.year, event.date!.month);
          months.putIfAbsent(month, () => []).add(event);
        }
        final keys = months.keys.toList()..sort();
        final goals = keys
            .map((m) => months[m]!.fold<int>(0, (s, e) => s + e.totalGoals))
            .toList();
        return CategoryChartData(
          metric: 'Cantidad',
          categories: [
            for (var i = 0; i < keys.length; i++)
              CategoryItem(
                label: formatMonth(keys[i]),
                details: [
                  'Promedio: ${formatNumber(goals[i] / months[keys[i]]!.length, decimals: 2)} goles/partido',
                ],
              ),
          ],
          series: [
            CategorySeries(
              name: 'Goles',
              color: DashboardColors.goalsFor,
              values: goals.map((g) => g.toDouble()).toList(),
            ),
            CategorySeries(
              name: 'Partidos',
              color: DashboardColors.matches,
              asLine: true,
              values: keys.map((m) => months[m]!.length.toDouble()).toList(),
            ),
          ],
        );
      },
    ),
    ChartDefinition(
      id: 'results_pie',
      section: DashboardSection.partidos,
      kind: ChartKind.pie,
      title: 'Quién gana los partidos',
      description: 'Reparto de todos los partidos finalizados entre victoria '
          'local, empate y victoria visitante.',
      axisHint: 'Porciones: % de partidos finalizados',
      source: ChartDataSource.events,
      advanced: true,
      emptyMessage: 'No hay partidos finalizados en esta temporada todavía.',
      build: (data) {
        final finished = _finished(data);
        return PieChartData(
          unit: 'partidos',
          options: [
            PieOption(
              label: data.league.name,
              centerCaption: '${finished.length} partidos',
              slices: [
                PieSlice(
                  'Victoria local',
                  finished.where((e) => e.isHomeWin).length.toDouble(),
                  DashboardColors.home,
                ),
                PieSlice(
                  'Empate',
                  finished.where((e) => e.isDraw).length.toDouble(),
                  DashboardColors.draw,
                ),
                PieSlice(
                  'Victoria visitante',
                  finished.where((e) => e.isAwayWin).length.toDouble(),
                  DashboardColors.away,
                ),
              ],
            ),
          ],
        );
      },
    ),
    ChartDefinition(
      id: 'cumulative_goals_area',
      section: DashboardSection.partidos,
      kind: ChartKind.area,
      title: 'Goles acumulados en la temporada',
      description: 'Total de goles de la liga sumados fecha a fecha. La '
          'pendiente indica los días más goleadores.',
      axisHint: 'Eje X: fecha real · Eje Y: goles acumulados',
      source: ChartDataSource.events,
      advanced: true,
      emptyMessage: 'No hay partidos finalizados en esta temporada todavía.',
      build: (data) {
        final byDay = _finishedByDay(data);
        var total = 0;
        final points = <TimePoint>[];
        final notes = <DateTime, List<String>>{};
        byDay.forEach((day, matches) {
          final goals = matches.fold<int>(0, (s, e) => s + e.totalGoals);
          total += goals;
          points.add(TimePoint(day, total.toDouble()));
          notes[day] = ['+$goals goles en ${matches.length} partidos'];
        });
        return TimeChartData(
          metric: 'Goles acumulados',
          unit: 'goles',
          cumulative: true,
          notes: notes,
          series: [
            TimeSeriesLine(
              name: 'Goles acumulados',
              color: DashboardColors.points,
              points: points,
            ),
          ],
        );
      },
    ),

    // ------------------------------------------------------------------
    // ANÁLISIS AVANZADO
    // ------------------------------------------------------------------
    ChartDefinition(
      id: 'home_away_points',
      section: DashboardSection.avanzado,
      kind: ChartKind.stacked,
      title: 'Puntos como local y visitante',
      description: 'Puntos calculados partido a partido (idTeam) según se '
          'jugara en casa o fuera.',
      axisHint: 'Filas: equipos · Eje X: puntos obtenidos en partidos',
      source: ChartDataSource.both,
      advanced: true,
      emptyMessage: 'No hay partidos finalizados con equipos identificados.',
      build: _homeAwayPoints,
    ),
    ChartDefinition(
      id: 'points_gd_scatter',
      section: DashboardSection.avanzado,
      kind: ChartKind.scatter,
      title: 'Puntos vs diferencia de goles',
      description: 'Equipos por encima de la nube suman más puntos de los que '
          'su diferencia de goles sugiere.',
      axisHint: 'Eje X: diferencia de goles · Eje Y: puntos',
      source: ChartDataSource.standings,
      advanced: true,
      build: (data) => ScatterChartData(
        xLabel: 'Diferencia de goles',
        yLabel: 'Puntos',
        color: DashboardColors.points,
        signedX: true,
        points: _byRank(data)
            .map(
              (t) => ScatterPoint(
                x: t.goalDifference.toDouble(),
                y: t.points.toDouble(),
                label: t.team,
                teamId: t.idTeam,
                details: ['Posición ${t.rank}º · ${t.wins}V ${t.draws}E ${t.losses}D'],
              ),
            )
            .toList(),
      ),
    ),
    ChartDefinition(
      id: 'goals_per_match_distribution',
      section: DashboardSection.avanzado,
      kind: ChartKind.column,
      title: 'Goles por partido',
      description: 'Cuántos partidos terminaron con 0, 1, 2… goles en total. '
          'Revela si la liga es cerrada o abierta.',
      axisHint: 'Eje X: goles en el partido · Eje Y: nº de partidos',
      source: ChartDataSource.events,
      advanced: true,
      emptyMessage: 'No hay partidos finalizados en esta temporada todavía.',
      build: (data) {
        final finished = _finished(data);
        const buckets = 7; // 0..5 y 6+
        final counts = List<int>.filled(buckets, 0);
        final examples = List<MatchEventData?>.filled(buckets, null);
        for (final event in finished) {
          final bucket = math.min(event.totalGoals, buckets - 1);
          counts[bucket]++;
          examples[bucket] ??= event;
        }
        final total = finished.length;
        return CategoryChartData(
          metric: 'Partidos',
          unit: 'partidos',
          categories: [
            for (var i = 0; i < buckets; i++)
              CategoryItem(
                label: i == buckets - 1 ? '${buckets - 1}+ goles' : '$i goles',
                shortLabel: i == buckets - 1 ? '${buckets - 1}+' : '$i',
                details: [
                  if (total > 0)
                    '${formatNumber(counts[i] * 100 / total)}% de los partidos',
                  if (examples[i] != null) 'Ej.: ${examples[i]!.scoreLine}',
                ],
              ),
          ],
          series: [
            CategorySeries(
              name: 'Partidos',
              color: DashboardColors.matches,
              values: counts.map((c) => c.toDouble()).toList(),
            ),
          ],
        );
      },
    ),
    ChartDefinition(
      id: 'title_race_ts',
      section: DashboardSection.avanzado,
      kind: ChartKind.timeSeries,
      title: 'Carrera por el título',
      description: 'Puntos acumulados partido a partido por los 5 primeros '
          'de la tabla actual.',
      axisHint: 'Eje X: fecha real · Eje Y: puntos acumulados',
      source: ChartDataSource.both,
      advanced: true,
      emptyMessage: 'No hay partidos finalizados de los primeros clasificados.',
      build: _titleRace,
    ),
  ];

  // --------------------------------------------------------------------
  // Helpers de construcción
  // --------------------------------------------------------------------

  static List<TeamStandingData> _byRank(LeagueDashboardData data) =>
      data.standings.toList()..sort((a, b) => a.rank.compareTo(b.rank));

  static CategoryItem _teamItem(TeamStandingData t) => CategoryItem(
        label: t.team,
        shortLabel: teamAbbreviation(t.team),
        teamId: t.idTeam,
        details: [
          'Posición ${t.rank}º · ${t.points} pts',
          'PJ ${t.played} · ${t.wins}V ${t.draws}E ${t.losses}D',
        ],
      );

  /// Métrica de una sola serie por equipo, ordenada de mayor a menor.
  static CategoryChartData _teamMetric(
    LeagueDashboardData data, {
    required String metric,
    required String unit,
    required Color color,
    required double Function(TeamStandingData team) value,
  }) {
    final teams = _byRank(data)
      ..sort((a, b) {
        final byValue = value(b).compareTo(value(a));
        return byValue != 0 ? byValue : a.rank.compareTo(b.rank);
      });
    return CategoryChartData(
      metric: metric,
      unit: unit,
      categories: teams.map(_teamItem).toList(),
      series: [
        CategorySeries(
          name: metric,
          color: color,
          values: teams.map(value).toList(),
        ),
      ],
    );
  }

  static List<MatchEventData> _finished(LeagueDashboardData data) =>
      data.events.where((e) => e.hasScore && e.date != null).toList()
        ..sort((a, b) => a.date!.compareTo(b.date!));

  static Map<DateTime, List<MatchEventData>> _finishedByDay(
    LeagueDashboardData data,
  ) {
    final days = <DateTime, List<MatchEventData>>{};
    for (final event in _finished(data)) {
      final day = DateTime(event.date!.year, event.date!.month, event.date!.day);
      days.putIfAbsent(day, () => []).add(event);
    }
    return days;
  }

  static int _pointsFor(int scored, int conceded) =>
      scored > conceded ? 3 : (scored == conceded ? 1 : 0);

  static ChartData _homeAwayPoints(LeagueDashboardData data) {
    final home = <String, int>{};
    final away = <String, int>{};
    final homeRecord = <String, List<int>>{};
    final awayRecord = <String, List<int>>{};
    final names = <String, String>{};

    void record(Map<String, List<int>> target, String id, int pts) {
      final r = target.putIfAbsent(id, () => [0, 0, 0]);
      r[pts == 3 ? 0 : (pts == 1 ? 1 : 2)]++;
    }

    for (final e in _finished(data)) {
      final h = e.homeTeamId, a = e.awayTeamId;
      if (h == null || a == null) continue;
      names[h] = e.homeTeam;
      names[a] = e.awayTeam;
      final hp = _pointsFor(e.homeScore!, e.awayScore!);
      final ap = _pointsFor(e.awayScore!, e.homeScore!);
      home[h] = (home[h] ?? 0) + hp;
      away[a] = (away[a] ?? 0) + ap;
      record(homeRecord, h, hp);
      record(awayRecord, a, ap);
    }

    final ids = {...home.keys, ...away.keys}.toList()
      ..sort((x, y) {
        final byTotal = ((home[y] ?? 0) + (away[y] ?? 0))
            .compareTo((home[x] ?? 0) + (away[x] ?? 0));
        if (byTotal != 0) return byTotal;
        final rx = data.teamById(x)?.rank ?? 999;
        final ry = data.teamById(y)?.rank ?? 999;
        return rx.compareTo(ry);
      });

    String line(String label, List<int>? r) => r == null
        ? '$label: sin partidos'
        : '$label: ${r[0]}V ${r[1]}E ${r[2]}D';

    return CategoryChartData(
      metric: 'Puntos',
      unit: 'pts',
      categories: ids.map((id) {
        final name = data.teamById(id)?.team ?? names[id] ?? id;
        return CategoryItem(
          label: name,
          shortLabel: teamAbbreviation(name),
          teamId: id,
          details: [
            line('Local', homeRecord[id]),
            line('Visitante', awayRecord[id]),
          ],
        );
      }).toList(),
      series: [
        CategorySeries(
          name: 'Puntos como local',
          color: DashboardColors.home,
          values: ids.map((id) => (home[id] ?? 0).toDouble()).toList(),
        ),
        CategorySeries(
          name: 'Puntos como visitante',
          color: DashboardColors.away,
          values: ids.map((id) => (away[id] ?? 0).toDouble()).toList(),
        ),
      ],
    );
  }

  static ChartData _titleRace(LeagueDashboardData data) {
    final top = _byRank(data).take(5).toList();
    final finished = _finished(data);
    final lines = <TimeSeriesLine>[];

    for (var i = 0; i < top.length; i++) {
      final team = top[i];
      var total = 0;
      final points = <TimePoint>[];
      for (final e in finished) {
        final isHome = e.homeTeamId == team.idTeam;
        final isAway = e.awayTeamId == team.idTeam;
        if (!isHome && !isAway) continue;
        total += isHome
            ? _pointsFor(e.homeScore!, e.awayScore!)
            : _pointsFor(e.awayScore!, e.homeScore!);
        final day = DateTime(e.date!.year, e.date!.month, e.date!.day);
        points.add(TimePoint(day, total.toDouble()));
      }
      lines.add(
        TimeSeriesLine(
          name: team.team,
          teamId: team.idTeam,
          color: DashboardColors.series[i % DashboardColors.series.length],
          points: points,
        ),
      );
    }

    return TimeChartData(
      metric: 'Puntos acumulados',
      unit: 'pts',
      cumulative: true,
      series: lines,
    );
  }
}

const _abbreviationStopWords = {
  'fc', 'afc', 'cf', 'sc', 'ac', 'as', 'ssc', 'ss', 'us', 'club', 'de', 'del',
  'la', 'le', 'il', 'and', '&', 'calcio', 'rc', 'rcd', 'ca', 'cd', 'ud', 'sd',
  'vfb', 'vfl', 'tsg', 'sv', 'fsv', '1.', 'bv', 'borussia', 'olympique',
  'stade', 'hellas',
};

/// Abreviatura de 3 letras para ejes con muchos equipos. El nombre completo
/// siempre aparece en el tooltip y el escudo identifica al club.
String teamAbbreviation(String name) {
  final words = name
      .split(RegExp(r'[\s\-]+'))
      .where((w) => w.isNotEmpty)
      .toList();
  final meaningful = words
      .where((w) => !_abbreviationStopWords.contains(w.toLowerCase()))
      .where((w) => !RegExp(r'^\d').hasMatch(w))
      .toList();
  var source = meaningful.isNotEmpty ? meaningful : words;
  if (source.isEmpty) return name.toUpperCase();

  final String raw;
  if (source.length >= 3) {
    // West Ham United → WHU
    raw = source.take(3).map((w) => w[0]).join();
  } else {
    // Newcastle United → NEW, pero Manchester United → MUN (evita choque
    // con Manchester City).
    if (source.length == 2 &&
        _abbreviationSuffixes.contains(source.last.toLowerCase()) &&
        source.first.toLowerCase() != 'manchester') {
      source = [source.first];
    }
    raw = source.length == 1 ? source.first : source.first[0] + source.last;
  }
  final letters = raw.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '');
  return letters.substring(0, math.min(3, letters.length)).toUpperCase();
}

const _abbreviationSuffixes = {
  'united', 'hotspur', 'wanderers', 'albion', 'town', 'rovers', 'city',
};
