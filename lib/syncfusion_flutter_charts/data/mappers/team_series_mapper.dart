import '../../core/constants/app_constants.dart';
import '../../core/utils/stats_utils.dart';
import '../models/chart_point.dart';
import '../models/match_result.dart';
import '../models/team_stats.dart';
import 'season_analytics.dart';

/// Transformaciones centradas en uno o varios equipos (evolución, perfiles,
/// comparaciones). Todo se deriva de los partidos reales ya descargados.
class TeamSeriesMapper {
  static List<LabeledValue> positionByRound(SeasonAnalytics analytics, TeamStats team) => [
    for (final snap in analytics.history[team.key] ?? const []) LabeledValue(snap.roundLabel, snap.position.toDouble()),
  ];

  static List<LabeledValue> pointsByRound(SeasonAnalytics analytics, TeamStats team) => [
    for (final snap in analytics.history[team.key] ?? const []) LabeledValue(snap.roundLabel, snap.points.toDouble()),
  ];

  static List<LabeledValue> goalDifferenceByRound(SeasonAnalytics analytics, TeamStats team) => [
    for (final snap in analytics.history[team.key] ?? const [])
      LabeledValue(snap.roundLabel, snap.goalDifference.toDouble()),
  ];

  /// Diferencia de puntos con el líder al cierre de cada jornada.
  static List<LabeledValue> gapToLeaderByRound(SeasonAnalytics analytics, TeamStats team) {
    final own = analytics.history[team.key] ?? const [];
    return [
      for (var i = 0; i < own.length; i++)
        LabeledValue(own[i].roundLabel, (_maxPointsAt(analytics, i) - own[i].points).toDouble()),
    ];
  }

  static int _maxPointsAt(SeasonAnalytics analytics, int index) {
    var max = 0;
    for (final snaps in analytics.history.values) {
      if (index < snaps.length && snaps[index].points > max) max = snaps[index].points;
    }
    return max;
  }

  /// Mínimo y máximo de puntos acumulados en la liga al cierre de cada jornada.
  static List<RangePoint> leaguePointsRange(SeasonAnalytics analytics) {
    final rounds = analytics.rounds;
    return [
      for (var i = 0; i < rounds.length; i++)
        () {
          final values = [
            for (final snaps in analytics.history.values)
              if (i < snaps.length) snaps[i].points,
          ];
          return RangePoint(
            rounds[i].label,
            values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b).toDouble(),
            values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b).toDouble(),
          );
        }(),
    ];
  }

  static String matchLabel(TeamMatch match) => 'P${match.order}';

  static List<LabeledValue> cumulativeGoalsFor(TeamStats team) => [
    for (final m in team.matches) LabeledValue(matchLabel(m), m.cumulativeGoalsFor.toDouble(), detail: m.label),
  ];

  static List<LabeledValue> cumulativeGoalsAgainst(TeamStats team) => [
    for (final m in team.matches) LabeledValue(matchLabel(m), m.cumulativeGoalsAgainst.toDouble(), detail: m.label),
  ];

  /// Puntos acumulados solo en partidos de local (o de visitante), indexados
  /// por el número de partido dentro de esa condición.
  static List<LabeledValue> cumulativeSplitPoints(TeamStats team, {required bool home}) {
    var total = 0;
    var index = 0;
    return [
      for (final m in team.matches.where((m) => m.isHome == home))
        () {
          total += m.points;
          index++;
          return LabeledValue('$index', total.toDouble(), detail: m.label);
        }(),
    ];
  }

  /// Aportación de cada partido a la diferencia de goles (cascada).
  static List<LabeledValue> goalDifferenceSteps(TeamStats team) => [
    for (final m in team.matches) LabeledValue(matchLabel(m), m.goalDifference.toDouble(), detail: m.label),
  ];

  /// Perfil del equipo en índices 0–100 relativos a la liga.
  ///
  /// - Ataque: GF/PJ respecto al mejor ataque.
  /// - Defensa: mejor GC/PJ de la liga respecto al del equipo.
  /// - Rendimiento: % de puntos obtenidos.
  /// - Victorias: % de partidos ganados.
  /// - Porterías a cero: % de partidos sin encajar.
  /// - Forma: % de puntos posibles en los últimos partidos.
  static List<MatchResult> performanceProfile(SeasonAnalytics analytics, TeamStats team) {
    final teams = analytics.standings.where((t) => t.played > 0).toList();
    if (teams.isEmpty || team.played == 0) return const [];
    final bestAttack = teams.map((t) => t.goalsForPerMatch).reduce((a, b) => a > b ? a : b);
    final bestDefense = teams.map((t) => t.goalsAgainstPerMatch).reduce((a, b) => a < b ? a : b);
    final recent = team.recentMatches.length;
    double clamp(double value) => value.clamp(0, 100).toDouble();
    return [
      MatchResult('Ataque', clamp(StatsUtils.percent(team.goalsForPerMatch, bestAttack))),
      MatchResult(
        'Defensa',
        team.goalsAgainstPerMatch == 0 ? 100 : clamp(StatsUtils.percent(bestDefense, team.goalsAgainstPerMatch)),
      ),
      MatchResult('Rendimiento', clamp(team.performance)),
      MatchResult('Victorias', clamp(team.winRate)),
      MatchResult('Porterías a cero', clamp(StatsUtils.percent(team.cleanSheets, team.played))),
      MatchResult('Forma', clamp(StatsUtils.percent(team.recentFormPoints, recent * AppConstants.pointsPerWin))),
    ];
  }

  /// Resultados de los enfrentamientos directos entre dos equipos.
  static List<MatchResult> headToHead(TeamStats a, TeamStats b) {
    var winsA = 0, draws = 0, winsB = 0;
    for (final match in a.matches) {
      final event = match.event;
      if (!event.involves(b.key)) continue;
      switch (match.outcome) {
        case MatchOutcome.win:
          winsA++;
        case MatchOutcome.draw:
          draws++;
        case MatchOutcome.loss:
          winsB++;
      }
    }
    return [
      MatchResult('Gana ${a.name}', winsA.toDouble()),
      MatchResult('Empates', draws.toDouble()),
      MatchResult('Gana ${b.name}', winsB.toDouble()),
    ];
  }

  static List<num> goalsForPerMatch(TeamStats team) => [for (final m in team.matches) m.goalsFor];

  static MeanDeviation goalsDeviation(TeamStats team) =>
      MeanDeviation(team.name, team.goalsForPerMatch, team.goalsPerMatchStdDev);
}
