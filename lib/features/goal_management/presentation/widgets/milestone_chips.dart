import 'package:flutter/material.dart';
import '../../../../shared/models/goal_model.dart';

class MilestoneChips extends StatelessWidget {
  final List<Milestone> milestones;
  final int maxVisible;
  final bool showProgress;

  const MilestoneChips({
    super.key,
    required this.milestones,
    this.maxVisible = 3,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) return const SizedBox.shrink();

    final visibleMilestones = milestones.take(maxVisible).toList();
    final remainingCount = milestones.length - maxVisible;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ...visibleMilestones.map((milestone) => _buildMilestoneChip(
              context,
              milestone,
            )),
        if (remainingCount > 0) _buildMoreChip(context, remainingCount),
      ],
    );
  }

  Widget _buildMilestoneChip(BuildContext context, Milestone milestone) {
    final theme = Theme.of(context);
    final isCompleted = milestone.isCompleted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Icon(
            isCompleted ? Icons.check_circle : milestone.icon ?? Icons.flag,
            size: 12,
            color: isCompleted ? Colors.green : Colors.grey[600],
          ),

          const SizedBox(width: 4),

          // Name
          Text(
            milestone.name,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isCompleted ? Colors.green : Colors.grey[600],
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),

          // Progress indicator
          if (showProgress && !isCompleted) ...[
            const SizedBox(width: 4),
            Text(
              '${milestone.currentProgress}/${milestone.targetValue}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 9,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoreChip(BuildContext context, int count) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        '+$count daha',
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.blue,
        ),
      ),
    );
  }
}
