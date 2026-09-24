import 'package:flutter/material.dart';

/// Tarjeta estándar para envolver cualquier gráfico de `graphic`
/// con título, descripción y una altura fija para el lienzo.
class ChartCardWrapper extends StatelessWidget {
  final String title;
  final String description;
  final Widget chart;
  final double height;

  const ChartCardWrapper({
    super.key,
    required this.title,
    required this.description,
    required this.chart,
    this.height = 320,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 12),
            SizedBox(height: height, child: chart),
          ],
        ),
      ),
    );
  }
}
