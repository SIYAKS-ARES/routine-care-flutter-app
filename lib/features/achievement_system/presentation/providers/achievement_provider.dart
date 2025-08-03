import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/models/achievement_model.dart';
import '../../data/repositories/achievement_repository.dart';
import '../../domain/entities/achievement_statistics.dart';
import '../../domain/entities/user_progress.dart';

// Repository provider
final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return getIt<AchievementRepository>();
});

// Achievements state notifier
class AchievementNotifier
    extends StateNotifier<AsyncValue<List<AchievementModel>>> {
  final AchievementRepository _repository;
  final Logger _logger = Logger();

  AchievementNotifier(this._repository) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _repository.initialize();
      await loadAchievements();
    } catch (e) {
      _logger.e('Error initializing AchievementNotifier: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // ==================== Achievement Operations ====================

  /// Load all achievements
  Future<void> loadAchievements() async {
    try {
      state = const AsyncValue.loading();
      final achievements = await _repository.getAllAchievements();
      state = AsyncValue.data(achievements);
      _logger.i('Loaded ${achievements.length} achievements');
    } catch (e) {
      _logger.e('Error loading achievements: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Create custom achievement
  Future<void> createAchievement(AchievementModel achievement) async {
    try {
      await _repository.createAchievement(achievement);
      await loadAchievements(); // Refresh state
      _logger.i('Achievement created: ${achievement.title}');
    } catch (e) {
      _logger.e('Error creating achievement: $e');
      rethrow;
    }
  }

  /// Update achievement
  Future<void> updateAchievement(AchievementModel achievement) async {
    try {
      await _repository.updateAchievement(achievement);
      await loadAchievements(); // Refresh state
      _logger.i('Achievement updated: ${achievement.title}');
    } catch (e) {
      _logger.e('Error updating achievement: $e');
      rethrow;
    }
  }

  /// Manually unlock achievement
  Future<void> unlockAchievement(String achievementId) async {
    try {
      await _repository.unlockAchievement(achievementId);
      await loadAchievements(); // Refresh state
      _logger.i('Achievement manually unlocked: $achievementId');
    } catch (e) {
      _logger.e('Error unlocking achievement: $e');
      rethrow;
    }
  }

  /// Reset achievement
  Future<void> resetAchievement(String achievementId) async {
    try {
      await _repository.resetAchievement(achievementId);
      await loadAchievements(); // Refresh state
      _logger.i('Achievement reset: $achievementId');
    } catch (e) {
      _logger.e('Error resetting achievement: $e');
      rethrow;
    }
  }

  /// Reset all achievements
  Future<void> resetAllAchievements() async {
    try {
      await _repository.resetAllAchievements();
      await loadAchievements(); // Refresh state
      _logger.i('All achievements reset');
    } catch (e) {
      _logger.e('Error resetting all achievements: $e');
      rethrow;
    }
  }

  /// Force check achievements
  Future<List<AchievementModel>> forceCheckAchievements() async {
    try {
      final newlyUnlocked = await _repository.forceCheckAchievements();
      await loadAchievements(); // Refresh state
      _logger.i(
          'Force checked achievements, ${newlyUnlocked.length} newly unlocked');
      return newlyUnlocked;
    } catch (e) {
      _logger.e('Error force checking achievements: $e');
      return [];
    }
  }

  /// Delete all data
  Future<void> deleteAllData() async {
    try {
      await _repository.deleteAllData();
      await loadAchievements(); // Refresh state
      _logger.i('All achievement data deleted');
    } catch (e) {
      _logger.e('Error deleting all data: $e');
      rethrow;
    }
  }
}

// User Progress state notifier
class UserProgressNotifier extends StateNotifier<AsyncValue<UserProgress>> {
  final AchievementRepository _repository;
  final Logger _logger = Logger();

  UserProgressNotifier(this._repository) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _repository.initialize();
      await loadUserProgress();
    } catch (e) {
      _logger.e('Error initializing UserProgressNotifier: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Load user progress
  Future<void> loadUserProgress() async {
    try {
      state = const AsyncValue.loading();
      final progress = await _repository.getUserProgress();
      state = AsyncValue.data(progress);
      _logger.i('User progress loaded');
    } catch (e) {
      _logger.e('Error loading user progress: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Update progress and check achievements
  Future<List<AchievementModel>> updateProgress({
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
      await _repository.updateProgress(
        routineCompletions: routineCompletions,
        goalCompletions: goalCompletions,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        categoryCompletions: categoryCompletions,
        totalTimeSpent: totalTimeSpent,
        consecutiveDays: consecutiveDays,
        perfectWeekAchieved: perfectWeekAchieved,
        customData: customData,
      );

      await loadUserProgress(); // Refresh state
      _logger.i('User progress updated');

      // Return any newly unlocked achievements
      return await _repository.forceCheckAchievements();
    } catch (e) {
      _logger.e('Error updating progress: $e');
      return [];
    }
  }
}

// Main providers
final achievementProvider = StateNotifierProvider<AchievementNotifier,
    AsyncValue<List<AchievementModel>>>((ref) {
  final repository = ref.watch(achievementRepositoryProvider);
  return AchievementNotifier(repository);
});

final userProgressProvider =
    StateNotifierProvider<UserProgressNotifier, AsyncValue<UserProgress>>(
        (ref) {
  final repository = ref.watch(achievementRepositoryProvider);
  return UserProgressNotifier(repository);
});

// ==================== Derived Providers ====================

/// Unlocked achievements provider
final unlockedAchievementsProvider =
    Provider<AsyncValue<List<AchievementModel>>>((ref) {
  final achievementsAsync = ref.watch(achievementProvider);
  return achievementsAsync.when(
    data: (achievements) => AsyncValue.data(
      achievements.where((achievement) => achievement.isUnlocked).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Locked achievements provider (visible only)
final lockedAchievementsProvider =
    Provider<AsyncValue<List<AchievementModel>>>((ref) {
  final achievementsAsync = ref.watch(achievementProvider);
  return achievementsAsync.when(
    data: (achievements) => AsyncValue.data(
      achievements
          .where((achievement) =>
              !achievement.isUnlocked && achievement.canBeDisplayed)
          .toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Achievements by type provider
final achievementsByTypeProvider =
    Provider.family<AsyncValue<List<AchievementModel>>, AchievementType>(
        (ref, type) {
  final achievementsAsync = ref.watch(achievementProvider);
  return achievementsAsync.when(
    data: (achievements) => AsyncValue.data(
      achievements.where((achievement) => achievement.type == type).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Achievements by rarity provider
final achievementsByRarityProvider =
    Provider.family<AsyncValue<List<AchievementModel>>, AchievementRarity>(
        (ref, rarity) {
  final achievementsAsync = ref.watch(achievementProvider);
  return achievementsAsync.when(
    data: (achievements) => AsyncValue.data(
      achievements
          .where((achievement) => achievement.rarity == rarity)
          .toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Individual achievement provider
final achievementByIdProvider =
    Provider.family<AsyncValue<AchievementModel?>, String>(
        (ref, achievementId) {
  final achievementsAsync = ref.watch(achievementProvider);
  return achievementsAsync.when(
    data: (achievements) {
      try {
        final achievement = achievements
            .firstWhere((achievement) => achievement.id == achievementId);
        return AsyncValue.data(achievement);
      } catch (e) {
        return const AsyncValue.data(null);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Recently unlocked achievements provider
final recentlyUnlockedAchievementsProvider =
    FutureProvider.family<List<AchievementModel>, int>((ref, limit) async {
  final repository = ref.watch(achievementRepositoryProvider);
  await repository.initialize();
  return repository.getRecentlyUnlockedAchievements(limit: limit);
});

/// Achievements near completion provider
final achievementsNearCompletionProvider =
    FutureProvider<List<AchievementModel>>((ref) async {
  final repository = ref.watch(achievementRepositoryProvider);
  await repository.initialize();
  return repository.getAchievementsNearCompletion();
});

// ==================== Statistics Providers ====================

/// Achievement statistics provider
final achievementStatisticsProvider =
    FutureProvider<AchievementStatistics>((ref) async {
  final repository = ref.watch(achievementRepositoryProvider);
  await repository.initialize();
  return repository.getAchievementStatistics();
});

/// Achievement statistics notifier for real-time updates
class AchievementStatisticsNotifier
    extends StateNotifier<AsyncValue<AchievementStatistics>> {
  final AchievementRepository _repository;
  final Logger _logger = Logger();

  AchievementStatisticsNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _repository.initialize();
      await loadStatistics();
    } catch (e) {
      _logger.e('Error initializing AchievementStatisticsNotifier: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> loadStatistics() async {
    try {
      state = const AsyncValue.loading();
      final stats = await _repository.getAchievementStatistics();
      state = AsyncValue.data(stats);
      _logger.i('Achievement statistics loaded');
    } catch (e) {
      _logger.e('Error loading achievement statistics: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final achievementStatisticsNotifierProvider = StateNotifierProvider<
    AchievementStatisticsNotifier, AsyncValue<AchievementStatistics>>((ref) {
  final repository = ref.watch(achievementRepositoryProvider);
  return AchievementStatisticsNotifier(repository);
});

// ==================== Search Providers ====================

/// Achievement search provider
final achievementSearchProvider =
    StateNotifierProvider<AchievementSearchNotifier, String>((ref) {
  return AchievementSearchNotifier();
});

class AchievementSearchNotifier extends StateNotifier<String> {
  AchievementSearchNotifier() : super('');

  void updateSearchQuery(String query) {
    state = query;
  }

  void clearSearch() {
    state = '';
  }
}

/// Filtered achievements based on search
final filteredAchievementsProvider =
    FutureProvider<List<AchievementModel>>((ref) async {
  final repository = ref.watch(achievementRepositoryProvider);
  final searchQuery = ref.watch(achievementSearchProvider);

  await repository.initialize();

  if (searchQuery.isEmpty) {
    return repository.getAllAchievements();
  }

  return repository.searchAchievements(searchQuery);
});

// ==================== Helper Providers ====================

/// Achievement templates provider
final achievementTemplatesProvider = Provider<List<AchievementTemplate>>((ref) {
  return AchievementTemplates.templates;
});

/// Achievement count by rarity
final achievementCountByRarityProvider =
    Provider<Map<AchievementRarity, int>>((ref) {
  final achievementsAsync = ref.watch(achievementProvider);
  return achievementsAsync.when(
    data: (achievements) {
      final counts = <AchievementRarity, int>{};
      for (final rarity in AchievementRarity.values) {
        counts[rarity] = achievements
            .where((achievement) =>
                achievement.rarity == rarity && achievement.isUnlocked)
            .length;
      }
      return counts;
    },
    loading: () => <AchievementRarity, int>{},
    error: (error, stack) => <AchievementRarity, int>{},
  );
});

/// Achievement count by type
final achievementCountByTypeProvider =
    Provider<Map<AchievementType, int>>((ref) {
  final achievementsAsync = ref.watch(achievementProvider);
  return achievementsAsync.when(
    data: (achievements) {
      final counts = <AchievementType, int>{};
      for (final type in AchievementType.values) {
        counts[type] = achievements
            .where((achievement) =>
                achievement.type == type && achievement.isUnlocked)
            .length;
      }
      return counts;
    },
    loading: () => <AchievementType, int>{},
    error: (error, stack) => <AchievementType, int>{},
  );
});

/// Total experience points provider
final totalExperiencePointsProvider = Provider<int>((ref) {
  final achievementsAsync = ref.watch(achievementProvider);
  return achievementsAsync.when(
    data: (achievements) {
      return achievements
          .where((achievement) => achievement.isUnlocked)
          .fold<int>(
              0, (sum, achievement) => sum + achievement.experiencePoints);
    },
    loading: () => 0,
    error: (error, stack) => 0,
  );
});

/// Completion rate provider
final completionRateProvider = Provider<double>((ref) {
  final achievementsAsync = ref.watch(achievementProvider);
  return achievementsAsync.when(
    data: (achievements) {
      if (achievements.isEmpty) return 0.0;

      final unlockedCount =
          achievements.where((achievement) => achievement.isUnlocked).length;
      return (unlockedCount / achievements.length) * 100;
    },
    loading: () => 0.0,
    error: (error, stack) => 0.0,
  );
});

/// User level based on experience points
final userLevelProvider = Provider<int>((ref) {
  final totalXP = ref.watch(totalExperiencePointsProvider);
  // Simple level calculation: level = sqrt(XP / 100)
  return sqrt(totalXP / 100).floor() + 1;
});

/// Progress to next level
final progressToNextLevelProvider = Provider<double>((ref) {
  final totalXP = ref.watch(totalExperiencePointsProvider);
  final currentLevel = ref.watch(userLevelProvider);

  final currentLevelXP = (currentLevel - 1) * (currentLevel - 1) * 100;
  final nextLevelXP = currentLevel * currentLevel * 100;
  final progressXP = totalXP - currentLevelXP;
  final requiredXP = nextLevelXP - currentLevelXP;

  return requiredXP > 0 ? (progressXP / requiredXP) * 100 : 0.0;
});

// ==================== Quick Actions ====================

/// Quick action to increment routine completions
final incrementRoutineCompletionsProvider =
    Provider<Future<List<AchievementModel>> Function({int count})>((ref) {
  return ({int count = 1}) async {
    final notifier = ref.read(userProgressProvider.notifier);
    final progressAsync = ref.read(userProgressProvider);

    return progressAsync.when(
      data: (currentProgress) => notifier.updateProgress(
        routineCompletions: currentProgress.routineCompletions + count,
      ),
      loading: () => <AchievementModel>[],
      error: (error, stack) => <AchievementModel>[],
    );
  };
});

/// Quick action to increment goal completions
final incrementGoalCompletionsProvider =
    Provider<Future<List<AchievementModel>> Function({int count})>((ref) {
  return ({int count = 1}) async {
    final notifier = ref.read(userProgressProvider.notifier);
    final progressAsync = ref.read(userProgressProvider);

    return progressAsync.when(
      data: (currentProgress) => notifier.updateProgress(
        goalCompletions: currentProgress.goalCompletions + count,
      ),
      loading: () => <AchievementModel>[],
      error: (error, stack) => <AchievementModel>[],
    );
  };
});

/// Quick action to update streak
final updateStreakProvider =
    Provider<Future<List<AchievementModel>> Function(int newStreak)>((ref) {
  return (int newStreak) async {
    final notifier = ref.read(userProgressProvider.notifier);
    final progressAsync = ref.read(userProgressProvider);

    return progressAsync.when(
      data: (currentProgress) => notifier.updateProgress(
        currentStreak: newStreak,
        longestStreak: newStreak > currentProgress.longestStreak
            ? newStreak
            : currentProgress.longestStreak,
      ),
      loading: () => <AchievementModel>[],
      error: (error, stack) => <AchievementModel>[],
    );
  };
});

/// Quick action to increment category completions
final incrementCategoryCompletionsProvider = Provider<
    Future<List<AchievementModel>> Function(String categoryId,
        {int count})>((ref) {
  return (String categoryId, {int count = 1}) async {
    final notifier = ref.read(userProgressProvider.notifier);
    final progressAsync = ref.read(userProgressProvider);

    return progressAsync.when(
      data: (currentProgress) {
        final newCategoryCompletions =
            Map<String, int>.from(currentProgress.categoryCompletions);
        newCategoryCompletions[categoryId] =
            (newCategoryCompletions[categoryId] ?? 0) + count;

        return notifier.updateProgress(
          categoryCompletions: newCategoryCompletions,
        );
      },
      loading: () => <AchievementModel>[],
      error: (error, stack) => <AchievementModel>[],
    );
  };
});
