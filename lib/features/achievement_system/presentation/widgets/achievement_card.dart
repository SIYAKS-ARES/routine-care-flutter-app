import 'package:flutter/material.dart';
import '../../../../shared/models/achievement_model.dart';
import '../../domain/entities/user_progress.dart';

class AchievementCard extends StatelessWidget {
  final AchievementModel achievement;
  final UserProgress userProgress;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.userProgress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnlocked = achievement.isUnlocked;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? achievement.color.withOpacity(0.3)
                : theme.colorScheme.onSurface.withOpacity(0.1),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? achievement.color.withOpacity(0.2)
                  : theme.colorScheme.onSurface.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradient background for unlocked
            if (isUnlocked)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      achievement.color.withOpacity(0.1),
                      achievement.color.withOpacity(0.05),
                    ],
                  ),
                ),
              ),

            // Locked overlay
            if (!isUnlocked)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: theme.colorScheme.onSurface.withOpacity(0.05),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and rarity
                  Row(
                    children: [
                      // Achievement icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? achievement.color.withOpacity(0.2)
                              : theme.colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          achievement.icon,
                          color: isUnlocked
                              ? achievement.color
                              : theme.colorScheme.onSurface.withOpacity(0.4),
                          size: 24,
                        ),
                      ),

                      const Spacer(),

                      // Rarity indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? _getRarityColor(achievement.rarity)
                                  .withOpacity(0.2)
                              : theme.colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getRarityName(achievement.rarity),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isUnlocked
                                ? _getRarityColor(achievement.rarity)
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    achievement.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isUnlocked
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    achievement.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isUnlocked
                          ? theme.colorScheme.onSurface.withOpacity(0.7)
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Bottom section
                  if (isUnlocked)
                    _buildUnlockedFooter(theme)
                  else
                    _buildProgressFooter(theme),
                ],
              ),
            ),

            // Lock indicator for locked achievements
            if (!isUnlocked)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedFooter(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: Colors.green,
        ),
        const SizedBox(width: 4),
        Text(
          'Açıldı',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          '${achievement.experiencePoints} XP',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressFooter(ThemeData theme) {
    // Simple progress calculation for routine completion
    int currentValue = 0;
    int targetValue = 1;

    if (achievement.unlockConditions.isNotEmpty) {
      final condition = achievement.unlockConditions.first;
      targetValue = condition.targetValue;

      switch (condition.type) {
        case UnlockConditionType.routineCompletion:
          currentValue = userProgress.routineCompletions;
          break;
        case UnlockConditionType.streakAchievement:
          currentValue = userProgress.longestStreak;
          break;
        default:
          currentValue = achievement.currentProgress;
      }
    }

    final progress =
        targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$currentValue/$targetValue',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(
            achievement.color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  String _getRarityName(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'ORTAK';
      case AchievementRarity.uncommon:
        return 'NADİR';
      case AchievementRarity.rare:
        return 'ENDER';
      case AchievementRarity.epic:
        return 'EPİK';
      case AchievementRarity.legendary:
        return 'EFSANE';
    }
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }
}
