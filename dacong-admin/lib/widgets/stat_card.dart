import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final double change;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final changeIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const Spacer(),
                Row(
                  children: [
                    Icon(changeIcon, size: 16, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '${change.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
