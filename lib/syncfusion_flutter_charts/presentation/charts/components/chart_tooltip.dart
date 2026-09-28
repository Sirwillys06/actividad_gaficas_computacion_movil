import 'package:flutter/material.dart';

/// Caja de tooltip común para los tooltips personalizados de Syncfusion.
class ChartTooltipBox extends StatelessWidget {
  const ChartTooltipBox(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF1E2A40),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white24),
    ),
    child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)),
  );
}
