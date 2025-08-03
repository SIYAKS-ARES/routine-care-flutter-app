import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CompletionChart extends StatelessWidget {
  final int completedDays;
  final int totalDays;

  const CompletionChart({
    super.key,
    required this.completedDays,
    required this.totalDays,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missedDays = totalDays - completedDays;
    final completionRate = totalDays > 0 ? completedDays / totalDays : 0.0;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 60,
              sections: [
                PieChartSectionData(
                  color: theme.colorScheme.primary,
                  value: completedDays.toDouble(),
                  title: '',
                  radius: 30,
                ),
                if (missedDays > 0)
                  PieChartSectionData(
                    color: theme.colorScheme.surfaceContainerHighest,
                    value: missedDays.toDouble(),
                    title: '',
                    radius: 25,
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                theme,
                color: theme.colorScheme.primary,
                label: 'Completed',
                value: '$completedDays days',
              ),
              const SizedBox(height: 8),
              _buildLegendItem(
                theme,
                color: theme.colorScheme.surfaceContainerHighest,
                label: 'Missed',
                value: '$missedDays days',
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '${(completionRate * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'Success Rate',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    ThemeData theme, {
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
