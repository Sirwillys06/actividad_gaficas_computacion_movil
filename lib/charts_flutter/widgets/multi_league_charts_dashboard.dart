import 'package:flutter/material.dart';

import '../charts/chart_catalog.dart';
import '../charts/chart_models.dart';
import '../models/multi_league_dashboard_models.dart';
import '../services/multi_league_api_service.dart';
import '../theme/dashboard_theme.dart';
import 'chart_card.dart';
import 'league_widgets.dart';

/// Dashboard de las 5 grandes ligas.
///
/// Acordeón → liga abierta → sección → gráfico → carga bajo demanda → caché
/// → render. Solo la liga abierta construye tarjetas y el SliverGrid solo
/// construye las visibles; nada se descarga al iniciar salvo la tabla de la
/// liga abierta por defecto.
class MultiLeagueChartsDashboard extends StatefulWidget {
  final MultiLeagueApiService apiService;
  final List<LeagueConfig> leagues;

  const MultiLeagueChartsDashboard({
    super.key,
    required this.apiService,
    required this.leagues,
  });

  @override
  State<MultiLeagueChartsDashboard> createState() => _MultiLeagueChartsDashboardState();
}

class _MultiLeagueChartsDashboardState extends State<MultiLeagueChartsDashboard> {
  int _openIndex = 0;
  DashboardSection _section = DashboardSection.rendimiento;
  late final List<GlobalKey> _headerKeys =
      List.generate(widget.leagues.length, (_) => GlobalKey());

  void _toggle(int index) {
    setState(() {
      if (_openIndex == index) {
        _openIndex = -1;
      } else {
        _openIndex = index;
        _section = DashboardSection.rendimiento;
      }
    });
  }

  /// Desde la portada: abre la liga y desplaza la vista hasta ella.
  void _jumpTo(int index) {
    setState(() {
      _openIndex = index;
      _section = DashboardSection.rendimiento;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _headerKeys[index].currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  /// Numeración global 1..16 dentro de la liga (básicos 1-8, avanzados 9-16).
  int _numberOf(ChartDefinition definition) => ChartCatalog.all.indexOf(definition) + 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DashboardHero(
              leagues: widget.leagues,
              openIndex: _openIndex,
              onSelect: _jumpTo,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          for (var index = 0; index < widget.leagues.length; index++) ...[
            _constrained(
              SliverToBoxAdapter(
                child: Padding(
                  key: _headerKeys[index],
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LeagueAccordionHeader(
                    league: widget.leagues[index],
                    expanded: _openIndex == index,
                    onTap: () => _toggle(index),
                  ),
                ),
              ),
            ),
            if (_openIndex == index) ..._openLeagueSlivers(widget.leagues[index]),
          ],
          const SliverToBoxAdapter(child: _Footer()),
        ],
      ),
    );
  }

  List<Widget> _openLeagueSlivers(LeagueConfig league) {
    final definitions = ChartCatalog.forSection(_section);
    return [
      _constrained(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: LeagueOverview(
              key: ValueKey('overview-${league.id}'),
              apiService: widget.apiService,
              league: league,
            ),
          ),
        ),
      ),
      SliverPersistentHeader(
        pinned: true,
        delegate: SectionTabsHeaderDelegate(
          league: league,
          selected: _section,
          onSelected: (section) => setState(() => _section = section),
        ),
      ),
      _constrained(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
            child: SectionIntro(league: league, section: _section),
          ),
        ),
      ),
      _constrained(
        SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 640,
            mainAxisExtent: 560,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: definitions.length,
          itemBuilder: (context, i) {
            final definition = definitions[i];
            return LazyChartCard(
              key: ValueKey('${league.id}-${definition.id}'),
              apiService: widget.apiService,
              league: league,
              definition: definition,
              number: _numberOf(definition),
            );
          },
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 28)),
    ];
  }

  /// Centra el contenido con un ancho máximo legible en pantallas grandes.
  Widget _constrained(Widget sliver) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final gutter = width > 1312 ? (width - 1280) / 2 : 16.0;
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: sliver,
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Text(
        'Datos: TheSportsDB (lookuptable.php y eventsseason.php) · '
        'Temporada ${MultiLeagueApiService.season} · '
        'Gráficos: charts_flutter_updated',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: DashboardColors.inkFaint),
      ),
    );
  }
}
