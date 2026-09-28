import 'package:flutter/material.dart';

import '../../data/repositories/sports_repository.dart';
import '../charts/catalog/chart_catalog.dart';
import '../charts/catalog/chart_definition.dart';
import '../state/dashboard_controller.dart';
import '../widgets/chart_definition_card.dart';
import '../widgets/filter_bar.dart';
import '../widgets/status_view.dart';
import 'summary_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.repository});

  /// Permite inyectar un repositorio (p. ej. con un cliente HTTP de pruebas).
  final SportsRepository? repository;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _controller = DashboardController(repository: widget.repository);

  /// null = Resumen; en otro caso, la categoría de gráficos abierta.
  ChartCategory? _category;

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(ChartCategory? category) => setState(() => _category = category);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sports Analytics'),
        actions: [IconButton(onPressed: _controller.refresh, icon: const Icon(Icons.refresh), tooltip: 'Actualizar')],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          if (c.leagues.isEmpty && c.loadingLeagues) return const LoadingView();
          if (c.leagues.isEmpty && c.error != null) return ErrorView(message: c.error!, onRetry: c.loadLeagues);
          if (c.leagues.isEmpty) return const LoadingView();
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1100;
              final content = _Content(controller: c, category: _category, wide: wide, onOpen: _open);
              if (!wide) return content;
              return Row(
                children: [
                  _SideNavigation(selected: _category, onSelect: _open),
                  const VerticalDivider(width: 1),
                  Expanded(child: content),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({required this.selected, required this.onSelect});
  final ChartCategory? selected;
  final ValueChanged<ChartCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget item(ChartCategory? category, IconData icon, String label) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        dense: true,
        selected: selected == category,
        selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon),
        title: Text(label),
        onTap: () => onSelect(category),
      ),
    );
    return SizedBox(
      width: 250,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          item(null, Icons.dashboard_rounded, 'Resumen'),
          const Divider(indent: 16, endIndent: 16),
          for (final category in ChartCategory.values)
            item(category, category.icon, '${category.label} (${ChartCatalog.byCategory(category).length})'),
        ],
      ),
    );
  }
}

class _SectionChips extends StatelessWidget {
  const _SectionChips({required this.selected, required this.onSelect});
  final ChartCategory? selected;
  final ValueChanged<ChartCategory?> onSelect;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            avatar: const Icon(Icons.dashboard_rounded, size: 18),
            label: const Text('Resumen'),
            selected: selected == null,
            onSelected: (_) => onSelect(null),
          ),
        ),
        for (final category in ChartCategory.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(category.icon, size: 18),
              label: Text(category.label),
              selected: selected == category,
              onSelected: (_) => onSelect(category),
            ),
          ),
      ],
    ),
  );
}

class _Content extends StatelessWidget {
  const _Content({required this.controller, required this.category, required this.wide, required this.onOpen});

  final DashboardController controller;
  final ChartCategory? category;
  final bool wide;
  final ValueChanged<ChartCategory?> onOpen;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final theme = Theme.of(context);
    final definitions = category == null ? const <ChartDefinition>[] : ChartCatalog.byCategory(category!);
    return RefreshIndicator(
      onRefresh: c.refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1300 && c.hasData ? 2 : 1;
          final rows = (definitions.length / columns).ceil();
          final chartContext = c.chartContext;
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList.list(
                  children: [
                    Text(
                      category?.label ?? 'Panel de análisis deportivo',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Datos reales de TheSportsDB · ${c.league?.name ?? ''}${c.season == null ? '' : ' · ${c.season}'}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    _FilterPanel(controller: c),
                    const SizedBox(height: 12),
                    _DataStatus(controller: c),
                    if (!wide) ...[const SizedBox(height: 12), _SectionChips(selected: category, onSelect: onOpen)],
                    const SizedBox(height: 12),
                    if (category == null) SummarySection(controller: c, onOpenCategory: onOpen),
                  ],
                ),
              ),
              if (category != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  // Construcción perezosa: solo se crean los gráficos visibles.
                  sliver: SliverList.builder(
                    itemCount: rows,
                    itemBuilder: (context, row) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var col = 0; col < columns; col++) ...[
                            if (col > 0) const SizedBox(width: 16),
                            Expanded(
                              child: row * columns + col < definitions.length
                                  ? ChartDefinitionCard(
                                      key: ValueKey(definitions[row * columns + col].id),
                                      definition: definitions[row * columns + col],
                                      context: chartContext,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Text(
                    'Fuente: TheSportsDB · Gráficos: Syncfusion Flutter Charts',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({required this.controller});
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final standings = c.analytics.standings;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 900 ? (constraints.maxWidth - 36) / 4 : constraints.maxWidth;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: width,
                      child: LeagueSelector(leagues: c.leagues, selected: c.league, onChanged: c.selectLeague),
                    ),
                    SizedBox(
                      width: width,
                      child: SeasonSelector(seasons: c.seasons, selected: c.season, onChanged: c.selectSeason),
                    ),
                    SizedBox(
                      width: width,
                      child: TeamSelector(teams: standings, selected: c.team, onChanged: c.selectTeam),
                    ),
                    SizedBox(
                      width: width,
                      child: CompareSelector(teams: standings, selected: c.compared, onChanged: c.setCompared),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RankingFilterSelector(selected: c.filter, onChanged: c.setFilter),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DataStatus extends StatelessWidget {
  const _DataStatus({required this.controller});
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final data = c.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.loadingSeason || c.completing) const LinearProgressIndicator(),
        if (c.error != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.warning_amber_rounded),
              title: Text(c.error!),
              trailing: TextButton(onPressed: c.refresh, child: const Text('Reintentar')),
            ),
          ),
        if (data != null && data.events.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.dataset_rounded, size: 20),
                  Text(
                    '${data.events.length} partidos descargados (${data.scoredEvents} con marcador) · '
                    'Endpoints: ${data.sources.join(', ')}',
                  ),
                  if (!c.completed)
                    Tooltip(
                      message:
                          'Consulta eventsround jornada a jornada (≈2 s entre peticiones para respetar '
                          'el límite gratuito) y añade solo partidos reales que falten.',
                      child: OutlinedButton.icon(
                        onPressed: c.completing ? null : c.completeSeason,
                        icon: const Icon(Icons.playlist_add_check_rounded),
                        label: const Text('Completar temporada por jornadas'),
                      ),
                    ),
                  if (c.completionStatus != null)
                    Text(c.completionStatus!, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
