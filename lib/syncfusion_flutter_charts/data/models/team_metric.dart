import '../../core/utils/formatters.dart';
import 'team_stats.dart';

/// Métrica numérica de un equipo, reutilizada por todos los gráficos de
/// ranking, dispersión y comparación.
class TeamMetric {
  final String label;
  final String unit;
  final double Function(TeamStats team) value;
  final bool isPercent;
  final bool isDecimal;

  const TeamMetric(this.label, this.value, {this.unit = '', this.isPercent = false, this.isDecimal = false});

  String format(num value) => isPercent
      ? Formatters.percent(value)
      : isDecimal
      ? Formatters.decimal(value)
      : Formatters.number(value);

  String get axisTitle => unit.isEmpty ? label : '$label ($unit)';

  static final points = TeamMetric('Puntos', (t) => t.points.toDouble(), unit: 'pts');
  static final played = TeamMetric('Partidos jugados', (t) => t.played.toDouble(), unit: 'PJ');
  static final wins = TeamMetric('Victorias', (t) => t.wins.toDouble());
  static final draws = TeamMetric('Empates', (t) => t.draws.toDouble());
  static final losses = TeamMetric('Derrotas', (t) => t.losses.toDouble());
  static final goalsFor = TeamMetric('Goles a favor', (t) => t.goalsFor.toDouble(), unit: 'GF');
  static final goalsAgainst = TeamMetric('Goles en contra', (t) => t.goalsAgainst.toDouble(), unit: 'GC');
  static final goalDifference = TeamMetric('Diferencia de goles', (t) => t.goalDifference.toDouble(), unit: 'DG');
  static final pointsPerMatch = TeamMetric(
    'Puntos por partido',
    (t) => t.pointsPerMatch,
    unit: 'pts/PJ',
    isDecimal: true,
  );
  static final performance = TeamMetric('Rendimiento', (t) => t.performance, unit: '% pts posibles', isPercent: true);
  static final goalsForPerMatch = TeamMetric(
    'Goles a favor por partido',
    (t) => t.goalsForPerMatch,
    unit: 'GF/PJ',
    isDecimal: true,
  );
  static final goalsAgainstPerMatch = TeamMetric(
    'Goles en contra por partido',
    (t) => t.goalsAgainstPerMatch,
    unit: 'GC/PJ',
    isDecimal: true,
  );
  static final winRate = TeamMetric('Victorias', (t) => t.winRate, unit: '%', isPercent: true);
  static final drawRate = TeamMetric('Empates', (t) => t.drawRate, unit: '%', isPercent: true);
  static final lossRate = TeamMetric('Derrotas', (t) => t.lossRate, unit: '%', isPercent: true);
  static final cleanSheets = TeamMetric('Porterías a cero', (t) => t.cleanSheets.toDouble());
  static final failedToScore = TeamMetric('Partidos sin marcar', (t) => t.failedToScore.toDouble());
  static final homePerformance = TeamMetric('Rendimiento local', (t) => t.home.performance, unit: '%', isPercent: true);
  static final awayPerformance = TeamMetric(
    'Rendimiento visitante',
    (t) => t.away.performance,
    unit: '%',
    isPercent: true,
  );
  static final homePointsPerMatch = TeamMetric(
    'Pts/PJ local',
    (t) => t.home.pointsPerMatch,
    unit: 'pts/PJ',
    isDecimal: true,
  );
  static final awayPointsPerMatch = TeamMetric(
    'Pts/PJ visitante',
    (t) => t.away.pointsPerMatch,
    unit: 'pts/PJ',
    isDecimal: true,
  );
  static final homeGoalsFor = TeamMetric('GF local', (t) => t.home.goalsFor.toDouble(), unit: 'goles');
  static final awayGoalsFor = TeamMetric('GF visitante', (t) => t.away.goalsFor.toDouble(), unit: 'goles');
  static final homeGoalsAgainst = TeamMetric('GC local', (t) => t.home.goalsAgainst.toDouble(), unit: 'goles');
  static final awayGoalsAgainst = TeamMetric('GC visitante', (t) => t.away.goalsAgainst.toDouble(), unit: 'goles');
  static final homeWins = TeamMetric('Victorias local', (t) => t.home.wins.toDouble());
  static final awayWins = TeamMetric('Victorias visitante', (t) => t.away.wins.toDouble());
  static final homeDraws = TeamMetric('Empates local', (t) => t.home.draws.toDouble());
  static final awayDraws = TeamMetric('Empates visitante', (t) => t.away.draws.toDouble());
  static final homeLosses = TeamMetric('Derrotas local', (t) => t.home.losses.toDouble());
  static final awayLosses = TeamMetric('Derrotas visitante', (t) => t.away.losses.toDouble());
  static final homeAdvantage = TeamMetric(
    'Ventaja de localía',
    (t) => t.homeAdvantage,
    unit: 'Δ pts/PJ',
    isDecimal: true,
  );
  static final recentForm = TeamMetric(
    'Puntos en los últimos partidos',
    (t) => t.recentFormPoints.toDouble(),
    unit: 'pts',
  );
  static final bothTeamsScoredRate = TeamMetric(
    'Ambos marcan',
    (t) => t.bothTeamsScoredRate,
    unit: '% partidos',
    isPercent: true,
  );
}
