import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';
import 'team_badge.dart';

class TooltipRow {
  final String label;
  final String value;
  final Color? color;
  final bool emphasized;

  const TooltipRow(this.label, this.value, {this.color, this.emphasized = false});
}

/// Contenido de un tooltip, independiente del tipo de gráfico.
class TooltipContent {
  final String title;

  /// Si se indica, se muestra el escudo junto al título.
  final bool showBadge;
  final String? badgeUrl;
  final String? subtitle;
  final List<TooltipRow> rows;
  final List<String> notes;

  const TooltipContent({
    required this.title,
    this.showBadge = false,
    this.badgeUrl,
    this.subtitle,
    this.rows = const [],
    this.notes = const [],
  });
}

/// Tooltip común a los 80 gráficos: mismo estilo para equipos, fechas y
/// composiciones.
class ChartTooltip extends StatelessWidget {
  final TooltipContent content;

  const ChartTooltip({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minWidth: 170, maxWidth: 240),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: DashboardColors.pitchDark,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              blurRadius: 18,
              offset: Offset(0, 8),
              color: Color(0x33000000),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (content.showBadge) ...[
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: TeamBadge(
                      badgeUrl: content.badgeUrl,
                      name: content.title,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    content.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (content.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                content.subtitle!,
                style: const TextStyle(color: Color(0xFF9FB8AE), fontSize: 10),
              ),
            ],
            if (content.rows.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final row in content.rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (row.color != null) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: row.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          row.label,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        row.value,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: row.emphasized ? 14 : 11.5,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (content.notes.isNotEmpty) ...[
              const SizedBox(height: 5),
              for (final note in content.notes)
                Text(
                  note,
                  style: const TextStyle(
                    color: Color(0xFF9FB8AE),
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
