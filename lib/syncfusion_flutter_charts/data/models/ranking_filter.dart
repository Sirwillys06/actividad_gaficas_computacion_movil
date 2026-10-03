import 'team_stats.dart';

/// Filtros globales de la clasificación. Se aplican sobre la tabla ya
/// ordenada, por lo que Top/Bottom siempre respetan la posición real.
enum RankingFilter {
  all('Todos'),
  top5('Top 5'),
  top10('Top 10'),
  top15('Top 15'),
  bottom5('Bottom 5');

  const RankingFilter(this.label);
  final String label;

  List<TeamStats> apply(List<TeamStats> standings) => switch (this) {
    RankingFilter.all => standings,
    RankingFilter.top5 => standings.take(5).toList(),
    RankingFilter.top10 => standings.take(10).toList(),
    RankingFilter.top15 => standings.take(15).toList(),
    RankingFilter.bottom5 => standings.length <= 5 ? standings : standings.sublist(standings.length - 5),
  };
}
