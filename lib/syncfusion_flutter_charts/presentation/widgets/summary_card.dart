import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ])),
      ]),
    ),
  );
}
