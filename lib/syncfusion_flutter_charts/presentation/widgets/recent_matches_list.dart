import 'package:flutter/material.dart';

import '../../data/models/event.dart';
import 'team_badge.dart';

/// Últimos partidos con marcador (con escudos de ambos equipos).
class RecentMatchesList extends StatelessWidget {
  const RecentMatchesList({super.key, required this.events, this.limit = 10});

  final List<SportEvent> events;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final recent = events.reversed.take(limit).toList();
    return Column(
      children: [
        for (final event in recent)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    event.round == null ? (event.date ?? '') : 'J${event.round}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(event.homeTeam, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                TeamBadge(name: event.homeTeam, url: event.homeBadge, size: 22),
                Container(
                  width: 56,
                  alignment: Alignment.center,
                  child: Text(event.scoreLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                TeamBadge(name: event.awayTeam, url: event.awayBadge, size: 22),
                const SizedBox(width: 8),
                Expanded(child: Text(event.awayTeam, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
      ],
    );
  }
}
