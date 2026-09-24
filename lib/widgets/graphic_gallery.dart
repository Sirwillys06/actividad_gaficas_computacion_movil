import 'package:flutter/material.dart';

import 'chart_entry.dart';

/// Renderiza todas las entradas de una categoría, agrupadas por familia
/// de gráfico (Barras, Líneas, Dashboard, etc.).
class GraphicGalleryPage extends StatelessWidget {
  final List<ChartEntry> entries;

  const GraphicGalleryPage({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final families = <String, List<ChartEntry>>{};
    for (final entry in entries) {
      families.putIfAbsent(entry.family, () => []).add(entry);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final family in families.keys) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Text(
              '$family (${families[family]!.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          for (final entry in families[family]!) entry.builder(context),
        ],
      ],
    );
  }
}
