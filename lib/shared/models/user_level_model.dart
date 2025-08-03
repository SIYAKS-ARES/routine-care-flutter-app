import 'package:flutter/material.dart';

enum LevelBenefit {
  customThemes,
  extraReminderSlots,
  advancedStatistics,
  premiumBadges,
  prioritySupport,
  exportData,
  unlimitedRoutines,
  categoryCustomization,
  achievementBonus,
  specialCelebrations,
}

class LevelTier {
  final int level;
  final String title;
  final String description;
  final int requiredExperience;
  final Color color;
  final IconData icon;
  final List<LevelBenefit> benefits;
  final int experienceBonus; // %bonus for activities
  final String? badgeImagePath;

  const LevelTier({
    required this.level,
    required this.title,
    required this.description,
    required this.requiredExperience,
    required this.color,
    required this.icon,
    required this.benefits,
    this.experienceBonus = 0,
    this.badgeImagePath,
  });

  Map<String, dynamic> toJson() => {
        'level': level,
        'title': title,
        'description': description,
        'requiredExperience': requiredExperience,
        'colorValue': color.value,
        'iconCodePoint': icon.codePoint,
        'iconFontFamily': icon.fontFamily,
        'benefits': benefits.map((b) => b.name).toList(),
        'experienceBonus': experienceBonus,
        'badgeImagePath': badgeImagePath,
      };

  factory LevelTier.fromJson(Map<String, dynamic> json) => LevelTier(
        level: json['level'],
        title: json['title'],
        description: json['description'],
        requiredExperience: json['requiredExperience'],
        color: Color(json['colorValue']),
        icon: IconData(
          json['iconCodePoint'],
          fontFamily: json['iconFontFamily'],
        ),
        benefits: (json['benefits'] as List<dynamic>)
            .map((b) =>
                LevelBenefit.values.firstWhere((benefit) => benefit.name == b))
            .toList(),
        experienceBonus: json['experienceBonus'] ?? 0,
        badgeImagePath: json['badgeImagePath'],
      );
}

class UserLevelModel {
  final String userId;
  final int currentLevel;
  final int currentExperience;
  final int totalExperience;
  final String currentTitle;
  final DateTime lastLevelUp;
  final List<LevelBenefit> unlockedBenefits;
  final Map<String, int> experienceFromSources; // source -> xp amount
  final int experienceToNextLevel;
  final double progressToNextLevel;
  final DateTime createdAt;
  final DateTime lastUpdated;

  const UserLevelModel({
    required this.userId,
    required this.currentLevel,
    required this.currentExperience,
    required this.totalExperience,
    required this.currentTitle,
    required this.lastLevelUp,
    required this.unlockedBenefits,
    required this.experienceFromSources,
    required this.experienceToNextLevel,
    required this.progressToNextLevel,
    required this.createdAt,
    required this.lastUpdated,
  });

  UserLevelModel copyWith({
    String? userId,
    int? currentLevel,
    int? currentExperience,
    int? totalExperience,
    String? currentTitle,
    DateTime? lastLevelUp,
    List<LevelBenefit>? unlockedBenefits,
    Map<String, int>? experienceFromSources,
    int? experienceToNextLevel,
    double? progressToNextLevel,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return UserLevelModel(
      userId: userId ?? this.userId,
      currentLevel: currentLevel ?? this.currentLevel,
      currentExperience: currentExperience ?? this.currentExperience,
      totalExperience: totalExperience ?? this.totalExperience,
      currentTitle: currentTitle ?? this.currentTitle,
      lastLevelUp: lastLevelUp ?? this.lastLevelUp,
      unlockedBenefits: unlockedBenefits ?? this.unlockedBenefits,
      experienceFromSources:
          experienceFromSources ?? this.experienceFromSources,
      experienceToNextLevel:
          experienceToNextLevel ?? this.experienceToNextLevel,
      progressToNextLevel: progressToNextLevel ?? this.progressToNextLevel,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'currentLevel': currentLevel,
        'currentExperience': currentExperience,
        'totalExperience': totalExperience,
        'currentTitle': currentTitle,
        'lastLevelUp': lastLevelUp.toIso8601String(),
        'unlockedBenefits': unlockedBenefits.map((b) => b.name).toList(),
        'experienceFromSources': experienceFromSources,
        'experienceToNextLevel': experienceToNextLevel,
        'progressToNextLevel': progressToNextLevel,
        'createdAt': createdAt.toIso8601String(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory UserLevelModel.fromJson(Map<String, dynamic> json) => UserLevelModel(
        userId: json['userId'],
        currentLevel: json['currentLevel'],
        currentExperience: json['currentExperience'],
        totalExperience: json['totalExperience'],
        currentTitle: json['currentTitle'],
        lastLevelUp: DateTime.parse(json['lastLevelUp']),
        unlockedBenefits: (json['unlockedBenefits'] as List<dynamic>)
            .map((b) =>
                LevelBenefit.values.firstWhere((benefit) => benefit.name == b))
            .toList(),
        experienceFromSources:
            Map<String, int>.from(json['experienceFromSources'] ?? {}),
        experienceToNextLevel: json['experienceToNextLevel'],
        progressToNextLevel: json['progressToNextLevel'].toDouble(),
        createdAt: DateTime.parse(json['createdAt']),
        lastUpdated: DateTime.parse(json['lastUpdated']),
      );

  factory UserLevelModel.initial(String userId) {
    final now = DateTime.now();
    return UserLevelModel(
      userId: userId,
      currentLevel: 1,
      currentExperience: 0,
      totalExperience: 0,
      currentTitle: 'Beginner',
      lastLevelUp: now,
      unlockedBenefits: [],
      experienceFromSources: {},
      experienceToNextLevel: LevelSystemConfig.getRequiredExperienceForLevel(2),
      progressToNextLevel: 0.0,
      createdAt: now,
      lastUpdated: now,
    );
  }

  // Helper methods
  bool hasBenefit(LevelBenefit benefit) => unlockedBenefits.contains(benefit);

  int getExperienceFromSource(String source) =>
      experienceFromSources[source] ?? 0;

  bool canLevelUp() => experienceToNextLevel <= 0;

  String get formattedProgress => '${(progressToNextLevel * 100).toInt()}%';

  String get formattedExperience =>
      '$currentExperience / ${currentExperience + experienceToNextLevel}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserLevelModel &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          currentLevel == other.currentLevel &&
          currentExperience == other.currentExperience &&
          totalExperience == other.totalExperience;

  @override
  int get hashCode =>
      userId.hashCode ^
      currentLevel.hashCode ^
      currentExperience.hashCode ^
      totalExperience.hashCode;

  @override
  String toString() =>
      'UserLevel(level: $currentLevel, title: $currentTitle, xp: $currentExperience)';
}

// Level system configuration and constants
class LevelSystemConfig {
  static const int baseExperiencePerLevel = 100;
  static const double levelMultiplier = 1.5;
  static const int maxLevel = 100;

  // Experience rewards for different activities
  static const Map<String, int> experienceRewards = {
    'routine_completion': 10,
    'streak_milestone': 25,
    'goal_completion': 50,
    'achievement_unlock': 100,
    'perfect_week': 200,
    'perfect_month': 500,
    'daily_login': 5,
    'first_routine': 20,
    'category_mastery': 150,
  };

  // Level tier definitions
  static final List<LevelTier> levelTiers = [
    LevelTier(
      level: 1,
      title: 'Beginner',
      description: 'Starting your routine journey',
      requiredExperience: 0,
      color: const Color(0xFF8BC34A),
      icon: Icons.egg_rounded,
      benefits: [],
    ),
    LevelTier(
      level: 5,
      title: 'Dedicated',
      description: 'Building consistent habits',
      requiredExperience: 500,
      color: const Color(0xFF2196F3),
      icon: Icons.psychology_rounded,
      benefits: [LevelBenefit.extraReminderSlots],
      experienceBonus: 5,
    ),
    LevelTier(
      level: 10,
      title: 'Enthusiast',
      description: 'Routine master in training',
      requiredExperience: 1500,
      color: const Color(0xFF9C27B0),
      icon: Icons.workspace_premium_rounded,
      benefits: [
        LevelBenefit.extraReminderSlots,
        LevelBenefit.customThemes,
        LevelBenefit.categoryCustomization,
      ],
      experienceBonus: 10,
    ),
    LevelTier(
      level: 20,
      title: 'Expert',
      description: 'Advanced routine strategist',
      requiredExperience: 5000,
      color: const Color(0xFFFF9800),
      icon: Icons.star_rounded,
      benefits: [
        LevelBenefit.extraReminderSlots,
        LevelBenefit.customThemes,
        LevelBenefit.categoryCustomization,
        LevelBenefit.advancedStatistics,
        LevelBenefit.premiumBadges,
      ],
      experienceBonus: 15,
    ),
    LevelTier(
      level: 50,
      title: 'Master',
      description: 'Routine optimization expert',
      requiredExperience: 25000,
      color: const Color(0xFFE91E63),
      icon: Icons.military_tech_rounded,
      benefits: [
        LevelBenefit.extraReminderSlots,
        LevelBenefit.customThemes,
        LevelBenefit.categoryCustomization,
        LevelBenefit.advancedStatistics,
        LevelBenefit.premiumBadges,
        LevelBenefit.exportData,
        LevelBenefit.unlimitedRoutines,
      ],
      experienceBonus: 20,
    ),
    LevelTier(
      level: 100,
      title: 'Legend',
      description: 'Ultimate routine champion',
      requiredExperience: 100000,
      color: const Color(0xFFFFD700),
      icon: Icons.emoji_events_rounded,
      benefits: LevelBenefit.values,
      experienceBonus: 25,
    ),
  ];

  static int getRequiredExperienceForLevel(int level) {
    if (level <= 1) return 0;
    return (baseExperiencePerLevel *
            (1 - (levelMultiplier * level)) /
            (1 - levelMultiplier))
        .round();
  }

  static LevelTier getLevelTier(int level) {
    LevelTier currentTier = levelTiers.first;

    for (final tier in levelTiers) {
      if (level >= tier.level) {
        currentTier = tier;
      } else {
        break;
      }
    }

    return currentTier;
  }

  static LevelTier? getNextLevelTier(int currentLevel) {
    for (final tier in levelTiers) {
      if (tier.level > currentLevel) {
        return tier;
      }
    }
    return null; // Max level reached
  }

  static int getExperienceReward(String source) {
    return experienceRewards[source] ?? 0;
  }

  static UserLevelModel calculateLevelUp(
      UserLevelModel currentLevel, int additionalExperience) {
    final newTotalExperience =
        currentLevel.totalExperience + additionalExperience;
    int newLevel = currentLevel.currentLevel;
    int newCurrentExperience =
        currentLevel.currentExperience + additionalExperience;

    // Check for level ups
    while (
        newCurrentExperience >= getRequiredExperienceForLevel(newLevel + 1) &&
            newLevel < maxLevel) {
      newCurrentExperience -= getRequiredExperienceForLevel(newLevel + 1);
      newLevel++;
    }

    final newTier = getLevelTier(newLevel);
    final nextLevelExperience = getRequiredExperienceForLevel(newLevel + 1);
    final experienceToNext = nextLevelExperience - newCurrentExperience;
    final progress = nextLevelExperience > 0
        ? newCurrentExperience / nextLevelExperience
        : 1.0;

    return currentLevel.copyWith(
      currentLevel: newLevel,
      currentExperience: newCurrentExperience,
      totalExperience: newTotalExperience,
      currentTitle: newTier.title,
      lastLevelUp: newLevel > currentLevel.currentLevel
          ? DateTime.now()
          : currentLevel.lastLevelUp,
      unlockedBenefits: newTier.benefits,
      experienceToNextLevel: experienceToNext,
      progressToNextLevel: progress,
      lastUpdated: DateTime.now(),
    );
  }
}
