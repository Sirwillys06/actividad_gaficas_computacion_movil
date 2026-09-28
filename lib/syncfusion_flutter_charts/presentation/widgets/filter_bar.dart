import 'package:flutter/material.dart';

import '../../data/models/league.dart';
import '../../data/models/ranking_filter.dart';
import '../../data/models/team_stats.dart';
import 'search_sheet.dart';
import 'team_badge.dart';

/// Botón-selector con aspecto de campo de formulario.
class SelectorButton extends StatelessWidget {
  const SelectorButton({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.leading,
    this.onPressed,
  });

  final String label;
  final String value;
  final IconData icon;
  final Widget? leading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onPressed,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: leading == null ? Icon(icon) : Padding(padding: const EdgeInsets.all(10), child: leading),
        suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
        enabled: onPressed != null,
      ),
      child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );
}

class LeagueSelector extends StatelessWidget {
  const LeagueSelector({super.key, required this.leagues, required this.selected, required this.onChanged});
  final List<League> leagues;
  final League? selected;
  final ValueChanged<League> onChanged;

  @override
  Widget build(BuildContext context) => SelectorButton(
    label: 'Competición',
    value: selected?.name ?? 'Selecciona una liga',
    icon: Icons.emoji_events_outlined,
    leading: selected == null ? null : TeamBadge(name: selected!.name, url: selected!.logo, size: 24),
    onPressed: leagues.isEmpty
        ? null
        : () async {
            final result = await SearchSheet.show<League>(
              context,
              title: 'Competiciones de fútbol (${leagues.length})',
              items: leagues,
              labelOf: (league) => league.name,
              subtitleOf: (league) => league.country.isEmpty ? null : league.country,
              initialSelection: [?selected],
            );
            if (result != null && result.isNotEmpty) onChanged(result.first);
          },
  );
}

class SeasonSelector extends StatelessWidget {
  const SeasonSelector({super.key, required this.seasons, required this.selected, required this.onChanged});
  final List<String> seasons;
  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    key: ValueKey('season-${seasons.length}-$selected'),
    initialValue: seasons.contains(selected) ? selected : null,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Temporada', prefixIcon: Icon(Icons.calendar_month_rounded)),
    items: [for (final season in seasons) DropdownMenuItem(value: season, child: Text(season))],
    onChanged: seasons.isEmpty
        ? null
        : (value) {
            if (value != null) onChanged(value);
          },
  );
}

class TeamSelector extends StatelessWidget {
  const TeamSelector({super.key, required this.teams, required this.selected, required this.onChanged});
  final List<TeamStats> teams;
  final TeamStats? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => SelectorButton(
    label: 'Equipo analizado',
    value: selected == null ? 'Ninguno' : '#${selected!.rank} ${selected!.name}',
    icon: Icons.shield_outlined,
    leading: selected == null ? null : TeamBadge(name: selected!.name, url: selected!.badge, size: 24),
    onPressed: teams.isEmpty
        ? null
        : () async {
            final result = await SearchSheet.show<TeamStats>(
              context,
              title: 'Buscar equipo (${teams.length})',
              items: teams,
              labelOf: (team) => team.name,
              subtitleOf: (team) => '#${team.rank} · ${team.points} pts · ${team.played} PJ',
              leadingOf: (team) => TeamBadge(name: team.name, url: team.badge),
              initialSelection: [?selected],
            );
            if (result != null && result.isNotEmpty) onChanged(result.first.key);
          },
  );
}

class CompareSelector extends StatelessWidget {
  const CompareSelector({
    super.key,
    required this.teams,
    required this.selected,
    required this.onChanged,
    this.max = 6,
  });

  final List<TeamStats> teams;
  final List<TeamStats> selected;
  final ValueChanged<List<String>> onChanged;
  final int max;

  @override
  Widget build(BuildContext context) => SelectorButton(
    label: 'Equipos comparados',
    value: selected.isEmpty ? 'Ninguno' : selected.map((team) => team.name).join(', '),
    icon: Icons.groups_rounded,
    onPressed: teams.isEmpty
        ? null
        : () async {
            final result = await SearchSheet.show<TeamStats>(
              context,
              title: 'Comparar equipos',
              items: teams,
              labelOf: (team) => team.name,
              subtitleOf: (team) => '#${team.rank} · ${team.points} pts',
              leadingOf: (team) => TeamBadge(name: team.name, url: team.badge),
              initialSelection: selected,
              multiple: true,
              maxSelection: max,
            );
            if (result != null) onChanged(result.map((team) => team.key).toList());
          },
  );
}

class RankingFilterSelector extends StatelessWidget {
  const RankingFilterSelector({super.key, required this.selected, required this.onChanged});
  final RankingFilter selected;
  final ValueChanged<RankingFilter> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      const Icon(Icons.filter_list_rounded, size: 18),
      for (final filter in RankingFilter.values)
        ChoiceChip(label: Text(filter.label), selected: filter == selected, onSelected: (_) => onChanged(filter)),
    ],
  );
}
