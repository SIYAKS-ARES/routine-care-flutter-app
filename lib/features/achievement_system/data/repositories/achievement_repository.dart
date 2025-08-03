import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import '../../../../shared/models/achievement_model.dart';
import '../../domain/entities/achievement_statistics.dart';
import '../../domain/entities/user_progress.dart';

class AchievementRepository {
  static const String _boxName = 'achievements_box';
  static const String _statisticsBoxName = 'achievement_statistics_box';
  static const String _userProgressBoxName = 'user_progress_box';

  final Logger _logger = Logger();
  late Box<Map> _achievementBox;
  late Box<Map> _statisticsBox;
  late Box<Map> _userProgressBox;
  bool _isInitialized = false;

  // Initialize Hive boxes
  Future<void> initialize() async {
    try {
      if (!_isInitialized) {
        _achievementBox = await Hive.openBox<Map>(_boxName);
        _statisticsBox = await Hive.openBox<Map>(_statisticsBoxName);
        _userProgressBox = await Hive.openBox<Map>(_userProgressBoxName);
        _isInitialized = true;

        // Initialize with default achievements if none exist
        await _initializeDefaultAchievements();

        _logger.i('AchievementRepository initialized successfully');
      }
    } catch (e) {
      _logger.e('Error initializing AchievementRepository: $e');
      throw Exception('Failed to initialize AchievementRepository: $e');
    }
  }

  // ==================== CRUD Operations ====================

  /// Get all achievements
  Future<List<AchievementModel>> getAllAchievements() async {
    try {
      await _ensureInitialized();
      final achievements = <AchievementModel>[];

      for (final data in _achievementBox.values) {
        try {
          final achievement =
              AchievementModel.fromJson(Map<String, dynamic>.from(data));
          achievements.add(achievement);
        } catch (e) {
          _logger.w('Error parsing achievement data: $e');
        }
      }

      // Sort by sort order, then by rarity, then by creation date
      achievements.sort((a, b) {
        if (a.sortOrder != b.sortOrder) {
          return a.sortOrder.compareTo(b.sortOrder);
        }
        if (a.rarity != b.rarity) {
          return b.rarity.index
              .compareTo(a.rarity.index); // Higher rarity first
        }
        return a.createdAt.compareTo(b.createdAt);
      });

      return achievements;
    } catch (e) {
      _logger.e('Error getting all achievements: $e');
      return [];
    }
  }

  /// Get achievement by ID
  Future<AchievementModel?> getAchievementById(String achievementId) async {
    try {
      await _ensureInitialized();
      final data = _achievementBox.get(achievementId);

      if (data != null) {
        return AchievementModel.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      _logger.e('Error getting achievement by ID: $e');
      return null;
    }
  }

  /// Get unlocked achievements
  Future<List<AchievementModel>> getUnlockedAchievements() async {
    try {
      final allAchievements = await getAllAchievements();
      return allAchievements
          .where((achievement) => achievement.isUnlocked)
          .toList();
    } catch (e) {
      _logger.e('Error getting unlocked achievements: $e');
      return [];
    }
  }

  /// Get locked achievements that can be displayed
  Future<List<AchievementModel>> getVisibleLockedAchievements() async {
    try {
      final allAchievements = await getAllAchievements();
      return allAchievements
          .where((achievement) =>
              !achievement.isUnlocked && achievement.canBeDisplayed)
          .toList();
    } catch (e) {
      _logger.e('Error getting visible locked achievements: $e');
      return [];
    }
  }

  /// Get achievements by type
  Future<List<AchievementModel>> getAchievementsByType(
      AchievementType type) async {
    try {
      final allAchievements = await getAllAchievements();
      return allAchievements
          .where((achievement) => achievement.type == type)
          .toList();
    } catch (e) {
      _logger.e('Error getting achievements by type: $e');
      return [];
    }
  }

  /// Get achievements by rarity
  Future<List<AchievementModel>> getAchievementsByRarity(
      AchievementRarity rarity) async {
    try {
      final allAchievements = await getAllAchievements();
      return allAchievements
          .where((achievement) => achievement.rarity == rarity)
          .toList();
    } catch (e) {
      _logger.e('Error getting achievements by rarity: $e');
      return [];
    }
  }

  /// Update achievement
  Future<AchievementModel> updateAchievement(
      AchievementModel achievement) async {
    try {
      await _ensureInitialized();
      await _achievementBox.put(achievement.id, achievement.toJson());
      _logger.i('Achievement updated: ${achievement.title}');

      // Update statistics
      await _updateStatistics();

      return achievement;
    } catch (e) {
      _logger.e('Error updating achievement: $e');
      rethrow;
    }
  }

  /// Create custom achievement
  Future<AchievementModel> createAchievement(
      AchievementModel achievement) async {
    try {
      await _ensureInitialized();
      await _achievementBox.put(achievement.id, achievement.toJson());
      _logger.i('Achievement created: ${achievement.title}');

      // Update statistics
      await _updateStatistics();

      return achievement;
    } catch (e) {
      _logger.e('Error creating achievement: $e');
      rethrow;
    }
  }

  // ==================== Progress Tracking ====================

  /// Update user progress for achievements
  Future<void> updateProgress({
    int? routineCompletions,
    int? goalCompletions,
    int? currentStreak,
    int? longestStreak,
    Map<String, int>? categoryCompletions,
    int? totalTimeSpent,
    int? consecutiveDays,
    bool? perfectWeekAchieved,
    Map<String, dynamic>? customData,
  }) async {
    try {
      await _ensureInitialized();

      // Get current user progress
      final currentProgress = await getUserProgress();

      // Update progress values
      final updatedProgress = currentProgress.copyWith(
        routineCompletions:
            routineCompletions ?? currentProgress.routineCompletions,
        goalCompletions: goalCompletions ?? currentProgress.goalCompletions,
        currentStreak: currentStreak ?? currentProgress.currentStreak,
        longestStreak: longestStreak ?? currentProgress.longestStreak,
        categoryCompletions:
            categoryCompletions ?? currentProgress.categoryCompletions,
        totalTimeSpent: totalTimeSpent ?? currentProgress.totalTimeSpent,
        consecutiveDays: consecutiveDays ?? currentProgress.consecutiveDays,
        perfectWeekAchieved:
            perfectWeekAchieved ?? currentProgress.perfectWeekAchieved,
        customData: customData ?? currentProgress.customData,
        lastUpdated: DateTime.now(),
      );

      // Save updated progress
      await _userProgressBox.put('progress', updatedProgress.toJson());

      // Check for achievement unlocks
      await _checkAndUnlockAchievements(updatedProgress);

      _logger.i('User progress updated');
    } catch (e) {
      _logger.e('Error updating progress: $e');
    }
  }

  /// Get user progress
  Future<UserProgress> getUserProgress() async {
    try {
      await _ensureInitialized();
      final data = _userProgressBox.get('progress');

      if (data != null) {
        return UserProgress.fromJson(Map<String, dynamic>.from(data));
      }

      // Return default progress if none exists
      final defaultProgress = UserProgress.initial();
      await _userProgressBox.put('progress', defaultProgress.toJson());
      return defaultProgress;
    } catch (e) {
      _logger.e('Error getting user progress: $e');
      return UserProgress.initial();
    }
  }

  /// Check and unlock achievements based on current progress
  Future<List<AchievementModel>> _checkAndUnlockAchievements(
      UserProgress progress) async {
    try {
      final achievements = await getAllAchievements();
      final newlyUnlocked = <AchievementModel>[];

      for (final achievement in achievements) {
        if (achievement.isUnlocked) continue;

        bool shouldUnlock = false;
        int newProgress = achievement.currentProgress;

        // Check each unlock condition
        for (final condition in achievement.unlockConditions) {
          final result = _checkUnlockCondition(condition, progress);
          newProgress = result.progress;

          if (result.isUnlocked) {
            shouldUnlock = true;
            break;
          }
        }

        // Update progress if changed
        if (newProgress != achievement.currentProgress) {
          final updatedAchievement =
              achievement.copyWith(currentProgress: newProgress);
          await updateAchievement(updatedAchievement);
        }

        // Unlock achievement if conditions met
        if (shouldUnlock) {
          final unlockedAchievement = achievement.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
            currentProgress: achievement.unlockConditions.first.targetValue,
          );

          await updateAchievement(unlockedAchievement);
          newlyUnlocked.add(unlockedAchievement);

          _logger.i('Achievement unlocked: ${achievement.title}');
        }
      }

      return newlyUnlocked;
    } catch (e) {
      _logger.e('Error checking achievements: $e');
      return [];
    }
  }

  /// Check individual unlock condition
  ({bool isUnlocked, int progress}) _checkUnlockCondition(
    UnlockCondition condition,
    UserProgress progress,
  ) {
    switch (condition.type) {
      case UnlockConditionType.routineCompletion:
        return (
          isUnlocked: progress.routineCompletions >= condition.targetValue,
          progress: progress.routineCompletions,
        );

      case UnlockConditionType.goalCompletion:
        return (
          isUnlocked: progress.goalCompletions >= condition.targetValue,
          progress: progress.goalCompletions,
        );

      case UnlockConditionType.streakAchievement:
        return (
          isUnlocked: progress.longestStreak >= condition.targetValue,
          progress: progress.longestStreak,
        );

      case UnlockConditionType.categoryMastery:
        final categoryCount =
            progress.categoryCompletions[condition.categoryId] ?? 0;
        return (
          isUnlocked: categoryCount >= condition.targetValue,
          progress: categoryCount,
        );

      case UnlockConditionType.timeSpent:
        return (
          isUnlocked: progress.totalTimeSpent >= condition.targetValue,
          progress: progress.totalTimeSpent,
        );

      case UnlockConditionType.consecutiveDays:
        return (
          isUnlocked: progress.consecutiveDays >= condition.targetValue,
          progress: progress.consecutiveDays,
        );

      case UnlockConditionType.perfectWeek:
        return (
          isUnlocked: progress.perfectWeekAchieved,
          progress: progress.perfectWeekAchieved ? 1 : 0,
        );

      case UnlockConditionType.milestoneReached:
      case UnlockConditionType.custom:
        // Custom logic can be implemented here
        return (isUnlocked: false, progress: 0);
    }
  }

  // ==================== Manual Operations ====================

  /// Manually unlock achievement (for testing or special cases)
  Future<AchievementModel> unlockAchievement(String achievementId) async {
    try {
      final achievement = await getAchievementById(achievementId);
      if (achievement == null) throw Exception('Achievement not found');

      if (achievement.isUnlocked) return achievement;

      final unlockedAchievement = achievement.copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
        currentProgress: achievement.unlockConditions.first.targetValue,
      );

      await updateAchievement(unlockedAchievement);
      _logger.i('Achievement manually unlocked: ${achievement.title}');

      return unlockedAchievement;
    } catch (e) {
      _logger.e('Error manually unlocking achievement: $e');
      rethrow;
    }
  }

  /// Reset achievement progress
  Future<AchievementModel> resetAchievement(String achievementId) async {
    try {
      final achievement = await getAchievementById(achievementId);
      if (achievement == null) throw Exception('Achievement not found');

      final resetAchievement = achievement.copyWith(
        isUnlocked: false,
        unlockedAt: null,
        currentProgress: 0,
      );

      await updateAchievement(resetAchievement);
      _logger.i('Achievement reset: ${achievement.title}');

      return resetAchievement;
    } catch (e) {
      _logger.e('Error resetting achievement: $e');
      rethrow;
    }
  }

  /// Reset all achievements
  Future<void> resetAllAchievements() async {
    try {
      final achievements = await getAllAchievements();

      for (final achievement in achievements) {
        if (achievement.isUnlocked) {
          await resetAchievement(achievement.id);
        }
      }

      // Reset user progress
      final resetProgress = UserProgress.initial();
      await _userProgressBox.put('progress', resetProgress.toJson());

      _logger.i('All achievements reset');
    } catch (e) {
      _logger.e('Error resetting all achievements: $e');
      rethrow;
    }
  }

  // ==================== Statistics ====================

  /// Get achievement statistics
  Future<AchievementStatistics> getAchievementStatistics() async {
    try {
      await _ensureInitialized();
      final data = _statisticsBox.get('statistics');

      if (data != null) {
        return AchievementStatistics.fromJson(Map<String, dynamic>.from(data));
      }

      // Calculate and store initial statistics
      return await _calculateAndStoreStatistics();
    } catch (e) {
      _logger.e('Error getting achievement statistics: $e');
      return AchievementStatistics.empty();
    }
  }

  /// Update statistics
  Future<void> _updateStatistics() async {
    try {
      await _calculateAndStoreStatistics();
    } catch (e) {
      _logger.e('Error updating statistics: $e');
    }
  }

  /// Calculate and store statistics
  Future<AchievementStatistics> _calculateAndStoreStatistics() async {
    try {
      final allAchievements = await getAllAchievements();
      final userProgress = await getUserProgress();

      final totalAchievements = allAchievements.length;
      final unlockedAchievements =
          allAchievements.where((a) => a.isUnlocked).length;
      final completionRate = totalAchievements > 0
          ? (unlockedAchievements / totalAchievements) * 100
          : 0.0;

      final totalExperience = allAchievements
          .where((a) => a.isUnlocked)
          .fold<int>(0, (sum, a) => sum + a.experiencePoints);

      final rarityBreakdown = <AchievementRarity, int>{};
      for (final rarity in AchievementRarity.values) {
        rarityBreakdown[rarity] = allAchievements
            .where((a) => a.rarity == rarity && a.isUnlocked)
            .length;
      }

      final typeBreakdown = <AchievementType, int>{};
      for (final type in AchievementType.values) {
        typeBreakdown[type] =
            allAchievements.where((a) => a.type == type && a.isUnlocked).length;
      }

      final stats = AchievementStatistics(
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

      await _statisticsBox.put('statistics', stats.toJson());
      return stats;
    } catch (e) {
      _logger.e('Error calculating statistics: $e');
      return AchievementStatistics.empty();
    }
  }

  // ==================== Helper Methods ====================

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Initialize default achievements from templates
  Future<void> _initializeDefaultAchievements() async {
    try {
      final existingAchievements = await getAllAchievements();

      // Only initialize if no achievements exist
      if (existingAchievements.isEmpty) {
        final defaultAchievements = AchievementTemplates.createAllTemplates();

        for (final achievement in defaultAchievements) {
          await _achievementBox.put(achievement.id, achievement.toJson());
        }

        _logger.i(
            'Initialized ${defaultAchievements.length} default achievements');
      }
    } catch (e) {
      _logger.e('Error initializing default achievements: $e');
    }
  }

  /// Search achievements by title or description
  Future<List<AchievementModel>> searchAchievements(String query) async {
    try {
      final allAchievements = await getAllAchievements();
      final lowerQuery = query.toLowerCase();

      return allAchievements
          .where((achievement) =>
              achievement.canBeDisplayed &&
              (achievement.title.toLowerCase().contains(lowerQuery) ||
                  achievement.description.toLowerCase().contains(lowerQuery) ||
                  achievement.tags
                      .any((tag) => tag.toLowerCase().contains(lowerQuery))))
          .toList();
    } catch (e) {
      _logger.e('Error searching achievements: $e');
      return [];
    }
  }

  /// Get recently unlocked achievements
  Future<List<AchievementModel>> getRecentlyUnlockedAchievements(
      {int limit = 5}) async {
    try {
      final unlockedAchievements = await getUnlockedAchievements();

      // Sort by unlock date (most recent first)
      unlockedAchievements.sort((a, b) =>
          (b.unlockedAt ?? DateTime(0)).compareTo(a.unlockedAt ?? DateTime(0)));

      return unlockedAchievements.take(limit).toList();
    } catch (e) {
      _logger.e('Error getting recently unlocked achievements: $e');
      return [];
    }
  }

  /// Get achievements near completion (80%+ progress)
  Future<List<AchievementModel>> getAchievementsNearCompletion() async {
    try {
      final lockedAchievements = await getVisibleLockedAchievements();
      return lockedAchievements
          .where((achievement) => achievement.isNearCompletion)
          .toList();
    } catch (e) {
      _logger.e('Error getting achievements near completion: $e');
      return [];
    }
  }

  /// Delete all data (for reset purposes)
  Future<void> deleteAllData() async {
    try {
      await _ensureInitialized();
      await _achievementBox.clear();
      await _statisticsBox.clear();
      await _userProgressBox.clear();

      // Reinitialize default achievements
      await _initializeDefaultAchievements();

      _logger.i('All achievement data deleted and reset');
    } catch (e) {
      _logger.e('Error deleting all data: $e');
      rethrow;
    }
  }

  /// Force check all achievements (useful for debugging)
  Future<List<AchievementModel>> forceCheckAchievements() async {
    try {
      final progress = await getUserProgress();
      return await _checkAndUnlockAchievements(progress);
    } catch (e) {
      _logger.e('Error force checking achievements: $e');
      return [];
    }
  }
}
