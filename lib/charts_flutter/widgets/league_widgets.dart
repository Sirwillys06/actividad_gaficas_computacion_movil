import 'package:flutter/material.dart';

import '../charts/chart_catalog.dart';
import '../charts/chart_models.dart';
import '../models/multi_league_dashboard_models.dart';
import '../services/multi_league_api_service.dart';
import '../theme/dashboard_theme.dart';
import 'team_badge.dart';

/// Portada: identidad del producto y acceso directo a cada liga.
class DashboardHero extends StatelessWidget {
  final List<LeagueConfig> leagues;
  final int openIndex;
  final ValueChanged<int> onSelect;

  const DashboardHero({
    super.key,
    required this.leagues,
    required this.openIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final perLeague = ChartCatalog.all.length;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DashboardColors.pitchDark, DashboardColors.pitch],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: DashboardColors.accent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.sports_soccer_rounded, color: DashboardColors.pitchDark),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'THE SPORTS ANALYTICS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Estadísticas de las 5 grandes ligas europeas · '
                          'Temporada ${MultiLeagueApiService.season}',
                          style: TextStyle(color: Color(0xFFB7D3C7), fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < leagues.length; i++)
                    _LeaguePill(
                      league: leagues[i],
                      selected: i == openIndex,
                      onTap: () => onSelect(i),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 18,
                runSpacing: 6,
                children: [
                  _HeroFact(icon: Icons.flag_outlined, text: '${leagues.length} ligas'),
                  _HeroFact(icon: Icons.insert_chart_outlined, text: '$perLeague gráficos por liga'),
                  _HeroFact(
                    icon: Icons.dashboard_customize_outlined,
                    text: '${perLeague * leagues.length} visualizaciones',
                  ),
                  const _HeroFact(icon: Icons.cloud_outlined, text: 'Datos reales: TheSportsDB'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaguePill extends StatelessWidget {
  final LeagueConfig league;
  final bool selected;
  final VoidCallback onTap;

  const _LeaguePill({required this.league, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(league.flag, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 7),
              Text(
                league.name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? DashboardColors.pitchDark : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroFact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroFact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: DashboardColors.accent),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Color(0xFFD5E6DE), fontSize: 11.5)),
      ],
    );
  }
}

/// Cabecera de cada liga en el acordeón.
class LeagueAccordionHeader extends StatelessWidget {
  final LeagueConfig league;
  final bool expanded;
  final VoidCallback onTap;

  const LeagueAccordionHeader({
    super.key,
    required this.league,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = expanded ? Colors.white : DashboardColors.ink;
    return Material(
      color: expanded ? DashboardColors.pitch : DashboardColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: expanded ? DashboardColors.pitch : DashboardColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: expanded
                      ? Colors.white.withValues(alpha: 0.12)
                      : DashboardColors.background,
                  shape: BoxShape.circle,
                ),
                child: Text(league.flag, style: const TextStyle(fontSize: 19)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      league.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                    Text(
                      '${league.country} · Temporada ${MultiLeagueApiService.season}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: expanded ? const Color(0xFFB7D3C7) : DashboardColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!expanded)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Text(
                    'Ver estadísticas',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.pitch,
                    ),
                  ),
                ),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: Icon(Icons.keyboard_arrow_down_rounded, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resumen de la liga abierta, calculado solo con la tabla (1 petición).
class LeagueOverview extends StatefulWidget {
  final MultiLeagueApiService apiService;
  final LeagueConfig league;

  const LeagueOverview({super.key, required this.apiService, required this.league});

  @override
  State<LeagueOverview> createState() => _LeagueOverviewState();
}

class _LeagueOverviewState extends State<LeagueOverview> {
  // Se guarda el Future para que cambiar de sección no reinicie el estado.
  late final Future<LeagueDashboardData> _future =
      widget.apiService.getLeagueData(widget.league, includeEvents: false);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LeagueDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _OverviewMessage(
            icon: Icons.cloud_off_rounded,
            text: 'No se pudo cargar la tabla de esta liga. Los gráficos '
                'muestran su propio estado.',
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }
        final standings = snapshot.data!.standings;
        if (standings.isEmpty) {
          return const _OverviewMessage(
            icon: Icons.hourglass_empty_rounded,
            text: 'TheSportsDB aún no publica la tabla de esta temporada.',
          );
        }

        final leader = standings.reduce((a, b) => a.rank <= b.rank ? a : b);
        final attack = standings.reduce((a, b) => b.goalsFor > a.goalsFor ? b : a);
        final defense = standings.reduce((a, b) => b.goalsAgainst < a.goalsAgainst ? b : a);
        final goals = standings.fold<int>(0, (s, t) => s + t.goalsFor);
        final matches = standings.fold<int>(0, (s, t) => s + t.played) ~/ 2;
        final maxPlayed = standings.fold<int>(0, (m, t) => t.played > m ? t.played : m);

        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 6
                : (constraints.maxWidth >= 640 ? 3 : 2);
            final width = (constraints.maxWidth - 10 * (columns - 1)) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatTile(
                  width: width,
                  label: 'Líder',
                  value: leader.team,
                  detail: '${leader.points} pts · ${leader.wins}V ${leader.draws}E ${leader.losses}D',
                  badge: leader.badge,
                  highlight: true,
                ),
                _StatTile(
                  width: width,
                  label: 'Mejor ataque',
                  value: attack.team,
                  detail: '${attack.goalsFor} goles a favor',
                  badge: attack.badge,
                ),
                _StatTile(
                  width: width,
                  label: 'Mejor defensa',
                  value: defense.team,
                  detail: '${defense.goalsAgainst} goles en contra',
                  badge: defense.badge,
                ),
                _StatTile(
                  width: width,
                  label: 'Equipos',
                  value: '${standings.length}',
                  detail: 'Jornada $maxPlayed disputada',
                  icon: Icons.groups_2_outlined,
                ),
                _StatTile(
                  width: width,
                  label: 'Partidos jugados',
                  value: '$matches',
                  detail: 'según la tabla',
                  icon: Icons.stadium_outlined,
                ),
                _StatTile(
                  width: width,
                  label: 'Goles',
                  value: '$goals',
                  detail: matches == 0
                      ? 'sin partidos'
                      : '${formatNumber(goals / matches, decimals: 2)} por partido',
                  icon: Icons.sports_soccer_rounded,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _OverviewMessage extends StatelessWidget {
  final IconData icon;
  final String text;

  const _OverviewMessage({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: DashboardColors.inkFaint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, color: DashboardColors.inkMuted)),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final String detail;
  final String? badge;
  final IconData? icon;
  final bool highlight;

  const _StatTile({
    required this.width,
    required this.label,
    required this.value,
    required this.detail,
    this.badge,
    this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTeam = icon == null;
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? DashboardColors.accent.withValues(alpha: 0.10) : DashboardColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? DashboardColors.accent.withValues(alpha: 0.5) : DashboardColors.border,
        ),
      ),
      child: Row(
        children: [
          if (isTeam)
            TeamBadge(badgeUrl: badge, name: value, size: 30)
          else
            Icon(icon, size: 24, color: DashboardColors.pitch),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isTeam ? 13.5 : 18,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.ink,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: DashboardColors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pestañas de sección. Se fijan arriba al hacer scroll para que siempre se
/// vea qué liga y qué sección se están explorando.
class SectionTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final LeagueConfig league;
  final DashboardSection selected;
  final ValueChanged<DashboardSection> onSelected;

  const SectionTabsHeaderDelegate({
    required this.league,
    required this.selected,
    required this.onSelected,
  });

  static const double height = 60;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: DashboardColors.background.withValues(alpha: 0.97),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (overlapsContent || shrinkOffset > 0) ...[
                Text(league.flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final section in DashboardSection.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _SectionTab(
                            section: section,
                            selected: section == selected,
                            count: ChartCatalog.forSection(section).length,
                            onTap: () => onSelected(section),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SectionTabsHeaderDelegate old) =>
      old.selected != selected || old.league.id != league.id;
}

class _SectionTab extends StatelessWidget {
  final DashboardSection section;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  const _SectionTab({
    required this.section,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : DashboardColors.ink;
    return Material(
      color: selected ? DashboardColors.pitch : DashboardColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? DashboardColors.pitch : DashboardColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(section.icon, size: 16, color: selected ? DashboardColors.accent : DashboardColors.pitch),
              const SizedBox(width: 6),
              Text(
                section.label,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.18) : DashboardColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Introducción de la sección activa.
class SectionIntro extends StatelessWidget {
  final LeagueConfig league;
  final DashboardSection section;

  const SectionIntro({super.key, required this.league, required this.section});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(section.icon, size: 20, color: DashboardColors.pitch),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12.5, color: DashboardColors.inkMuted),
              children: [
                TextSpan(
                  text: '${league.name} › ${section.label}  ',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.ink,
                  ),
                ),
                TextSpan(text: section.description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
