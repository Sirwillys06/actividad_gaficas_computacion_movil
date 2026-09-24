import 'package:flutter/material.dart';

class ChartSection extends StatelessWidget {
  final String title;
  final String description;
  final Widget chart;

  const ChartSection({
    super.key,
    required this.title,
    required this.description,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              description,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 20),

            chart,
          ],
        ),
      ),
    );
  }
}