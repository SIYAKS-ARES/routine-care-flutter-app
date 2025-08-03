import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/goal_model.dart';
import '../providers/goal_provider.dart';
import 'goal_progress_indicator.dart';
import 'milestone_chips.dart';

class GoalCard extends ConsumerWidget {
  final GoalModel goal;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool isCompact;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: goal.difficultyColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, ref, theme),

              if (!isCompact) ...[
                const SizedBox(height: 12),

                // Description
                if (goal.description.isNotEmpty) _buildDescription(theme),

                const SizedBox(height: 12),

                // Progress
                _buildProgress(theme),

                const SizedBox(height: 12),

                // Milestones
                if (goal.milestones.isNotEmpty) _buildMilestones(),

                const SizedBox(height: 12),

                // Time info
                _buildTimeInfo(theme),

                if (showActions) ...[
                  const SizedBox(height: 16),
                  _buildActions(context, ref, theme),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Row(
      children: [
        // Goal icon/reward icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: goal.difficultyColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            goal.rewardIcon ?? Icons.flag,
            color: goal.difficultyColor,
            size: 20,
          ),
        ),

        const SizedBox(width: 12),

        // Goal name and type
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color:
                      goal.status == GoalStatus.completed ? Colors.green : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    goal.typeName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: goal.difficultyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      goal.difficultyName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: goal.difficultyColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Status badge
        _buildStatusBadge(theme),
      ],
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    Color color;
    IconData icon;
    String text;

    switch (goal.status) {
      case GoalStatus.active:
        color = Colors.blue;
        icon = Icons.play_arrow;
        text = 'Aktif';
        break;
      case GoalStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'Tamamlandı';
        break;
      case GoalStatus.paused:
        color = Colors.orange;
        icon = Icons.pause;
        text = 'Duraklatıldı';
        break;
      case GoalStatus.failed:
        color = Colors.red;
        icon = Icons.close;
        text = 'Başarısız';
        break;
      case GoalStatus.expired:
        color = Colors.grey;
        icon = Icons.access_time;
        text = 'Süresi Doldu';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(ThemeData theme) {
    return Text(
      goal.description,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProgress(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'İlerleme',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${goal.currentProgress}/${goal.targetValue}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: goal.difficultyColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GoalProgressIndicator(
          progress: goal.progressPercentage / 100,
          color: goal.difficultyColor,
          backgroundColor: goal.difficultyColor.withOpacity(0.1),
          height: 6,
        ),
        const SizedBox(height: 4),
        Text(
          '${goal.progressPercentage.toStringAsFixed(0)}% tamamlandı',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestones() {
    if (goal.milestones.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ara Hedefler',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        MilestoneChips(
          milestones: goal.milestones,
          maxVisible: 3,
        ),
      ],
    );
  }

  Widget _buildTimeInfo(ThemeData theme) {
    return Row(
      children: [
        // Start date
        _buildTimeInfoItem(
          icon: Icons.calendar_today,
          label: 'Başlangıç',
          value: _formatDate(goal.startDate),
          theme: theme,
        ),

        if (goal.hasDeadline) ...[
          const SizedBox(width: 16),
          _buildTimeInfoItem(
            icon: goal.isOverdue ? Icons.warning : Icons.schedule,
            label: goal.isOverdue ? 'Gecikti' : 'Bitiş',
            value: _formatDate(goal.endDate!),
            theme: theme,
            isWarning: goal.isOverdue,
          ),
        ],

        if (goal.daysRemaining != null && !goal.isCompleted) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: goal.daysRemaining! <= 3
                  ? Colors.red.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${goal.daysRemaining} gün kaldı',
              style: theme.textTheme.bodySmall?.copyWith(
                color: goal.daysRemaining! <= 3 ? Colors.red : Colors.blue,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    bool isWarning = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isWarning
              ? Colors.red
              : theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isWarning ? Colors.red : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Row(
      children: [
        // Status action button
        if (goal.status == GoalStatus.active)
          _buildActionButton(
            icon: Icons.pause,
            label: 'Duraklat',
            color: Colors.orange,
            onPressed: () => _pauseGoal(ref),
          ),

        if (goal.status == GoalStatus.paused)
          _buildActionButton(
            icon: Icons.play_arrow,
            label: 'Devam Et',
            color: Colors.green,
            onPressed: () => _resumeGoal(ref),
          ),

        if (goal.status == GoalStatus.active && !goal.isCompleted)
          _buildActionButton(
            icon: Icons.check,
            label: 'Tamamla',
            color: Colors.green,
            onPressed: () => _completeGoal(ref),
          ),

        const Spacer(),

        // Edit button
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: onEdit,
            tooltip: 'Düzenle',
          ),

        // Delete button
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            color: Colors.red,
            onPressed: () => _showDeleteDialog(context),
            tooltip: 'Sil',
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          textStyle: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _pauseGoal(WidgetRef ref) {
    ref.read(goalProvider.notifier).pauseGoal(goal.id);
  }

  void _resumeGoal(WidgetRef ref) {
    ref.read(goalProvider.notifier).resumeGoal(goal.id);
  }

  void _completeGoal(WidgetRef ref) {
    ref.read(goalProvider.notifier).completeGoal(goal.id);
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hedefi Sil'),
        content:
            Text('${goal.name} hedefini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
