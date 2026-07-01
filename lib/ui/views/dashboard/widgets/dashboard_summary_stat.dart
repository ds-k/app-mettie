import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class DashboardSummaryStat extends StatelessWidget {
  final String label;
  final String value;

  const DashboardSummaryStat({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: kOnDark,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFeatures: kTabularFigures,
          ),
        ),
      ],
    );
  }
}
