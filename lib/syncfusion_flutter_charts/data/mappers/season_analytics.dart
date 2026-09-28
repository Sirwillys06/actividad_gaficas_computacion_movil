import '../../core/utils/stats_utils.dart';
import '../models/event.dart';
import '../models/round_stats.dart';
import '../models/team.dart';
import '../models/team_stats.dart';

/// Resultado de transformar los partidos reales de una temporada en todas las
/// estructuras que consumen los gráficos. Se calcula una sola vez por carga de
/// datos; cambiar filtros o pestañas no vuelve a recorrer la API.
class SeasonAnalytics {
  /// Todos los partidos recibidos (con y sin marcador).
  final List<SportEvent> allEvents;

  /// Partidos con marcador, en orden cronológico.
  final List<SportEvent> scoredEvents;

  /// Clasificación calculada (puntos, diferencia de goles, goles a favor).
  final List<TeamStats> standings;

  /// Agregados por jornada, en orden.
  final List<RoundStats> rounds;

  /// `true` si las jornadas proceden de `intRound`; `false` si se agrupó por fecha.
  final bool roundsFromApi;

  /// Evolución de posición y puntos de cada equipo al cierre de cada jornada.
  final Map<String, List<StandingSnapshot>> history;

  final Map<String, TeamStats> _byKey;

  SeasonAnalytics._({
    required this.allEvents,
    required this.scoredEvents,
    required this.standings,
    required this.rounds,
    required this.roundsFromApi,
    required this.history,
  }) : _byKey = {for (final team in standings) team.key: team};

  static final SeasonAnalytics empty = SeasonAnalytics.fromEvents(const []);

  factory SeasonAnalytics.fromEvents(List<SportEvent> events, {List<Team> teams = const []}) {
    final unique = <String, SportEvent>{};
    for (final event in events) {
      unique[event.id] = event;
    }
    final all = unique.values.toList()..sort(_chronological);
    final scored = all.where((event) => event.hasScore).toList();

    final useRounds = scored.isNotEmpty && scored.where((event) => event.round != null).length * 2 >= scored.length;
    final rounds = _buildRounds(scored, useRounds);
    final standings = _buildStandings(scored, teams);
    final history = _buildHistory(rounds, standings);

    return SeasonAnalytics._(
      allEvents: all,
      scoredEvents: scored,
      standings: standings,
      rounds: rounds,
      roundsFromApi: useRounds,
      history: history,
    );
  }

  bool get isEmpty => scoredEvents.isEmpty;
  int get unscoredEvents => allEvents.length - scoredEvents.length;
  String get roundUnit => roundsFromApi ? 'Jornada' : 'Fecha';

  TeamStats? team(String? key) => key == null ? null : _byKey[key];

  int get totalGoals => scoredEvents.fold(0, (sum, event) => sum + event.totalGoals);
  int get homeGoals => scoredEvents.fold(0, (sum, event) => sum + event.homeScore!);
  int get awayGoals => scoredEvents.fold(0, (sum, event) => sum + event.awayScore!);
  int get homeWins => scoredEvents.where((e) => e.homeScore! > e.awayScore!).length;
  int get awayWins => scoredEvents.where((e) => e.homeScore! < e.awayScore!).length;
  int get draws => scoredEvents.where((e) => e.homeScore == e.awayScore).length;
  double get averageGoals => StatsUtils.ratio(totalGoals, scoredEvents.length);

  static int _chronological(SportEvent a, SportEvent b) {
    final ka = a.kickoff;
    final kb = b.kickoff;
    if (ka != null && kb != null && ka != kb) return ka.compareTo(kb);
    if (ka == null && kb != null) return 1;
    if (ka != null && kb == null) return -1;
    final ra = a.round ?? 0;
    final rb = b.round ?? 0;
    if (ra != rb) return ra.compareTo(rb);
    return a.id.compareTo(b.id);
  }

  static List<RoundStats> _buildRounds(List<SportEvent> scored, bool useRounds) {
    if (useRounds) {
      final grouped = <int, List<SportEvent>>{};
      for (final event in scored) {
        final round = event.round;
        if (round != null) grouped.putIfAbsent(round, () => []).add(event);
      }
      final keys = grouped.keys.toList()..sort();
      return [for (final key in keys) RoundStats(order: key, label: 'J$key', events: grouped[key]!)];
    }
    final grouped = <String, List<SportEvent>>{};
    for (final event in scored) {
      final date = event.date;
      if (date != null) grouped.putIfAbsent(date, () => []).add(event);
    }
    final keys = grouped.keys.toList()..sort();
    return [
      for (var i = 0; i < keys.length; i++)
        RoundStats(order: i + 1, label: _shortDate(keys[i]), events: grouped[keys[i]]!),
    ];
  }

  static String _shortDate(String isoDate) {
    final parts = isoDate.split('-');
    return parts.length == 3 ? '${parts[2]}/${parts[1]}' : isoDate;
  }

  static List<TeamStats> _buildStandings(List<SportEvent> scored, List<Team> teams) {
    final teamById = {for (final team in teams) team.id: team};
    final teamByName = {for (final team in teams) team.name: team};
    final matchesByTeam = <String, List<SportEvent>>{};
    final names = <String, String>{};
    final badges = <String, String?>{};

    void register(String key, String name, String? eventBadge) {
      matchesByTeam.putIfAbsent(key, () => []);
      names.putIfAbsent(key, () => name);
      final known = teamById[key] ?? teamByName[name];
      badges[key] ??= known?.badge ?? eventBadge;
    }

    for (final event in scored) {
      register(event.homeKey, event.homeTeam, event.homeBadge);
      register(event.awayKey, event.awayTeam, event.awayBadge);
      matchesByTeam[event.homeKey]!.add(event);
      matchesByTeam[event.awayKey]!.add(event);
    }

    final stats = <TeamStats>[];
    matchesByTeam.forEach((key, events) {
      var points = 0, goalsFor = 0, goalsAgainst = 0;
      final matches = <TeamMatch>[];
      for (var i = 0; i < events.length; i++) {
        final event = events[i];
        final isHome = event.homeKey == key;
        final gf = isHome ? event.homeScore! : event.awayScore!;
        final ga = isHome ? event.awayScore! : event.homeScore!;
        goalsFor += gf;
        goalsAgainst += ga;
        points += TeamMatch.pointsFor(gf > ga ? MatchOutcome.win : (gf == ga ? MatchOutcome.draw : MatchOutcome.loss));
        matches.add(
          TeamMatch(
            event: event,
            isHome: isHome,
            order: i + 1,
            cumulativePoints: points,
            cumulativeGoalsFor: goalsFor,
            cumulativeGoalsAgainst: goalsAgainst,
          ),
        );
      }
      stats.add(TeamStats(key: key, name: names[key]!, badge: badges[key], rank: 0, matches: matches));
    });

    stats.sort(compareStanding);
    return [for (var i = 0; i < stats.length; i++) stats[i].withRank(i + 1)];
  }

  /// Criterio de desempate: puntos, diferencia de goles, goles a favor, nombre.
  /// (Cada competición tiene reglas propias; este es el criterio más común y
  /// se documenta en la interfaz como tabla calculada.)
  static int compareStanding(TeamStats a, TeamStats b) {
    final byPoints = b.points.compareTo(a.points);
    if (byPoints != 0) return byPoints;
    final byDiff = b.goalDifference.compareTo(a.goalDifference);
    if (byDiff != 0) return byDiff;
    final byGoals = b.goalsFor.compareTo(a.goalsFor);
    if (byGoals != 0) return byGoals;
    return a.name.compareTo(b.name);
  }

  static Map<String, List<StandingSnapshot>> _buildHistory(List<RoundStats> rounds, List<TeamStats> standings) {
    final history = {for (final team in standings) team.key: <StandingSnapshot>[]};
    if (rounds.isEmpty) return history;
    final points = {for (final team in standings) team.key: 0};
    final goalsFor = {for (final team in standings) team.key: 0};
    final goalsAgainst = {for (final team in standings) team.key: 0};
    final names = {for (final team in standings) team.key: team.name};

    for (final round in rounds) {
      for (final event in round.events) {
        final home = event.homeScore!;
        final away = event.awayScore!;
        goalsFor[event.homeKey] = goalsFor[event.homeKey]! + home;
        goalsAgainst[event.homeKey] = goalsAgainst[event.homeKey]! + away;
        goalsFor[event.awayKey] = goalsFor[event.awayKey]! + away;
        goalsAgainst[event.awayKey] = goalsAgainst[event.awayKey]! + home;
        final homeOutcome = home > away ? MatchOutcome.win : (home == away ? MatchOutcome.draw : MatchOutcome.loss);
        final awayOutcome = away > home ? MatchOutcome.win : (home == away ? MatchOutcome.draw : MatchOutcome.loss);
        points[event.homeKey] = points[event.homeKey]! + TeamMatch.pointsFor(homeOutcome);
        points[event.awayKey] = points[event.awayKey]! + TeamMatch.pointsFor(awayOutcome);
      }
      final order = history.keys.toList()
        ..sort((a, b) {
          final byPoints = points[b]!.compareTo(points[a]!);
          if (byPoints != 0) return byPoints;
          final diffA = goalsFor[a]! - goalsAgainst[a]!;
          final diffB = goalsFor[b]! - goalsAgainst[b]!;
          if (diffA != diffB) return diffB.compareTo(diffA);
          final byGoals = goalsFor[b]!.compareTo(goalsFor[a]!);
          if (byGoals != 0) return byGoals;
          return names[a]!.compareTo(names[b]!);
        });
      for (var i = 0; i < order.length; i++) {
        final key = order[i];
        history[key]!.add(
          StandingSnapshot(
            roundOrder: round.order,
            roundLabel: round.label,
            position: i + 1,
            points: points[key]!,
            goalDifference: goalsFor[key]! - goalsAgainst[key]!,
          ),
        );
      }
    }
    return history;
  }
}
