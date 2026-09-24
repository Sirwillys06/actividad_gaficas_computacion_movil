import 'package:flutter/material.dart';

class ChartCardWrapper extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget chart;
  final double aspectRatio;
  const ChartCardWrapper({super.key, required this.title, this.subtitle = '', required this.chart, this.aspectRatio = 1.6});
  @override Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.all(8), elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        if (subtitle.isNotEmpty) Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        SizedBox(height: 200, child: chart),
      ])),
  );
}
