import 'package:flutter_test/flutter_test.dart';

import 'package:actividad_graficos/syncfusion_flutter_charts/data/mappers/chart_data_mapper.dart';
import 'package:actividad_graficos/syncfusion_flutter_charts/data/mappers/season_analytics.dart';
import 'package:actividad_graficos/syncfusion_flutter_charts/data/mappers/team_series_mapper.dart';
import 'package:actividad_graficos/syncfusion_flutter_charts/data/models/event.dart';
import 'package:actividad_graficos/syncfusion_flutter_charts/data/models/ranking_filter.dart';
import 'package:actividad_graficos/syncfusion_flutter_charts/data/models/team.dart';

import 'support/season_fixture.dart';

SportEvent _e(String id, String home, String away, int? hs, int? as, {int round = 1, String date = '2025-08-16'}) =>
    SportEvent(
      id: id,
      homeTeam: home,
      awayTeam: away,
      homeTeamId: home,
      awayTeamId: away,
      homeScore: hs,
      awayScore: as,
      round: round,
      date: date,
    );

void main() {
  // A: 2-1 vs B (V), 0-0 vs C (E) · B: 3-0 vs C (V) · C sin partidos ganados.
  final events = [
    _e('1', 'A', 'B', 2, 1, round: 1, date: '2025-08-16'),
    _e('2', 'C', 'A', 0, 0, round: 2, date: '2025-08-23'),
    _e('3', 'B', 'C', 3, 0, round: 2, date: '2025-08-23'),
    _e('4', 'A', 'C', null, null, round: 3, date: '2025-08-30'),
  ];
  final analytics = SeasonAnalytics.fromEvents(events);
  final a = analytics.team('A')!;
  final b = analytics.team('B')!;
  final c = analytics.team('C')!;

  group('team statistics', () {
    test('counts goals for and against', () {
      expect(a.goalsFor, 2);
      expect(a.goalsAgainst, 1);
      expect(b.goalsFor, 4);
      expect(b.goalsAgainst, 2);
      expect(c.goalsFor, 0);
      expect(c.goalsAgainst, 3);
    });

    test('counts wins, draws and losses', () {
      expect([a.wins, a.draws, a.losses], [1, 1, 0]);
      expect([b.wins, b.draws, b.losses], [1, 0, 1]);
      expect([c.wins, c.draws, c.losses], [0, 1, 1]);
    });

    test('computes points and goal difference', () {
      expect(a.points, 4);
      expect(b.points, 3);
      expect(c.points, 1);
      expect(a.goalDifference, 1);
      expect(b.goalDifference, 2);
      expect(c.goalDifference, -3);
    });

    test('computes averages and percentages', () {
      expect(a.pointsPerMatch, 2);
      expect(b.goalsForPerMatch, 2);
      expect(a.winRate, 50);
      expect(a.performance, closeTo(66.67, 0.01));
      expect(c.cleanSheets, 1);
      expect(c.failedToScore, 2);
    });

    test('splits home and away records', () {
      expect(a.home.played, 1);
      expect(a.home.wins, 1);
      expect(a.away.draws, 1);
      expect(b.away.goalsFor, 1);
    });

    test('orders the standings by points, goal difference and goals', () {
      expect(analytics.standings.map((t) => t.key), ['A', 'B', 'C']);
      expect(analytics.standings.map((t) => t.rank), [1, 2, 3]);
    });
  });

  group('league aggregates', () {
    test('ignores matches without score', () {
      expect(analytics.allEvents, hasLength(4));
      expect(analytics.scoredEvents, hasLength(3));
      expect(analytics.unscoredEvents, 1);
      expect(analytics.rounds.map((r) => r.label), ['J1', 'J2']);
    });

    test('computes totals and averages', () {
      expect(analytics.totalGoals, 6);
      expect(analytics.averageGoals, 2);
      expect(analytics.homeWins, 2);
      expect(analytics.draws, 1);
      expect(analytics.awayWins, 0);
      expect(analytics.homeGoals, 5);
      expect(analytics.awayGoals, 1);
    });

    test('tracks position and points after every round', () {
      final history = TeamSeriesMapper.positionByRound(analytics, a);
      expect(history.map((p) => p.value), [1, 1]);
      expect(TeamSeriesMapper.pointsByRound(analytics, c).map((p) => p.value), [0, 1]);
      expect(TeamSeriesMapper.gapToLeaderByRound(analytics, b).map((p) => p.value), [3, 1]);
    });

    test('groups by date when the API does not provide rounds', () {
      final noRounds = SeasonAnalytics.fromEvents([
        const SportEvent(id: '1', homeTeam: 'A', awayTeam: 'B', homeScore: 1, awayScore: 0, date: '2025-01-05'),
        const SportEvent(id: '2', homeTeam: 'B', awayTeam: 'A', homeScore: 1, awayScore: 1, date: '2025-01-12'),
      ]);
      expect(noRounds.roundsFromApi, isFalse);
      expect(noRounds.rounds.map((r) => r.label), ['05/01', '12/01']);
    });

    test('deduplicates events by id', () {
      final duplicated = SeasonAnalytics.fromEvents([...events, events.first]);
      expect(duplicated.scoredEvents, hasLength(3));
    });
  });

  group('ranking filters', () {
    final big = SeasonAnalytics.fromEvents(buildSeasonFixture(teams: 20, rounds: 4));

    test('all keeps every team', () {
      expect(RankingFilter.all.apply(big.standings), hasLength(20));
    });

    test('top N keeps the first N positions', () {
      expect(RankingFilter.top5.apply(big.standings).map((t) => t.rank), [1, 2, 3, 4, 5]);
      expect(RankingFilter.top10.apply(big.standings), hasLength(10));
      expect(RankingFilter.top15.apply(big.standings).last.rank, 15);
    });

    test('bottom 5 keeps the last five positions', () {
      expect(RankingFilter.bottom5.apply(big.standings).map((t) => t.rank), [16, 17, 18, 19, 20]);
    });

    test('filters never fail with fewer teams than requested', () {
      expect(RankingFilter.top15.apply(analytics.standings), hasLength(3));
      expect(RankingFilter.bottom5.apply(analytics.standings), hasLength(3));
    });
  });

  group('empty and incomplete data', () {
    test('empty input produces empty analytics', () {
      final empty = SeasonAnalytics.fromEvents(const []);
      expect(empty.isEmpty, isTrue);
      expect(empty.standings, isEmpty);
      expect(empty.rounds, isEmpty);
      expect(empty.averageGoals, 0);
    });

    test('only unscored matches produce no statistics', () {
      final unscored = SeasonAnalytics.fromEvents([_e('1', 'A', 'B', null, null)]);
      expect(unscored.isEmpty, isTrue);
      expect(unscored.standings, isEmpty);
      expect(unscored.unscoredEvents, 1);
    });

    test('postponed matches are not counted even with a score', () {
      final event = SportEvent.fromJson(eventJson()..['strPostponed'] = 'yes');
      expect(event.hasScore, isFalse);
    });
  });

  group('JSON parsing', () {
    test('parses string numbers and ids', () {
      final event = SportEvent.fromJson(eventJson(homeScore: '3', awayScore: 0, round: '7'));
      expect(event.homeScore, 3);
      expect(event.awayScore, 0);
      expect(event.round, 7);
      expect(event.kickoff, DateTime.utc(2025, 8, 16, 14));
      expect(event.kickoffHourUtc, 14);
    });

    test('treats empty scores and special rounds as missing', () {
      final event = SportEvent.fromJson(eventJson(homeScore: '', awayScore: null, round: '0'));
      expect(event.hasScore, isFalse);
      expect(event.round, isNull);
    });

    test('keeps the team badge from the teams endpoint', () {
      final withBadges = SeasonAnalytics.fromEvents(
        events,
        teams: const [Team(id: 'A', name: 'A', badge: 'https://example.org/a.png')],
      );
      expect(withBadges.team('A')!.badge, 'https://example.org/a.png');
      expect(withBadges.team('B')!.badge, isNull);
    });
  });

  group('match level mappers', () {
    test('score frequency, margins and matrix use only real scores', () {
      expect(ChartDataMapper.scorelineFrequency(events).map((p) => p.label), ['0-0', '2-1', '3-0']);
      final margins = ChartDataMapper.winsByMargin(events);
      expect(margins.map((p) => p.value), [1, 0, 1, 0]);
      expect(ChartDataMapper.scoreMatrix(events), hasLength(3));
      expect(ChartDataMapper.totalGoals(events), [3, 0, 3]);
    });

    test('over/under split', () {
      final overUnder = ChartDataMapper.overUnder(events);
      expect(overUnder.map((p) => p.value), [2, 1]);
    });

    test('head to head and performance profile', () {
      expect(TeamSeriesMapper.headToHead(a, b).map((r) => r.value), [1, 0, 0]);
      final profile = TeamSeriesMapper.performanceProfile(analytics, a);
      expect(profile, hasLength(6));
      expect(profile.every((item) => item.value >= 0 && item.value <= 100), isTrue);
    });
  });
}
