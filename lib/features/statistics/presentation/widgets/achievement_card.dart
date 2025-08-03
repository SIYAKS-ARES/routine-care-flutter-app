import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../providers/statistics_provider.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const AchievementCard({
    super.key,
    required this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: achievement.isUnlocked ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: achievement.isUnlocked
              ? _getAchievementColor(achievement.type).withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: achievement.isUnlocked ? 2 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: achievement.isUnlocked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getAchievementColor(achievement.type)
                        .withValues(alpha: 0.05),
                    _getAchievementColor(achievement.type)
                        .withValues(alpha: 0.1),
                  ],
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Achievement Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: achievement.isUnlocked
                      ? _getAchievementColor(achievement.type)
                          .withValues(alpha: 0.2)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      _getAchievementIcon(achievement.iconName),
                      color: achievement.isUnlocked
                          ? _getAchievementColor(achievement.type)
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                      size: 24,
                    ),
                    if (achievement.isUnlocked)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Achievement Title
              Text(
                achievement.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: achievement.isUnlocked
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Achievement Description
              Text(
                achievement.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: achievement.isUnlocked
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Progress indicator
              if (!achievement.isUnlocked) ...[
                LinearProgressIndicator(
                  value: achievement.progressPercentage,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    _getAchievementColor(achievement.type)
                        .withValues(alpha: 0.7),
                  ),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 4),
                Text(
                  '${achievement.progress}/${achievement.target}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                // Unlock date
                if (achievement.unlockedAt != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: _getAchievementColor(achievement.type)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Unlocked ${DateFormat('MMM d').format(achievement.unlockedAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getAchievementColor(achievement.type),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getAchievementColor(AchievementType type) {
    switch (type) {
      case AchievementType.streak:
        return Colors.orange;
      case AchievementType.completion:
        return Colors.green;
      case AchievementType.consistency:
        return Colors.blue;
      case AchievementType.milestone:
        return Colors.purple;
    }
  }

  IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'emoji_events':
        return Icons.emoji_events;
      case 'military_tech':
        return Icons.military_tech;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'diamond':
        return Icons.diamond;
      case 'star':
        return Icons.star;
      case 'trending_up':
        return Icons.trending_up;
      case 'confirmation_number':
        return Icons.confirmation_number;
      case 'rocket_launch':
        return Icons.rocket_launch;
      default:
        return Icons.emoji_events;
    }
  }
}
