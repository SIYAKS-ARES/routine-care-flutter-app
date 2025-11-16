import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class MonthSummary extends StatelessWidget {
  final Map<DateTime, int> datasets;
  final DateTime startDate;

  const MonthSummary({
    super.key,
    required this.datasets,
    required this.startDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Activity Overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            HeatMapCalendar(
              datasets: datasets,
              colorMode: ColorMode.color,
              defaultColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              textColor: theme.colorScheme.onSurfaceVariant,
              showColorTip: false,
              size: 30,
              fontSize: 12,
              weekTextColor: theme.colorScheme.onSurfaceVariant,
              monthFontSize: 14,
              colorsets: {
                1: theme.colorScheme.primary.withValues(alpha: 0.1),
                2: theme.colorScheme.primary.withValues(alpha: 0.2),
                3: theme.colorScheme.primary.withValues(alpha: 0.3),
                4: theme.colorScheme.primary.withValues(alpha: 0.4),
                5: theme.colorScheme.primary.withValues(alpha: 0.5),
                6: theme.colorScheme.primary.withValues(alpha: 0.6),
                7: theme.colorScheme.primary.withValues(alpha: 0.7),
                8: theme.colorScheme.primary.withValues(alpha: 0.8),
                9: theme.colorScheme.primary.withValues(alpha: 0.9),
                10: theme.colorScheme.primary,
              },
            ),
            const SizedBox(height: 12),
            _buildLegend(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Less',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Row(
          children: List.generate(5, (index) {
            final alpha = (index + 1) * 0.2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: alpha),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        Text(
          'More',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
