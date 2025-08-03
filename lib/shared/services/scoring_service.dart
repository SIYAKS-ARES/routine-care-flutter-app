import '../models/routine_model.dart';
import '../models/user_level_model.dart';
import '../models/achievement_model.dart';
import '../../features/achievement_system/domain/entities/user_progress.dart';

enum RoutineDifficulty { easy, medium, hard }

class ScoringService {
  // Base experience points for different activities
  static const Map<String, int> baseExperiencePoints = {
    'routine_completion': 10,
    'streak_milestone': 25,
    'goal_completion': 50,
    'achievement_unlock': 100,
    'perfect_week': 200,
    'perfect_month': 500,
    'daily_login': 5,
    'first_routine': 20,
    'category_mastery': 150,
    'level_up': 200,
  };

  // Streak multipliers
  static const Map<int, double> streakMultipliers = {
    3: 1.1, // 10% bonus for 3-day streak
    7: 1.25, // 25% bonus for week streak
    14: 1.5, // 50% bonus for 2-week streak
    30: 2.0, // 100% bonus for month streak
    60: 2.5, // 150% bonus for 2-month streak
    100: 3.0, // 200% bonus for 100-day streak
  };

  // Difficulty multipliers
  static const Map<RoutineDifficulty, double> difficultyMultipliers = {
    RoutineDifficulty.easy: 1.0,
    RoutineDifficulty.medium: 1.2,
    RoutineDifficulty.hard: 1.5,
  };

  // Time-based bonuses (completion time)
  static const Map<String, double> timeBonuses = {
    'early_morning': 1.3, // Before 7 AM
    'morning': 1.2, // 7-9 AM
    'late_night': 1.1, // After 10 PM
    'weekend': 1.15, // Weekend completion
  };

  /// Calculate experience points for routine completion
  static ExperienceReward calculateRoutineExperience({
    required RoutineModel routine,
    required UserProgress userProgress,
    UserLevelModel? userLevel,
    DateTime? completionTime,
  }) {
    var basePoints = baseExperiencePoints['routine_completion']!;
    var multiplier = 1.0;
    var bonusReasons = <String>[];

    // Difficulty multiplier (default to medium for now)
    final difficulty = _estimateRoutineDifficulty(routine);
    final difficultyBonus = difficultyMultipliers[difficulty] ?? 1.0;
    multiplier *= difficultyBonus;
    if (difficultyBonus > 1.0) {
      bonusReasons.add('Difficulty: ${difficulty.name}');
    }

    // Streak multiplier
    final streakMultiplier = _getStreakMultiplier(userProgress.currentStreak);
    if (streakMultiplier > 1.0) {
      multiplier *= streakMultiplier;
      bonusReasons.add('${userProgress.currentStreak}-day streak');
    }

    // Time-based bonus
    if (completionTime != null) {
      final timeBonus = _getTimeBonus(completionTime);
      if (timeBonus.multiplier > 1.0) {
        multiplier *= timeBonus.multiplier;
        bonusReasons.add(timeBonus.reason);
      }
    }

    // Level bonus (if user has level benefits)
    if (userLevel != null) {
      final levelTier = LevelSystemConfig.getLevelTier(userLevel.currentLevel);
      if (levelTier.experienceBonus > 0) {
        final levelBonus = 1.0 + (levelTier.experienceBonus / 100);
        multiplier *= levelBonus;
        bonusReasons.add('Level ${userLevel.currentLevel} bonus');
      }
    }

    // Category mastery bonus
    if (routine.categoryId != null) {
      final categoryCompletions =
          userProgress.getCategoryCompletions(routine.categoryId!);
      if (categoryCompletions >= 50) {
        multiplier *= 1.2;
        bonusReasons.add('Category mastery');
      }
    }

    final finalPoints = (basePoints * multiplier).round();

    return ExperienceReward(
      basePoints: basePoints,
      bonusPoints: finalPoints - basePoints,
      totalPoints: finalPoints,
      multiplier: multiplier,
      reasons: bonusReasons,
      source: 'routine_completion',
    );
  }

  /// Calculate experience for streak milestones
  static ExperienceReward calculateStreakMilestone(int streakDays) {
    var basePoints = baseExperiencePoints['streak_milestone']!;
    var bonusMultiplier = 1.0;
    var bonusReasons = <String>[];

    // Milestone bonuses
    if (streakDays >= 100) {
      bonusMultiplier = 5.0;
      bonusReasons.add('100-day legendary streak');
    } else if (streakDays >= 50) {
      bonusMultiplier = 3.0;
      bonusReasons.add('50-day epic streak');
    } else if (streakDays >= 30) {
      bonusMultiplier = 2.0;
      bonusReasons.add('30-day month streak');
    } else if (streakDays >= 14) {
      bonusMultiplier = 1.5;
      bonusReasons.add('14-day strong streak');
    } else if (streakDays >= 7) {
      bonusMultiplier = 1.3;
      bonusReasons.add('7-day week streak');
    } else if (streakDays >= 3) {
      bonusMultiplier = 1.1;
      bonusReasons.add('3-day starter streak');
    }

    final finalPoints = (basePoints * bonusMultiplier).round();

    return ExperienceReward(
      basePoints: basePoints,
      bonusPoints: finalPoints - basePoints,
      totalPoints: finalPoints,
      multiplier: bonusMultiplier,
      reasons: bonusReasons,
      source: 'streak_milestone',
    );
  }

  /// Calculate experience for achievement unlock
  static ExperienceReward calculateAchievementUnlock(
      AchievementModel achievement) {
    var basePoints = achievement.experiencePoints;
    var bonusMultiplier = 1.0;
    var bonusReasons = <String>[];

    // Rarity bonus
    switch (achievement.rarity) {
      case AchievementRarity.common:
        bonusMultiplier = 1.0;
        break;
      case AchievementRarity.uncommon:
        bonusMultiplier = 1.2;
        bonusReasons.add('Uncommon achievement');
        break;
      case AchievementRarity.rare:
        bonusMultiplier = 1.5;
        bonusReasons.add('Rare achievement');
        break;
      case AchievementRarity.epic:
        bonusMultiplier = 2.0;
        bonusReasons.add('Epic achievement');
        break;
      case AchievementRarity.legendary:
        bonusMultiplier = 3.0;
        bonusReasons.add('Legendary achievement');
        break;
    }

    final finalPoints = (basePoints * bonusMultiplier).round();

    return ExperienceReward(
      basePoints: basePoints,
      bonusPoints: finalPoints - basePoints,
      totalPoints: finalPoints,
      multiplier: bonusMultiplier,
      reasons: bonusReasons,
      source: 'achievement_unlock',
    );
  }

  /// Calculate experience for perfect week
  static ExperienceReward calculatePerfectWeek(int consecutiveWeeks) {
    var basePoints = baseExperiencePoints['perfect_week']!;
    var bonusMultiplier = 1.0 + (consecutiveWeeks - 1) * 0.5;
    var bonusReasons = <String>[];

    if (consecutiveWeeks > 1) {
      bonusReasons.add('$consecutiveWeeks consecutive perfect weeks');
    }

    final finalPoints = (basePoints * bonusMultiplier).round();

    return ExperienceReward(
      basePoints: basePoints,
      bonusPoints: finalPoints - basePoints,
      totalPoints: finalPoints,
      multiplier: bonusMultiplier,
      reasons: bonusReasons,
      source: 'perfect_week',
    );
  }

  /// Calculate daily login bonus
  static ExperienceReward calculateDailyLogin({
    required int consecutiveDays,
    UserLevelModel? userLevel,
  }) {
    var basePoints = baseExperiencePoints['daily_login']!;
    var multiplier = 1.0;
    var bonusReasons = <String>[];

    // Consecutive login bonus
    if (consecutiveDays >= 30) {
      multiplier = 3.0;
      bonusReasons.add('30+ day login streak');
    } else if (consecutiveDays >= 7) {
      multiplier = 2.0;
      bonusReasons.add('7+ day login streak');
    } else if (consecutiveDays >= 3) {
      multiplier = 1.5;
      bonusReasons.add('3+ day login streak');
    }

    // Level bonus
    if (userLevel != null) {
      final levelTier = LevelSystemConfig.getLevelTier(userLevel.currentLevel);
      if (levelTier.experienceBonus > 0) {
        final levelBonus = 1.0 + (levelTier.experienceBonus / 100);
        multiplier *= levelBonus;
        bonusReasons.add('Level ${userLevel.currentLevel} bonus');
      }
    }

    final finalPoints = (basePoints * multiplier).round();

    return ExperienceReward(
      basePoints: basePoints,
      bonusPoints: finalPoints - basePoints,
      totalPoints: finalPoints,
      multiplier: multiplier,
      reasons: bonusReasons,
      source: 'daily_login',
    );
  }

  /// Get streak multiplier based on current streak
  static double _getStreakMultiplier(int streakDays) {
    double multiplier = 1.0;

    for (final entry in streakMultipliers.entries) {
      if (streakDays >= entry.key) {
        multiplier = entry.value;
      }
    }

    return multiplier;
  }

  /// Get time-based bonus for completion time
  static TimeBonus _getTimeBonus(DateTime completionTime) {
    final hour = completionTime.hour;
    final isWeekend = completionTime.weekday >= 6;

    if (isWeekend) {
      return TimeBonus(
        multiplier: timeBonuses['weekend']!,
        reason: 'Weekend warrior',
      );
    }

    if (hour < 7) {
      return TimeBonus(
        multiplier: timeBonuses['early_morning']!,
        reason: 'Early bird',
      );
    }

    if (hour >= 7 && hour <= 9) {
      return TimeBonus(
        multiplier: timeBonuses['morning']!,
        reason: 'Morning routine',
      );
    }

    if (hour >= 22) {
      return TimeBonus(
        multiplier: timeBonuses['late_night']!,
        reason: 'Night owl',
      );
    }

    return TimeBonus(multiplier: 1.0, reason: '');
  }

  /// Calculate total experience from multiple sources
  static int calculateTotalExperience(List<ExperienceReward> rewards) {
    return rewards.fold(0, (total, reward) => total + reward.totalPoints);
  }

  /// Check if experience amount triggers level up
  static bool shouldLevelUp(UserLevelModel currentLevel, int newExperience) {
    final totalExp = currentLevel.totalExperience + newExperience;
    final requiredExp = LevelSystemConfig.getRequiredExperienceForLevel(
        currentLevel.currentLevel + 1);
    return totalExp >= requiredExp;
  }

  /// Calculate level progression after adding experience
  static LevelProgressionResult calculateLevelProgression(
    UserLevelModel currentLevel,
    int additionalExperience,
  ) {
    final newLevel =
        LevelSystemConfig.calculateLevelUp(currentLevel, additionalExperience);
    final leveledUp = newLevel.currentLevel > currentLevel.currentLevel;

    final levelUpRewards = <ExperienceReward>[];
    if (leveledUp) {
      final levelsGained = newLevel.currentLevel - currentLevel.currentLevel;
      for (int i = 0; i < levelsGained; i++) {
        levelUpRewards.add(ExperienceReward(
          basePoints: baseExperiencePoints['level_up']!,
          bonusPoints: 0,
          totalPoints: baseExperiencePoints['level_up']!,
          multiplier: 1.0,
          reasons: ['Level up bonus'],
          source: 'level_up',
        ));
      }
    }

    return LevelProgressionResult(
      oldLevel: currentLevel,
      newLevel: newLevel,
      leveledUp: leveledUp,
      levelsGained: newLevel.currentLevel - currentLevel.currentLevel,
      levelUpRewards: levelUpRewards,
    );
  }

  /// Estimate routine difficulty based on routine characteristics
  static RoutineDifficulty _estimateRoutineDifficulty(RoutineModel routine) {
    // Simple heuristic for now - can be enhanced later
    // Could be based on category, completion history, etc.

    // For now, return medium as default
    // In future, could analyze:
    // - Routine name keywords (exercise -> hard, meditation -> easy)
    // - Historical completion rates
    // - Category-based difficulty
    // - User-defined difficulty

    return RoutineDifficulty.medium;
  }
}

/// Experience reward details
class ExperienceReward {
  final int basePoints;
  final int bonusPoints;
  final int totalPoints;
  final double multiplier;
  final List<String> reasons;
  final String source;

  const ExperienceReward({
    required this.basePoints,
    required this.bonusPoints,
    required this.totalPoints,
    required this.multiplier,
    required this.reasons,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'basePoints': basePoints,
        'bonusPoints': bonusPoints,
        'totalPoints': totalPoints,
        'multiplier': multiplier,
        'reasons': reasons,
        'source': source,
      };

  factory ExperienceReward.fromJson(Map<String, dynamic> json) =>
      ExperienceReward(
        basePoints: json['basePoints'],
        bonusPoints: json['bonusPoints'],
        totalPoints: json['totalPoints'],
        multiplier: json['multiplier'].toDouble(),
        reasons: List<String>.from(json['reasons']),
        source: json['source'],
      );

  @override
  String toString() => 'Experience: +$totalPoints ($source)';
}

/// Time-based bonus information
class TimeBonus {
  final double multiplier;
  final String reason;

  const TimeBonus({
    required this.multiplier,
    required this.reason,
  });
}

/// Level progression result after experience gain
class LevelProgressionResult {
  final UserLevelModel oldLevel;
  final UserLevelModel newLevel;
  final bool leveledUp;
  final int levelsGained;
  final List<ExperienceReward> levelUpRewards;

  const LevelProgressionResult({
    required this.oldLevel,
    required this.newLevel,
    required this.leveledUp,
    required this.levelsGained,
    required this.levelUpRewards,
  });

  int get totalLevelUpBonus =>
      levelUpRewards.fold(0, (sum, reward) => sum + reward.totalPoints);
}
