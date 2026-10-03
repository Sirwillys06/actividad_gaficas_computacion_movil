import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/stats_utils.dart';
import '../charts/catalog/chart_catalog.dart';
import '../charts/catalog/chart_definition.dart';
import '../state/dashboard_controller.dart';
import '../widgets/recent_matches_list.dart';
import '../widgets/standings_table.dart';
import '../widgets/status_view.dart';
import '../widgets/summary_card.dart';
import '../widgets/team_badge.dart';

/// Sección "Resumen": indicadores globales, tabla, últimos resultados y
/// acceso directo a las categorías de gráficos.
class SummarySection extends StatelessWidget {
  const SummarySection({super.key, required this.controller, required this.onOpenCategory});

  final DashboardController controller;
  final ValueChanged<ChartCategory> onOpenCategory;

  @override
  Widget build(BuildContext context) {
    final analytics = controller.analytics;
    if (analytics.isEmpty) {
      return Card(
        child: EmptyView(
          message: controller.loadingSeason
              ? 'Cargando partidos de la temporada…'
              : 'No hay partidos con marcador para esta liga y temporada.',
        ),
      );
    }
    final scored = analytics.scoredEvents.length;
    final leader = analytics.standings.first;
    final theme = Theme.of(context);
    final kpis = <(String, String, IconData)>[
      ('Equipos analizados', '${analytics.standings.length}', Icons.groups_rounded),
      ('Partidos con marcador', '$scored de ${analytics.allEvents.length}', Icons.scoreboard_rounded),
      ('${analytics.roundUnit}s', '${analytics.rounds.length}', Icons.event_repeat_rounded),
      ('Goles totales', '${analytics.totalGoals}', Icons.sports_soccer_rounded),
      ('Goles por partido', Formatters.decimal(analytics.averageGoals), Icons.speed_rounded),
      ('Victorias locales', Formatters.percent(StatsUtils.percent(analytics.homeWins, scored)), Icons.home_rounded),
      ('Empates', Formatters.percent(StatsUtils.percent(analytics.draws, scored)), Icons.drag_handle_rounded),
      (
        'Victorias visitantes',
        Formatters.percent(StatsUtils.percent(analytics.awayWins, scored)),
        Icons.flight_takeoff_rounded,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000 ? 4 : (constraints.maxWidth >= 560 ? 3 : 2);
        final cardWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final (label, value, icon) in kpis)
                  SizedBox(
                    width: cardWidth,
                    child: SummaryCard(label: label, value: value, icon: icon),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                leading: TeamBadge(name: leader.name, url: leader.badge, size: 40),
                title: Text('Líder: ${leader.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${leader.points} pts · ${leader.wins}V ${leader.draws}E ${leader.losses}D · DG ${Formatters.signed(leader.goalDifference)}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clasificación calculada',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Calculada con los partidos con marcador descargados (3/1/0; desempate por DG y GF). '
                      'Filtro activo: ${controller.filter.label}. Toca un equipo para analizarlo.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    StandingsTable(
                      teams: controller.chartContext.teams,
                      selectedKey: controller.team?.key,
                      onSelect: controller.selectTeam,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Últimos resultados',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    RecentMatchesList(events: analytics.scoredEvents),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Catálogo de análisis', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final category in ChartCategory.values)
                  SizedBox(
                    width: cardWidth,
                    child: Card(
                      child: ListTile(
                        leading: Icon(category.icon, color: theme.colorScheme.primary),
                        title: Text(category.label),
                        subtitle: Text('${ChartCatalog.byCategory(category).length} gráficos'),
                        onTap: () => onOpenCategory(category),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
