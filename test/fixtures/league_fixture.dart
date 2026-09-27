import 'package:actividad_graficos/charts_flutter/models/multi_league_dashboard_models.dart';

/// Liga ficticia y determinista para tests: 20 equipos, 6 jornadas.
/// La tabla se calcula a partir de los partidos, así ambos bloques son
/// coherentes entre sí (como en TheSportsDB).
LeagueDashboardData buildFixtureLeague({int rounds = 6}) {
  const names = [
    'Arsenal', 'Liverpool', 'Manchester City', 'Chelsea', 'Aston Villa',
    'Tottenham Hotspur', 'Newcastle United', 'Manchester United',
    'West Ham United', 'Brighton', 'Brentford', 'Fulham', 'Crystal Palace',
    'Wolverhampton Wanderers', 'Everton', 'Nottingham Forest', 'Bournemouth',
    'Leeds United', 'Burnley', 'Sunderland',
  ];
  final ids = [for (var i = 0; i < names.length; i++) '${133600 + i}'];

  var seed = 7;
  int next(int max) {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed % max;
  }

  final events = <MatchEventData>[];
  final start = DateTime(2026, 8, 15);
  for (var r = 0; r < rounds; r++) {
    // Rotación tipo "round robin" para emparejar a los 20 equipos.
    final order = [0, ...List.generate(19, (i) => 1 + (i + r) % 19)];
    for (var m = 0; m < 10; m++) {
      final home = order[m], away = order[19 - m];
      final strength = (20 - home) - (20 - away);
      final hs = next(3) + (strength > 5 ? 1 : 0);
      final as = next(3) + (strength < -5 ? 1 : 0);
      events.add(
        MatchEventData(
          id: 'e$r$m',
          date: start.add(Duration(days: r * 7 + (m % 3))),
          homeTeam: names[home],
          awayTeam: names[away],
          homeTeamId: ids[home],
          awayTeamId: ids[away],
          homeScore: hs,
          awayScore: as,
          round: r + 1,
        ),
      );
    }
  }
  // Un partido futuro sin marcador: debe ignorarse en los gráficos.
  events.add(
    MatchEventData(
      id: 'future',
      date: start.add(Duration(days: rounds * 7)),
      homeTeam: names[0],
      awayTeam: names[1],
      homeTeamId: ids[0],
      awayTeamId: ids[1],
      homeScore: null,
      awayScore: null,
    ),
  );

  final stats = {for (final id in ids) id: List<int>.filled(6, 0)};
  // [PJ, V, E, D, GF, GC]
  for (final e in events.where((e) => e.hasScore)) {
    final h = stats[e.homeTeamId]!, a = stats[e.awayTeamId]!;
    h[0]++;
    a[0]++;
    h[4] += e.homeScore!;
    h[5] += e.awayScore!;
    a[4] += e.awayScore!;
    a[5] += e.homeScore!;
    if (e.isHomeWin) {
      h[1]++;
      a[3]++;
    } else if (e.isAwayWin) {
      a[1]++;
      h[3]++;
    } else {
      h[2]++;
      a[2]++;
    }
  }

  final rows = [
    for (var i = 0; i < names.length; i++)
      (
        id: ids[i],
        name: names[i],
        s: stats[ids[i]]!,
        pts: stats[ids[i]]![1] * 3 + stats[ids[i]]![2],
      ),
  ]..sort((x, y) {
      final byPts = y.pts.compareTo(x.pts);
      if (byPts != 0) return byPts;
      return (y.s[4] - y.s[5]).compareTo(x.s[4] - x.s[5]);
    });

  final standings = [
    for (var i = 0; i < rows.length; i++)
      TeamStandingData(
        idTeam: rows[i].id,
        team: rows[i].name,
        rank: i + 1,
        played: rows[i].s[0],
        wins: rows[i].s[1],
        draws: rows[i].s[2],
        losses: rows[i].s[3],
        goalsFor: rows[i].s[4],
        goalsAgainst: rows[i].s[5],
        goalDifference: rows[i].s[4] - rows[i].s[5],
        points: rows[i].pts,
        badge: null,
      ),
  ];

  return LeagueDashboardData(
    league: fiveMajorEuropeanLeagues.first,
    standings: standings,
    events: events,
  );
}
