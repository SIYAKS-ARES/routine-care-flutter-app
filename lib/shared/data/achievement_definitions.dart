import 'package:flutter/material.dart';
import '../models/achievement_model.dart';

class AchievementDefinitions {
  static final List<AchievementModel> allAchievements = [
    // Routine Achievements
    AchievementModel(
      id: 'first_routine',
      title: 'First Steps',
      description: 'Complete your very first routine',
      type: AchievementType.routine,
      rarity: AchievementRarity.common,
      icon: Icons.play_arrow_rounded,
      color: const Color(0xFF4CAF50),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.routineCompletion,
          targetValue: 1,
        ),
      ],
      experiencePoints: 20,
      createdAt: DateTime.now(),
      tags: ['beginner', 'routine'],
    ),

    AchievementModel(
      id: 'routine_warrior',
      title: 'Routine Warrior',
      description: 'Complete 50 routines',
      type: AchievementType.routine,
      rarity: AchievementRarity.uncommon,
      icon: Icons.fitness_center_rounded,
      color: const Color(0xFF2196F3),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.routineCompletion,
          targetValue: 50,
        ),
      ],
      experiencePoints: 100,
      createdAt: DateTime.now(),
      tags: ['intermediate', 'routine'],
    ),

    AchievementModel(
      id: 'routine_master',
      title: 'Routine Master',
      description: 'Complete 500 routines',
      type: AchievementType.routine,
      rarity: AchievementRarity.rare,
      icon: Icons.military_tech_rounded,
      color: const Color(0xFFFF9800),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.routineCompletion,
          targetValue: 500,
        ),
      ],
      experiencePoints: 500,
      createdAt: DateTime.now(),
      tags: ['advanced', 'routine'],
    ),

    // Streak Achievements
    AchievementModel(
      id: 'streak_starter',
      title: 'Streak Starter',
      description: 'Maintain a 3-day streak',
      type: AchievementType.streak,
      rarity: AchievementRarity.common,
      icon: Icons.local_fire_department_rounded,
      color: const Color(0xFFFF5722),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.streakAchievement,
          targetValue: 3,
        ),
      ],
      experiencePoints: 30,
      createdAt: DateTime.now(),
      tags: ['beginner', 'streak'],
    ),

    AchievementModel(
      id: 'week_warrior',
      title: 'Week Warrior',
      description: 'Maintain a 7-day streak',
      type: AchievementType.streak,
      rarity: AchievementRarity.uncommon,
      icon: Icons.whatshot_rounded,
      color: const Color(0xFFFF5722),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.streakAchievement,
          targetValue: 7,
        ),
      ],
      experiencePoints: 75,
      createdAt: DateTime.now(),
      tags: ['intermediate', 'streak'],
    ),

    AchievementModel(
      id: 'month_champion',
      title: 'Month Champion',
      description: 'Maintain a 30-day streak',
      type: AchievementType.streak,
      rarity: AchievementRarity.epic,
      icon: Icons.celebration_rounded,
      color: const Color(0xFF9C27B0),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.streakAchievement,
          targetValue: 30,
        ),
      ],
      experiencePoints: 300,
      createdAt: DateTime.now(),
      tags: ['advanced', 'streak'],
    ),

    AchievementModel(
      id: 'streak_legend',
      title: 'Streak Legend',
      description: 'Maintain a 100-day streak',
      type: AchievementType.streak,
      rarity: AchievementRarity.legendary,
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFFFFD700),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.streakAchievement,
          targetValue: 100,
        ),
      ],
      experiencePoints: 1000,
      createdAt: DateTime.now(),
      tags: ['legendary', 'streak'],
    ),

    // Time-based Achievements
    AchievementModel(
      id: 'perfect_week',
      title: 'Perfect Week',
      description: 'Complete all routines for 7 consecutive days',
      type: AchievementType.time,
      rarity: AchievementRarity.rare,
      icon: Icons.calendar_today_rounded,
      color: const Color(0xFF4CAF50),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.perfectWeek,
          targetValue: 1,
        ),
      ],
      experiencePoints: 200,
      createdAt: DateTime.now(),
      tags: ['time', 'perfect'],
    ),

    AchievementModel(
      id: 'early_bird',
      title: 'Early Bird',
      description: 'Complete routines before 8 AM for 7 days',
      type: AchievementType.time,
      rarity: AchievementRarity.uncommon,
      icon: Icons.wb_sunny_rounded,
      color: const Color(0xFFFFC107),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.custom,
          targetValue: 7,
          customData: {'time': 'before_8am'},
        ),
      ],
      experiencePoints: 150,
      createdAt: DateTime.now(),
      tags: ['time', 'morning'],
    ),

    AchievementModel(
      id: 'night_owl',
      title: 'Night Owl',
      description: 'Complete routines after 10 PM for 7 days',
      type: AchievementType.time,
      rarity: AchievementRarity.uncommon,
      icon: Icons.nightlight_round,
      color: const Color(0xFF3F51B5),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.custom,
          targetValue: 7,
          customData: {'time': 'after_10pm'},
        ),
      ],
      experiencePoints: 150,
      createdAt: DateTime.now(),
      tags: ['time', 'evening'],
    ),

    // Milestone Achievements
    AchievementModel(
      id: 'habit_builder',
      title: 'Habit Builder',
      description: 'Create your first routine',
      type: AchievementType.milestone,
      rarity: AchievementRarity.common,
      icon: Icons.add_task_rounded,
      color: const Color(0xFF607D8B),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.custom,
          targetValue: 1,
          customData: {'action': 'create_routine'},
        ),
      ],
      experiencePoints: 10,
      createdAt: DateTime.now(),
      tags: ['milestone', 'beginner'],
    ),

    AchievementModel(
      id: 'variety_seeker',
      title: 'Variety Seeker',
      description: 'Have 10 different active routines',
      type: AchievementType.milestone,
      rarity: AchievementRarity.rare,
      icon: Icons.diversity_3_rounded,
      color: const Color(0xFF795548),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.custom,
          targetValue: 10,
          customData: {'action': 'active_routines'},
        ),
      ],
      experiencePoints: 200,
      createdAt: DateTime.now(),
      tags: ['milestone', 'variety'],
    ),

    // Category Achievements
    AchievementModel(
      id: 'health_enthusiast',
      title: 'Health Enthusiast',
      description: 'Complete 100 health-related routines',
      type: AchievementType.category,
      rarity: AchievementRarity.uncommon,
      icon: Icons.favorite_rounded,
      color: const Color(0xFFE91E63),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.categoryMastery,
          targetValue: 100,
          categoryId: 'health',
        ),
      ],
      experiencePoints: 150,
      createdAt: DateTime.now(),
      tags: ['category', 'health'],
    ),

    AchievementModel(
      id: 'productivity_guru',
      title: 'Productivity Guru',
      description: 'Complete 100 productivity routines',
      type: AchievementType.category,
      rarity: AchievementRarity.uncommon,
      icon: Icons.business_center_rounded,
      color: const Color(0xFF3F51B5),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.categoryMastery,
          targetValue: 100,
          categoryId: 'productivity',
        ),
      ],
      experiencePoints: 150,
      createdAt: DateTime.now(),
      tags: ['category', 'productivity'],
    ),

    // Special Achievements
    AchievementModel(
      id: 'weekend_warrior',
      title: 'Weekend Warrior',
      description: 'Complete routines on 10 consecutive weekends',
      type: AchievementType.special,
      rarity: AchievementRarity.epic,
      icon: Icons.weekend_rounded,
      color: const Color(0xFF9C27B0),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.custom,
          targetValue: 10,
          customData: {'action': 'weekend_completion'},
        ),
      ],
      experiencePoints: 250,
      createdAt: DateTime.now(),
      tags: ['special', 'weekend'],
    ),

    AchievementModel(
      id: 'comeback_kid',
      title: 'Comeback Kid',
      description: 'Return after a 7+ day break and start a new streak',
      type: AchievementType.special,
      rarity: AchievementRarity.rare,
      icon: Icons.refresh_rounded,
      color: const Color(0xFF00BCD4),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.custom,
          targetValue: 1,
          customData: {'action': 'comeback'},
        ),
      ],
      experiencePoints: 100,
      createdAt: DateTime.now(),
      tags: ['special', 'comeback'],
    ),

    AchievementModel(
      id: 'perfectionist',
      title: 'Perfectionist',
      description: 'Complete 100% of routines for 30 days',
      type: AchievementType.special,
      rarity: AchievementRarity.legendary,
      icon: Icons.verified_rounded,
      color: const Color(0xFFFFD700),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.custom,
          targetValue: 30,
          customData: {'action': 'perfect_completion'},
        ),
      ],
      experiencePoints: 500,
      createdAt: DateTime.now(),
      tags: ['special', 'perfect'],
    ),

    // Goal Achievements
    AchievementModel(
      id: 'goal_getter',
      title: 'Goal Getter',
      description: 'Complete your first goal',
      type: AchievementType.goal,
      rarity: AchievementRarity.common,
      icon: Icons.flag_rounded,
      color: const Color(0xFF4CAF50),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.goalCompletion,
          targetValue: 1,
        ),
      ],
      experiencePoints: 50,
      createdAt: DateTime.now(),
      tags: ['goal', 'beginner'],
    ),

    AchievementModel(
      id: 'achievement_hunter',
      title: 'Achievement Hunter',
      description: 'Unlock 25 achievements',
      type: AchievementType.special,
      rarity: AchievementRarity.epic,
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFFFF9800),
      unlockConditions: [
        UnlockCondition(
          type: UnlockConditionType.custom,
          targetValue: 25,
          customData: {'action': 'achievements_unlocked'},
        ),
      ],
      experiencePoints: 300,
      createdAt: DateTime.now(),
      tags: ['special', 'meta'],
    ),
  ];

  // Helper methods to get achievements by category
  static List<AchievementModel> getAchievementsByType(AchievementType type) {
    return allAchievements
        .where((achievement) => achievement.type == type)
        .toList();
  }

  static List<AchievementModel> getAchievementsByRarity(
      AchievementRarity rarity) {
    return allAchievements
        .where((achievement) => achievement.rarity == rarity)
        .toList();
  }

  static List<AchievementModel> getBeginnerAchievements() {
    return allAchievements
        .where((achievement) => achievement.tags.contains('beginner'))
        .toList();
  }

  static AchievementModel? getAchievementById(String id) {
    try {
      return allAchievements.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<AchievementModel> getHiddenAchievements() {
    return allAchievements
        .where((achievement) => achievement.isHidden)
        .toList();
  }

  static List<AchievementModel> getVisibleAchievements() {
    return allAchievements
        .where((achievement) => !achievement.isHidden)
        .toList();
  }

  // Get achievements sorted by rarity (legendary first)
  static List<AchievementModel> getAchievementsSortedByRarity() {
    final achievements = List<AchievementModel>.from(allAchievements);
    achievements.sort((a, b) {
      final rarityOrder = {
        AchievementRarity.legendary: 0,
        AchievementRarity.epic: 1,
        AchievementRarity.rare: 2,
        AchievementRarity.uncommon: 3,
        AchievementRarity.common: 4,
      };
      return rarityOrder[a.rarity]!.compareTo(rarityOrder[b.rarity]!);
    });
    return achievements;
  }

  // Get achievements sorted by experience points (highest first)
  static List<AchievementModel> getAchievementsSortedByExperience() {
    final achievements = List<AchievementModel>.from(allAchievements);
    achievements
        .sort((a, b) => b.experiencePoints.compareTo(a.experiencePoints));
    return achievements;
  }

  // Get total possible experience points
  static int getTotalPossibleExperience() {
    return allAchievements.fold(
        0, (sum, achievement) => sum + achievement.experiencePoints);
  }

  // Get achievements count by rarity
  static Map<AchievementRarity, int> getAchievementCountByRarity() {
    final counts = <AchievementRarity, int>{};
    for (final rarity in AchievementRarity.values) {
      counts[rarity] = getAchievementsByRarity(rarity).length;
    }
    return counts;
  }

  // Get achievements count by type
  static Map<AchievementType, int> getAchievementCountByType() {
    final counts = <AchievementType, int>{};
    for (final type in AchievementType.values) {
      counts[type] = getAchievementsByType(type).length;
    }
    return counts;
  }
}
