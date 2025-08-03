import '../models/achievement_model.dart';
import '../models/routine_model.dart';
import '../models/user_level_model.dart';
import '../data/achievement_definitions.dart';
import '../../features/achievement_system/domain/entities/user_progress.dart';
import '../../features/achievement_system/domain/entities/achievement_statistics.dart';
import 'scoring_service.dart';

class AchievementService {
  /// Check all conditions and return newly unlocked achievements
  static Future<List<AchievementUnlockResult>> checkAndUnlockAchievements({
    required UserProgress userProgress,
    required List<AchievementModel> currentUserAchievements,
    String? triggeredByAction,
    Map<String, dynamic>? actionData,
  }) async {
    final unlockedResults = <AchievementUnlockResult>[];
    final availableAchievements = AchievementDefinitions.allAchievements;

    for (final achievement in availableAchievements) {
      // Skip already unlocked achievements
      if (currentUserAchievements
          .any((ua) => ua.id == achievement.id && ua.isUnlocked)) {
        continue;
      }

      // Check if achievement conditions are met
      final unlockResult = await _checkAchievementConditions(
        achievement: achievement,
        userProgress: userProgress,
        triggeredByAction: triggeredByAction,
        actionData: actionData,
      );

      if (unlockResult.shouldUnlock) {
        unlockedResults.add(unlockResult);
      }
    }

    return unlockedResults;
  }

  /// Update progress for specific achievement
  static AchievementModel updateAchievementProgress({
    required AchievementModel achievement,
    required UserProgress userProgress,
    String? triggeredByAction,
    Map<String, dynamic>? actionData,
  }) {
    if (achievement.isUnlocked) return achievement;

    int totalProgress = 0;

    for (final condition in achievement.unlockConditions) {
      final progress = _calculateConditionProgress(
        condition: condition,
        userProgress: userProgress,
        triggeredByAction: triggeredByAction,
        actionData: actionData,
      );
      totalProgress += progress;
    }

    // Take the maximum progress from any condition (OR logic)
    // Or sum all for AND logic - depends on achievement design
    final currentProgress = totalProgress
        .clamp(0, achievement.unlockConditions.first.targetValue)
        .toInt();

    return achievement.copyWith(currentProgress: currentProgress);
  }

  /// Check if achievement conditions are met
  static Future<AchievementUnlockResult> _checkAchievementConditions({
    required AchievementModel achievement,
    required UserProgress userProgress,
    String? triggeredByAction,
    Map<String, dynamic>? actionData,
  }) async {
    final conditionResults = <ConditionCheckResult>[];

    for (final condition in achievement.unlockConditions) {
      final result = _checkSingleCondition(
        condition: condition,
        userProgress: userProgress,
        triggeredByAction: triggeredByAction,
        actionData: actionData,
      );
      conditionResults.add(result);
    }

    // Check if all conditions are met (AND logic)
    final allConditionsMet = conditionResults.every((result) => result.isMet);

    return AchievementUnlockResult(
      achievement: achievement,
      shouldUnlock: allConditionsMet,
      conditionResults: conditionResults,
      unlockedAt: allConditionsMet ? DateTime.now() : null,
    );
  }

  /// Check single unlock condition
  static ConditionCheckResult _checkSingleCondition({
    required UnlockCondition condition,
    required UserProgress userProgress,
    String? triggeredByAction,
    Map<String, dynamic>? actionData,
  }) {
    int currentValue = 0;
    String progressText = '';

    switch (condition.type) {
      case UnlockConditionType.routineCompletion:
        currentValue = userProgress.routineCompletions;
        progressText =
            '$currentValue/${condition.targetValue} routines completed';
        break;

      case UnlockConditionType.goalCompletion:
        currentValue = userProgress.goalCompletions;
        progressText = '$currentValue/${condition.targetValue} goals completed';
        break;

      case UnlockConditionType.streakAchievement:
        currentValue = userProgress.longestStreak;
        progressText = '$currentValue/${condition.targetValue} day streak';
        break;

      case UnlockConditionType.categoryMastery:
        if (condition.categoryId != null) {
          currentValue =
              userProgress.getCategoryCompletions(condition.categoryId!);
          progressText =
              '$currentValue/${condition.targetValue} ${condition.categoryId} routines';
        }
        break;

      case UnlockConditionType.timeSpent:
        currentValue = userProgress.totalTimeSpent;
        progressText = '$currentValue/${condition.targetValue} minutes spent';
        break;

      case UnlockConditionType.consecutiveDays:
        currentValue = userProgress.consecutiveDays;
        progressText =
            '$currentValue/${condition.targetValue} consecutive days';
        break;

      case UnlockConditionType.perfectWeek:
        currentValue = userProgress.perfectWeekAchieved ? 1 : 0;
        progressText =
            currentValue > 0 ? 'Perfect week achieved' : 'No perfect week yet';
        break;

      case UnlockConditionType.custom:
        final result = _checkCustomCondition(
          condition: condition,
          userProgress: userProgress,
          triggeredByAction: triggeredByAction,
          actionData: actionData,
        );
        currentValue = result.currentValue;
        progressText = result.progressText;
        break;

      case UnlockConditionType.milestoneReached:
        // Handle milestone conditions
        currentValue = _checkMilestone(condition, userProgress);
        progressText = '$currentValue/${condition.targetValue} milestones';
        break;
    }

    final isMet = currentValue >= condition.targetValue;
    final progress = condition.targetValue > 0
        ? (currentValue / condition.targetValue).clamp(0.0, 1.0)
        : (isMet ? 1.0 : 0.0);

    return ConditionCheckResult(
      condition: condition,
      currentValue: currentValue,
      targetValue: condition.targetValue,
      isMet: isMet,
      progress: progress,
      progressText: progressText,
    );
  }

  /// Check custom conditions with special logic
  static CustomConditionResult _checkCustomCondition({
    required UnlockCondition condition,
    required UserProgress userProgress,
    String? triggeredByAction,
    Map<String, dynamic>? actionData,
  }) {
    final customData = condition.customData ?? {};
    final action = customData['action'] as String?;

    switch (action) {
      case 'create_routine':
        // Check if user has created at least X routines
        final routineCount = actionData?['total_routines'] as int? ?? 0;
        return CustomConditionResult(
          currentValue: routineCount,
          progressText:
              '$routineCount/${condition.targetValue} routines created',
        );

      case 'active_routines':
        // Check active routine count
        final activeCount = actionData?['active_routines'] as int? ?? 0;
        return CustomConditionResult(
          currentValue: activeCount,
          progressText: '$activeCount/${condition.targetValue} active routines',
        );

      case 'weekend_completion':
        // Check weekend completions
        final weekendCount =
            userProgress.customData['weekend_completions'] as int? ?? 0;
        return CustomConditionResult(
          currentValue: weekendCount,
          progressText:
              '$weekendCount/${condition.targetValue} weekends completed',
        );

      case 'comeback':
        // Check if user made a comeback after break
        final comebackCount = userProgress.customData['comebacks'] as int? ?? 0;
        return CustomConditionResult(
          currentValue: comebackCount,
          progressText:
              comebackCount > 0 ? 'Comeback achieved' : 'No comeback yet',
        );

      case 'perfect_completion':
        // Check perfect completion days
        final perfectDays =
            userProgress.customData['perfect_days'] as int? ?? 0;
        return CustomConditionResult(
          currentValue: perfectDays,
          progressText: '$perfectDays/${condition.targetValue} perfect days',
        );

      case 'achievements_unlocked':
        // Meta achievement for unlocking other achievements
        final unlockedCount = actionData?['unlocked_achievements'] as int? ?? 0;
        return CustomConditionResult(
          currentValue: unlockedCount,
          progressText:
              '$unlockedCount/${condition.targetValue} achievements unlocked',
        );

      case 'before_8am':
      case 'after_10pm':
        // Time-based achievements
        final timeCount = userProgress.customData[action] as int? ?? 0;
        final timeLabel =
            action == 'before_8am' ? 'early morning' : 'late night';
        return CustomConditionResult(
          currentValue: timeCount,
          progressText:
              '$timeCount/${condition.targetValue} $timeLabel completions',
        );

      default:
        return CustomConditionResult(
          currentValue: 0,
          progressText: 'Unknown condition',
        );
    }
  }

  /// Check milestone conditions
  static int _checkMilestone(
      UnlockCondition condition, UserProgress userProgress) {
    // Simple milestone check - can be enhanced
    final totalProgress =
        userProgress.routineCompletions + userProgress.goalCompletions;
    return (totalProgress / 100).floor(); // 1 milestone per 100 completions
  }

  /// Update user progress based on action
  static UserProgress updateUserProgress({
    required UserProgress currentProgress,
    required String action,
    Map<String, dynamic>? actionData,
    RoutineModel? routine,
    DateTime? timestamp,
  }) {
    var updatedProgress = currentProgress;
    final now = timestamp ?? DateTime.now();

    switch (action) {
      case 'routine_completion':
        updatedProgress = updatedProgress.incrementRoutineCompletions();

        // Update category completions
        if (routine?.categoryId != null) {
          updatedProgress = updatedProgress
              .incrementCategoryCompletions(routine!.categoryId!);
        }

        // Update time-based tracking
        if (timestamp != null) {
          updatedProgress =
              _updateTimeBasedProgress(updatedProgress, timestamp);
        }

        // Update streak
        updatedProgress = _updateStreak(updatedProgress, timestamp);
        break;

      case 'goal_completion':
        updatedProgress = updatedProgress.incrementGoalCompletions();
        break;

      case 'create_routine':
        // Track routine creation
        final customData =
            Map<String, dynamic>.from(updatedProgress.customData);
        customData['routines_created'] =
            (customData['routines_created'] as int? ?? 0) + 1;
        updatedProgress = updatedProgress.copyWith(customData: customData);
        break;

      case 'perfect_week':
        updatedProgress = updatedProgress.markPerfectWeek();
        break;

      case 'daily_login':
        // Update consecutive days
        final lastLogin = updatedProgress.customData['last_login'] as String?;
        final consecutiveDays = _calculateConsecutiveDays(lastLogin, now);
        updatedProgress =
            updatedProgress.updateConsecutiveDays(consecutiveDays);

        // Update last login
        final customData =
            Map<String, dynamic>.from(updatedProgress.customData);
        customData['last_login'] = now.toIso8601String();
        updatedProgress = updatedProgress.copyWith(customData: customData);
        break;

      case 'comeback':
        // Track comeback after break
        final customData =
            Map<String, dynamic>.from(updatedProgress.customData);
        customData['comebacks'] = (customData['comebacks'] as int? ?? 0) + 1;
        updatedProgress = updatedProgress.copyWith(customData: customData);
        break;
    }

    return updatedProgress.copyWith(lastUpdated: now);
  }

  /// Update time-based progress tracking
  static UserProgress _updateTimeBasedProgress(
      UserProgress progress, DateTime timestamp) {
    final hour = timestamp.hour;
    final isWeekend = timestamp.weekday >= 6;
    final customData = Map<String, dynamic>.from(progress.customData);

    // Track time-based completions
    if (hour < 8) {
      customData['before_8am'] = (customData['before_8am'] as int? ?? 0) + 1;
    } else if (hour >= 22) {
      customData['after_10pm'] = (customData['after_10pm'] as int? ?? 0) + 1;
    }

    // Track weekend completions
    if (isWeekend) {
      customData['weekend_completions'] =
          (customData['weekend_completions'] as int? ?? 0) + 1;
    }

    return progress.copyWith(customData: customData);
  }

  /// Update streak based on completion timing
  static UserProgress _updateStreak(
      UserProgress progress, DateTime? timestamp) {
    if (timestamp == null) return progress;

    final lastCompletion = progress.lastUpdated;
    final daysDifference = timestamp.difference(lastCompletion).inDays;

    int newStreak;
    if (daysDifference <= 1) {
      // Continue or maintain streak
      newStreak = daysDifference == 1
          ? progress.currentStreak + 1
          : progress.currentStreak;
    } else {
      // Break in streak
      newStreak = 1; // Start new streak
    }

    return progress.updateStreak(newStreak);
  }

  /// Calculate consecutive login days
  static int _calculateConsecutiveDays(
      String? lastLoginString, DateTime currentLogin) {
    if (lastLoginString == null) return 1;

    try {
      final lastLogin = DateTime.parse(lastLoginString);
      final daysDifference = currentLogin.difference(lastLogin).inDays;

      if (daysDifference == 1) {
        // Consecutive day
        return 1; // Will be incremented by caller
      } else if (daysDifference == 0) {
        // Same day
        return 0; // No increment
      } else {
        // Gap in login streak
        return 1; // Reset to 1
      }
    } catch (e) {
      return 1; // Default to 1 if parsing fails
    }
  }

  /// Calculate progress for a single condition
  static int _calculateConditionProgress({
    required UnlockCondition condition,
    required UserProgress userProgress,
    String? triggeredByAction,
    Map<String, dynamic>? actionData,
  }) {
    final result = _checkSingleCondition(
      condition: condition,
      userProgress: userProgress,
      triggeredByAction: triggeredByAction,
      actionData: actionData,
    );
    return result.currentValue;
  }

  /// Get user's achievement statistics
  static AchievementStatistics calculateUserStatistics({
    required List<AchievementModel> userAchievements,
    required UserProgress userProgress,
  }) {
    final totalAchievements = AchievementDefinitions.allAchievements.length;
    final unlockedAchievements =
        userAchievements.where((a) => a.isUnlocked).length;
    final completionRate = totalAchievements > 0
        ? (unlockedAchievements / totalAchievements) * 100
        : 0.0;

    // Calculate total experience from achievements
    final totalExperience = userAchievements
        .where((a) => a.isUnlocked)
        .fold(0, (sum, a) => sum + a.experiencePoints);

    // Rarity breakdown
    final rarityBreakdown = <AchievementRarity, int>{};
    for (final rarity in AchievementRarity.values) {
      rarityBreakdown[rarity] = userAchievements
          .where((a) => a.isUnlocked && a.rarity == rarity)
          .length;
    }

    // Type breakdown
    final typeBreakdown = <AchievementType, int>{};
    for (final type in AchievementType.values) {
      typeBreakdown[type] =
          userAchievements.where((a) => a.isUnlocked && a.type == type).length;
    }

    return AchievementStatistics(
      totalAchievements: totalAchievements,
      unlockedAchievements: unlockedAchievements,
      completionRate: completionRate,
      totalExperiencePoints: totalExperience,
      currentStreak: userProgress.currentStreak,
      longestStreak: userProgress.longestStreak,
      rarityBreakdown: rarityBreakdown,
      typeBreakdown: typeBreakdown,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Result of achievement unlock check
class AchievementUnlockResult {
  final AchievementModel achievement;
  final bool shouldUnlock;
  final List<ConditionCheckResult> conditionResults;
  final DateTime? unlockedAt;

  const AchievementUnlockResult({
    required this.achievement,
    required this.shouldUnlock,
    required this.conditionResults,
    this.unlockedAt,
  });

  /// Create unlocked achievement model
  AchievementModel toUnlockedAchievement() {
    return achievement.copyWith(
      isUnlocked: true,
      unlockedAt: unlockedAt,
    );
  }
}

/// Result of condition check
class ConditionCheckResult {
  final UnlockCondition condition;
  final int currentValue;
  final int targetValue;
  final bool isMet;
  final double progress;
  final String progressText;

  const ConditionCheckResult({
    required this.condition,
    required this.currentValue,
    required this.targetValue,
    required this.isMet,
    required this.progress,
    required this.progressText,
  });
}

/// Custom condition check result
class CustomConditionResult {
  final int currentValue;
  final String progressText;

  const CustomConditionResult({
    required this.currentValue,
    required this.progressText,
  });
}
