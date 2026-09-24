import 'package:flutter/material.dart';

class CustomChartTooltip extends StatelessWidget {
  final String label;
  final String value;
  const CustomChartTooltip({super.key, required this.label, required this.value});
  @override Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
    child: Padding(padding: const EdgeInsets.all(8), child: Text('$label\n$value', style: const TextStyle(color: Colors.white))),
  );
}
