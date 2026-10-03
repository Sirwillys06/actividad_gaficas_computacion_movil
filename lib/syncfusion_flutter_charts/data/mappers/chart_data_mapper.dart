import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/stats_utils.dart';
import '../models/chart_point.dart';
import '../models/event.dart';
import '../models/match_result.dart';

/// Transformaciones de partidos (a nivel de liga) en datos de gráficos.
class ChartDataMapper {
  static List<MatchResult> goalsByTeam(List<SportEvent> events) {
    final totals = <String, double>{};

    for (final event in events.where((item) => item.hasScore)) {
      totals.update(event.homeTeam, (value) => value + event.homeScore!, ifAbsent: () => event.homeScore!.toDouble());
      totals.update(event.awayTeam, (value) => value + event.awayScore!, ifAbsent: () => event.awayScore!.toDouble());
    }

    return totals.entries.map((entry) => MatchResult(entry.key, entry.value)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  static List<MatchResult> outcomes(List<SportEvent> events) {
    double homeWins = 0;
    double draws = 0;
    double awayWins = 0;

    for (final event in events.where((item) => item.hasScore)) {
      if (event.homeScore == event.awayScore) {
        draws++;
      } else if (event.homeScore! > event.awayScore!) {
        homeWins++;
      } else {
        awayWins++;
      }
    }

    return [
      MatchResult('Victorias locales', homeWins),
      MatchResult('Empates', draws),
      MatchResult('Victorias visitantes', awayWins),
    ].where((item) => item.value > 0).toList();
  }

  /// Goles de cada partido con marcador. Por defecto los primeros
  /// [AppConstants.chartEventLimit]; `limit: null` devuelve todos.
  static List<MatchResult> goalsByMatch(List<SportEvent> events, {int? limit = AppConstants.chartEventLimit}) {
    final scored = events.where((item) => item.hasScore);
    return (limit == null ? scored : scored.take(limit))
        .toList()
        .asMap()
        .entries
        .map((entry) => MatchResult((entry.key + 1).toString(), entry.value.totalGoals.toDouble()))
        .toList();
  }

  static List<SportEvent> _scored(List<SportEvent> events) => events.where((event) => event.hasScore).toList();

  /// Partidos ordenados por goles (desc) y limitados a [count].
  static List<LabeledValue> highestScoringMatches(List<SportEvent> events, {int count = 10}) {
    final sorted = _scored(events)..sort((a, b) => b.totalGoals.compareTo(a.totalGoals));
    return sorted.take(count).map((e) => LabeledValue(e.matchLabel, e.totalGoals.toDouble(), detail: e.date)).toList();
  }

  static List<LabeledValue> lowestScoringMatches(List<SportEvent> events, {int count = 10}) {
    final sorted = _scored(events)..sort((a, b) => a.totalGoals.compareTo(b.totalGoals));
    return sorted.take(count).map((e) => LabeledValue(e.matchLabel, e.totalGoals.toDouble(), detail: e.date)).toList();
  }

  /// Margen absoluto de cada partido, en orden cronológico.
  static List<LabeledValue> marginByMatch(List<SportEvent> events) => [
    for (final (index, event) in _scored(events).indexed)
      LabeledValue('${index + 1}', (event.homeScore! - event.awayScore!).abs().toDouble(), detail: event.matchLabel),
  ];

  /// Goles de todos los partidos con marcador, con el partido como detalle.
  static List<LabeledValue> goalsPerMatchDetailed(List<SportEvent> events) => [
    for (final (index, event) in _scored(events).indexed)
      LabeledValue('${index + 1}', event.totalGoals.toDouble(), detail: event.matchLabel),
  ];

  /// Frecuencia de cada marcador (local-visitante), de más a menos frecuente.
  static List<LabeledValue> scorelineFrequency(List<SportEvent> events) {
    final counts = <String, int>{};
    for (final event in _scored(events)) {
      counts.update(event.scoreLabel, (value) => value + 1, ifAbsent: () => 1);
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : a.key.compareTo(b.key));
    return [for (final entry in entries) LabeledValue(entry.key, entry.value.toDouble())];
  }

  /// Partidos con ganador agrupados por margen de victoria (1, 2, 3, 4+).
  static List<LabeledValue> winsByMargin(List<SportEvent> events) {
    final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0};
    for (final event in _scored(events)) {
      final margin = (event.homeScore! - event.awayScore!).abs();
      if (margin == 0) continue;
      final bucket = margin >= 4 ? 4 : margin;
      counts[bucket] = counts[bucket]! + 1;
    }
    return [
      for (final entry in counts.entries)
        LabeledValue(
          entry.key == 4 ? '4+ goles' : '${entry.key} gol${entry.key == 1 ? '' : 'es'}',
          entry.value.toDouble(),
        ),
    ];
  }

  /// Matriz de marcadores: goles local (x), goles visitante (y), frecuencia (tamaño).
  static List<XYPoint> scoreMatrix(List<SportEvent> events) {
    final counts = <(int, int), int>{};
    for (final event in _scored(events)) {
      final key = (event.homeScore!, event.awayScore!);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return [
      for (final entry in counts.entries)
        XYPoint(
          x: entry.key.$1.toDouble(),
          y: entry.key.$2.toDouble(),
          size: entry.value.toDouble(),
          label: '${entry.key.$1}-${entry.key.$2}: ${entry.value} partido${entry.value == 1 ? '' : 's'}',
        ),
    ];
  }

  static List<num> totalGoals(List<SportEvent> events) => _scored(events).map((event) => event.totalGoals).toList();

  /// Partidos y goles medios por día de la semana (según `dateEvent`).
  static List<LabeledValue> matchesByWeekday(List<SportEvent> events) =>
      _byWeekday(events, (list) => list.length.toDouble());

  static List<LabeledValue> averageGoalsByWeekday(List<SportEvent> events) =>
      _byWeekday(events, (list) => StatsUtils.mean(list.map((event) => event.totalGoals)));

  static List<LabeledValue> _byWeekday(List<SportEvent> events, double Function(List<SportEvent>) reducer) {
    final grouped = <int, List<SportEvent>>{};
    for (final event in _scored(events)) {
      final day = event.day;
      if (day != null) grouped.putIfAbsent(day.weekday, () => []).add(event);
    }
    final keys = grouped.keys.toList()..sort();
    return [for (final key in keys) LabeledValue(Formatters.weekdays[key - 1], reducer(grouped[key]!))];
  }

  /// Partidos por hora de inicio (UTC, según `strTime`/`strTimestamp`).
  static List<LabeledValue> matchesByKickoffHour(List<SportEvent> events) {
    final grouped = <int, int>{};
    for (final event in _scored(events)) {
      final hour = event.kickoffHourUtc;
      if (hour != null) grouped[hour] = (grouped[hour] ?? 0) + 1;
    }
    final keys = grouped.keys.toList()..sort();
    return [for (final key in keys) LabeledValue('${key.toString().padLeft(2, '0')}:00', grouped[key]!.toDouble())];
  }

  /// Partidos por encima / por debajo de la línea de 2.5 goles.
  static List<MatchResult> overUnder(List<SportEvent> events) {
    final scored = _scored(events);
    final over = scored.where((event) => event.totalGoals > AppConstants.overUnderLine).length;
    return [
      MatchResult('Más de ${AppConstants.overUnderLine} goles', over.toDouble()),
      MatchResult('Menos de ${AppConstants.overUnderLine} goles', (scored.length - over).toDouble()),
    ].where((item) => item.value > 0).toList();
  }
}
