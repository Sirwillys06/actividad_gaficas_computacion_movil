import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:actividad_graficos/syncfusion_flutter_charts/data/models/league.dart';
import 'package:actividad_graficos/syncfusion_flutter_charts/data/repositories/sports_repository.dart';
import 'package:actividad_graficos/syncfusion_flutter_charts/data/services/sports_api_service.dart';

import 'support/season_fixture.dart';

void main() {
  const league = League(id: '4328', name: 'English Premier League', country: 'England');

  SportsRepository repositoryFor(http.Client client) => SportsRepository(
    service: SportsApiService(client: client),
    roundInterval: Duration.zero,
  );

  test('caches responses and shares requests in flight', () async {
    var calls = 0;
    final repository = repositoryFor(
      MockClient((request) async {
        calls++;
        return http.Response(
          jsonEncode({
            'events': [eventJson()],
          }),
          200,
        );
      }),
    );
    final results = await Future.wait([
      repository.getSeasonEvents('4328', '2025-2026'),
      repository.getSeasonEvents('4328', '2025-2026'),
    ]);
    await repository.getSeasonEvents('4328', '2025-2026');
    expect(results.first, hasLength(1));
    expect(calls, 1);
  });

  test('does not cache errors', () async {
    var calls = 0;
    final repository = repositoryFor(
      MockClient((request) async {
        calls++;
        return calls == 1 ? http.Response('boom', 500) : http.Response(jsonEncode({'events': []}), 200);
      }),
    );
    await expectLater(repository.getSeasonEvents('4328', '2025'), throwsA(isA<SportsApiException>()));
    expect(await repository.getSeasonEvents('4328', '2025'), isEmpty);
    expect(calls, 2);
  });

  test('handles "No data" strings, empty bodies and rate limits', () async {
    final responses = [
      http.Response(jsonEncode({'events': 'No data'}), 200),
      http.Response('', 200),
      http.Response('', 429),
    ];
    final service = SportsApiService(client: MockClient((_) async => responses.removeAt(0)));
    expect(await service.getSeasonEvents('1', 's'), isEmpty);
    expect(await service.getSeasonEvents('1', 's'), isEmpty);
    await expectLater(
      service.getSeasonEvents('1', 's'),
      throwsA(isA<SportsApiException>().having((e) => e.message, 'message', contains('límite'))),
    );
  });

  test('filters leagues to soccer', () async {
    final repository = repositoryFor(
      MockClient(
        (_) async => http.Response(
          jsonEncode({
            'leagues': [
              {'idLeague': '1', 'strLeague': 'Liga', 'strSport': 'Soccer'},
              {'idLeague': '2', 'strLeague': 'NBA', 'strSport': 'Basketball'},
            ],
          }),
          200,
        ),
      ),
    );
    final leagues = await repository.getLeagues();
    expect(leagues.map((l) => l.name), ['Liga']);
  });

  test('completes a truncated season round by round with real events only', () async {
    final requested = <String>[];
    final repository = repositoryFor(
      MockClient((request) async {
        final path = request.url.pathSegments.last;
        requested.add('$path?${request.url.query}');
        if (path == 'eventsseason.php') {
          return http.Response(
            jsonEncode({
              'events': [eventJson(id: '1', round: '1')],
            }),
            200,
          );
        }
        if (path == 'eventsround.php') {
          final round = request.url.queryParameters['r'];
          if (round == '2') {
            return http.Response(
              jsonEncode({
                'events': [eventJson(id: '2', home: 'Chelsea', away: 'Arsenal', round: '2')],
              }),
              200,
            );
          }
          if (round == '1') {
            return http.Response(
              jsonEncode({
                'events': [eventJson(id: '1', round: '1')],
              }),
              200,
            );
          }
          return http.Response(jsonEncode({'events': null}), 200);
        }
        return http.Response(jsonEncode({'teams': null}), 200);
      }),
    );
    final initial = await repository.getSeasonData(league, '2025-2026');
    expect(initial.events, hasLength(1));

    final progress = <int>[];
    final completed = await repository.completeSeasonByRounds(initial, onProgress: (round, _) => progress.add(round));
    // Jornada 1 ya completa (2 equipos -> 1 partido): no se vuelve a pedir.
    expect(progress, [2, 3, 4]);
    expect(completed.events.map((e) => e.id).toSet(), {'1', '2'});
    expect(completed.sources, contains('eventsround'));
  });
}
