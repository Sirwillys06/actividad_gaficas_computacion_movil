import '../core/safe_data_parser.dart';
import '../data/sports_api_mock.dart';
import 'chart_data_point.dart';

/// Traduce el JSON crudo de TheSportsDB al modelo agnóstico [ChartDataSet],
/// aplicando [SafeDataParser] y cayendo a [SportsApiMock] cuando no hay filas.
class SportsChartMapper {
  SportsChartMapper._();

  // ---------------------------------------------------------------------
  // 4.1 Standings (lookuptable.php)
  // ---------------------------------------------------------------------

  static ChartDataSet standingsPoints(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return SportsApiMock.getMockStandings();
    return ChartDataSet(
      title: 'Puntos por Equipo',
      xLabel: 'Equipos',
      yLabel: 'Puntos',
      points: rows
          .map((r) => ChartDataPoint(
                label: r['strTeam'].toSafeString(defaultValue: '—'),
                value: r['intPoints'].toSafeDouble(),
                secondaryValue: r['intRank'].toSafeDouble(),
                group: r['intRank'].toSafeInt() <= 4 ? 'Top' : 'Resto',
              ))
          .toList(),
    );
  }

  static ChartDataSet standingsGoalsForVsAgainst(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return SportsApiMock.getMockStandings();
    return ChartDataSet(
      title: 'Goles a Favor vs En Contra',
      xLabel: 'Goles a Favor',
      yLabel: 'Goles en Contra',
      points: rows
          .map((r) => ChartDataPoint(
                label: r['strTeam'].toSafeString(defaultValue: '—'),
                value: r['intGoalsFor'].toSafeDouble(),
                secondaryValue: r['intGoalsAgainst'].toSafeDouble(),
                group: 'Liga',
                extraMetaData: {'points': r['intPoints'].toSafeDouble()},
              ))
          .toList(),
    );
  }

  /// Win / Loss / Draw de un solo equipo (para pastel / dona / radar simple).
  static ChartDataSet standingsWinLossDraw(
    List<Map<String, Object?>> rows, {
    String? teamName,
  }) {
    if (rows.isEmpty) return SportsApiMock.getMockMatchStats();
    final row = teamName == null
        ? rows.first
        : rows.firstWhere(
            (r) => r['strTeam'].toSafeString() == teamName,
            orElse: () => rows.first,
          );
    final team = row['strTeam'].toSafeString(defaultValue: '—');
    return ChartDataSet(
      title: 'Rendimiento de $team',
      xLabel: 'Resultado',
      yLabel: 'Partidos',
      points: [
        ChartDataPoint(label: 'Ganados', value: row['intWin'].toSafeDouble(), group: team),
        ChartDataPoint(label: 'Empatados', value: row['intDraw'].toSafeDouble(), group: team),
        ChartDataPoint(label: 'Perdidos', value: row['intLoss'].toSafeDouble(), group: team),
      ],
    );
  }

  /// Win / Loss / Draw apilado de varios equipos (para barras/rosa apiladas).
  static ChartDataSet standingsWinLossDrawAll(
    List<Map<String, Object?>> rows, {
    int limit = 6,
  }) {
    if (rows.isEmpty) return SportsApiMock.getMockStandings();
    final points = <ChartDataPoint>[];
    for (final r in rows.take(limit)) {
      final team = r['strTeam'].toSafeString(defaultValue: '—');
      points.add(ChartDataPoint(label: team, value: r['intWin'].toSafeDouble(), group: 'Ganados'));
      points.add(ChartDataPoint(label: team, value: r['intDraw'].toSafeDouble(), group: 'Empatados'));
      points.add(ChartDataPoint(label: team, value: r['intLoss'].toSafeDouble(), group: 'Perdidos'));
    }
    return ChartDataSet(
      title: 'Ganados / Empatados / Perdidos',
      xLabel: 'Equipo',
      yLabel: 'Partidos',
      points: points,
    );
  }

  // ---------------------------------------------------------------------
  // 4.2 Events season (eventsseason.php)
  // ---------------------------------------------------------------------

  static ChartDataSet eventsGoalsByRound(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return SportsApiMock.getMockEventsSeason();
    return ChartDataSet(
      title: 'Goles por Jornada',
      xLabel: 'Jornada',
      yLabel: 'Goles',
      points: rows.map((r) {
        final goals = r['intHomeScore'].toSafeDouble() + r['intAwayScore'].toSafeDouble();
        return ChartDataPoint(
          label: 'J${r['intRound'].toSafeString(defaultValue: '-')}',
          value: goals,
          group: 'Liga',
          timestamp: r['dateEvent'].toSafeDate(),
          extraMetaData: {'evento': r['strEvent'].toSafeString()},
        );
      }).toList(),
    );
  }

  static ChartDataSet eventsAttendance(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return SportsApiMock.getMockEventsSeason();
    return ChartDataSet(
      title: 'Asistencia por Partido',
      xLabel: 'Fecha',
      yLabel: 'Espectadores',
      points: rows
          .map((r) => ChartDataPoint(
                label: r['dateEvent'].toSafeString(),
                value: r['intSpectators'].toSafeDouble(),
                group: 'Asistencia',
                timestamp: r['dateEvent'].toSafeDate(),
              ))
          .toList(),
    );
  }

  static ChartDataSet eventsHomeAwayScores(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return SportsApiMock.getMockEventsSeason();
    return ChartDataSet(
      title: 'Goles Local vs Visitante por Jornada',
      xLabel: 'Jornada',
      yLabel: 'Goles',
      points: rows.map((r) {
        return ChartDataPoint(
          label: 'J${r['intRound'].toSafeString(defaultValue: '-')}',
          value: r['intHomeScore'].toSafeDouble(),
          secondaryValue: r['intAwayScore'].toSafeDouble(),
          group: 'Liga',
          timestamp: r['dateEvent'].toSafeDate(),
        );
      }).toList(),
    );
  }

  static ChartDataSet eventsCumulativeHomeAway(List<Map<String, Object?>> rows) {
    final base = eventsHomeAwayScores(rows);
    var runningHome = 0.0;
    var runningAway = 0.0;
    final points = <ChartDataPoint>[];
    for (final p in base.points) {
      runningHome += p.value;
      runningAway += p.secondaryValue ?? 0;
      points.add(ChartDataPoint(label: p.label, value: runningHome, group: 'Local', timestamp: p.timestamp));
      points.add(ChartDataPoint(label: p.label, value: runningAway, group: 'Visitante', timestamp: p.timestamp));
    }
    return ChartDataSet(
      title: 'Goles Acumulados: Local vs Visitante',
      xLabel: base.xLabel,
      yLabel: 'Goles Acumulados',
      points: points,
    );
  }

  static ChartDataSet eventsCumulativeGoals(List<Map<String, Object?>> rows) {
    final base = eventsGoalsByRound(rows);
    var running = 0.0;
    final points = base.points.map((p) {
      running += p.value;
      return ChartDataPoint(
        label: p.label,
        value: running,
        group: 'Acumulado',
        timestamp: p.timestamp,
      );
    }).toList();
    return ChartDataSet(
      title: 'Goles Acumulados en la Temporada',
      xLabel: base.xLabel,
      yLabel: 'Goles Acumulados',
      points: points,
    );
  }

  // ---------------------------------------------------------------------
  // 4.3 Event stats (lookupeventstats.php)
  // ---------------------------------------------------------------------

  static ChartDataSet eventStatsHomeAway(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return SportsApiMock.getMockMatchStats();
    return ChartDataSet(
      title: 'Estadísticas del Partido',
      xLabel: 'Métrica',
      yLabel: 'Cantidad',
      points: rows
          .map((r) => ChartDataPoint(
                label: r['strStat'].toSafeString(defaultValue: '—'),
                value: r['intHome'].toSafeDouble(),
                secondaryValue: r['intAway'].toSafeDouble(),
                group: 'Partido',
              ))
          .toList(),
    );
  }

  static ChartDataSet eventStatsPossessionShare(List<Map<String, Object?>> rows) {
    final ds = eventStatsHomeAway(rows);
    final possession = ds.points.firstWhere(
      (p) =>
          p.label.toLowerCase().contains('posesi') ||
          p.label.toLowerCase().contains('possession'),
      orElse: () => ds.points.first,
    );
    return ChartDataSet(
      title: 'Posesión Local vs Visitante',
      xLabel: 'Equipo',
      yLabel: '%',
      points: [
        ChartDataPoint(label: 'Local', value: possession.value, group: 'Posesión'),
        ChartDataPoint(
          label: 'Visitante',
          value: possession.secondaryValue ?? 0,
          group: 'Posesión',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // 4.4 Teams (search_all_teams.php)
  // ---------------------------------------------------------------------

  static ChartDataSet teamsCapacityVsYear(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return SportsApiMock.getMockTeams();
    return ChartDataSet(
      title: 'Año de Fundación vs Capacidad',
      xLabel: 'Año de Fundación',
      yLabel: 'Capacidad',
      points: rows
          .map((r) => ChartDataPoint(
                label: r['strTeam'].toSafeString(defaultValue: '—'),
                value: r['intFormedYear'].toSafeDouble(),
                secondaryValue: r['intCapacity'].toSafeDouble(),
                group: r['strCountry'].toSafeString(defaultValue: 'N/A'),
              ))
          .toList(),
    );
  }

  /// Convierte un dataset con value/secondaryValue en dos series
  /// (p.ej. Local/Visitante) para gráficos de barras/radar agrupados.
  static ChartDataSet splitPair(
    ChartDataSet source, {
    String firstGroup = 'Local',
    String secondGroup = 'Visitante',
  }) {
    final points = <ChartDataPoint>[];
    for (final p in source.points) {
      points.add(ChartDataPoint(label: p.label, value: p.value, group: firstGroup));
      points.add(ChartDataPoint(
        label: p.label,
        value: p.secondaryValue ?? 0,
        group: secondGroup,
      ));
    }
    return ChartDataSet(
      title: source.title,
      xLabel: source.xLabel,
      yLabel: source.yLabel,
      points: points,
    );
  }

  static ChartDataSet standingsPointsAndGoals(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return SportsApiMock.getMockStandings();
    return ChartDataSet(
      title: 'Puntos vs Goles a Favor',
      xLabel: 'Equipo',
      yLabel: 'Cantidad',
      points: rows
          .map((r) => ChartDataPoint(
                label: r['strTeam'].toSafeString(defaultValue: '—'),
                value: r['intPoints'].toSafeDouble(),
                secondaryValue: r['intGoalsFor'].toSafeDouble(),
              ))
          .toList(),
    );
  }

  /// Perfil multi-métrica normalizado (0-1) de los primeros [limit] equipos,
  /// listo para un radar donde todas las métricas comparten escala.
  static ChartDataSet standingsMultiMetricRadar(
    List<Map<String, Object?>> rows, {
    int limit = 3,
  }) {
    if (rows.isEmpty) return SportsApiMock.getMockStandings();
    final teams = rows.take(limit).toList();
    const metrics = {
      'Puntos': 'intPoints',
      'Goles a Favor': 'intGoalsFor',
      'Goles en Contra': 'intGoalsAgainst',
      'Ganados': 'intWin',
    };

    final points = <ChartDataPoint>[];
    metrics.forEach((metricLabel, field) {
      final values = teams.map((r) => r[field].toSafeDouble()).toList();
      final min = values.reduce((a, b) => a < b ? a : b);
      final max = values.reduce((a, b) => a > b ? a : b);
      final range = (max - min) == 0 ? 1 : (max - min);
      for (var i = 0; i < teams.length; i++) {
        final team = teams[i]['strTeam'].toSafeString(defaultValue: '—');
        final normalized = (values[i] - min) / range;
        points.add(ChartDataPoint(label: metricLabel, value: normalized, group: team));
      }
    });

    return ChartDataSet(
      title: 'Perfil Multi-métrica (Normalizado)',
      xLabel: 'Métrica',
      yLabel: 'Valor Normalizado',
      points: points,
    );
  }

  static ChartDataSet eventsGoalsVsAttendance(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return SportsApiMock.getMockEventsSeason();
    return ChartDataSet(
      title: 'Goles vs Asistencia por Jornada',
      xLabel: 'Goles',
      yLabel: 'Asistencia',
      points: rows.map((r) {
        final goals = r['intHomeScore'].toSafeDouble() + r['intAwayScore'].toSafeDouble();
        return ChartDataPoint(
          label: 'J${r['intRound'].toSafeString(defaultValue: '-')}',
          value: goals,
          secondaryValue: r['intSpectators'].toSafeDouble(),
          group: 'Liga',
          timestamp: r['dateEvent'].toSafeDate(),
        );
      }).toList(),
    );
  }

  /// Intercambia label <-> group, útil para "voltear" un dataset y
  /// reutilizarlo en un gráfico con otra agrupación (ej. radar).
  static ChartDataSet swapLabelGroup(ChartDataSet source) {
    return ChartDataSet(
      title: source.title,
      xLabel: source.yLabel,
      yLabel: source.xLabel,
      points: source.points
          .map((p) => ChartDataPoint(
                label: p.group ?? '—',
                value: p.value,
                secondaryValue: p.secondaryValue,
                group: p.label,
                timestamp: p.timestamp,
                extraMetaData: p.extraMetaData,
              ))
          .toList(),
    );
  }

  static ChartDataSet teamsCapacityRanking(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return SportsApiMock.getMockTeams();
    final points = rows
        .map((r) => ChartDataPoint(
              label: r['strTeam'].toSafeString(defaultValue: '—'),
              value: r['intCapacity'].toSafeDouble(),
              group: 'Estadios',
              extraMetaData: {'estadio': r['strStadium'].toSafeString()},
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ChartDataSet(
      title: 'Ranking de Estadios por Capacidad',
      xLabel: 'Equipo',
      yLabel: 'Capacidad',
      points: points,
    );
  }
}
