import 'package:flutter/material.dart';

class ChartCard extends StatelessWidget {
  const ChartCard({super.key, required this.title, required this.description, required this.child});
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
        const SizedBox(height: 18),
        SizedBox(height: 300, child: child),
      ]),
    ),
  );
}
