import 'package:flutter/material.dart';

import '../../core/theme/chart_palette.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/team_stats.dart';
import 'team_badge.dart';

/// Tabla de clasificación calculada con todos los equipos del filtro activo.
class StandingsTable extends StatelessWidget {
  const StandingsTable({super.key, required this.teams, this.selectedKey, this.onSelect});

  final List<TeamStats> teams;
  final String? selectedKey;
  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context) {
    const headers = ['#', 'Equipo', 'PJ', 'G', 'E', 'P', 'GF', 'GC', 'DG', 'Pts', 'Pts/PJ', 'Forma'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 18,
        headingRowHeight: 40,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 44,
        showCheckboxColumn: false,
        columns: [
          for (final header in headers)
            DataColumn(
              label: Text(header, style: const TextStyle(fontWeight: FontWeight.bold)),
              numeric: header != 'Equipo' && header != 'Forma',
            ),
        ],
        rows: [
          for (final team in teams)
            DataRow(
              selected: team.key == selectedKey,
              onSelectChanged: onSelect == null ? null : (_) => onSelect!(team.key),
              cells: [
                DataCell(Text('${team.rank}')),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TeamBadge(name: team.name, url: team.badge, size: 24),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(team.name, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                DataCell(Text('${team.played}')),
                DataCell(Text('${team.wins}')),
                DataCell(Text('${team.draws}')),
                DataCell(Text('${team.losses}')),
                DataCell(Text('${team.goalsFor}')),
                DataCell(Text('${team.goalsAgainst}')),
                DataCell(Text(Formatters.signed(team.goalDifference))),
                DataCell(Text('${team.points}', style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(Formatters.decimal(team.pointsPerMatch))),
                DataCell(FormStrip(matches: team.recentMatches)),
              ],
            ),
        ],
      ),
    );
  }
}

/// Últimos resultados como pastillas V/E/D.
class FormStrip extends StatelessWidget {
  const FormStrip({super.key, required this.matches});
  final List<TeamMatch> matches;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final match in matches)
        Tooltip(
          message: match.label,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: switch (match.outcome) {
                MatchOutcome.win => ChartPalette.win,
                MatchOutcome.draw => ChartPalette.draw,
                MatchOutcome.loss => ChartPalette.loss,
              },
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(switch (match.outcome) {
              MatchOutcome.win => 'V',
              MatchOutcome.draw => 'E',
              MatchOutcome.loss => 'D',
            }, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
        ),
    ],
  );
}
