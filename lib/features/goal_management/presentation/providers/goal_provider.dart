import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../../shared/models/goal_model.dart';
import '../../data/repositories/goal_repository.dart';
import '../../domain/entities/goal_statistics.dart';

// Repository provider
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository();
});

// Goals state notifier
class GoalNotifier extends StateNotifier<AsyncValue<List<GoalModel>>> {
  final GoalRepository _repository;
  final Logger _logger = Logger();

  GoalNotifier(this._repository) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _repository.initialize();
      await loadGoals();
    } catch (e) {
      _logger.e('Error initializing GoalNotifier: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // ==================== Goal Operations ====================

  /// Load all goals
  Future<void> loadGoals() async {
    try {
      state = const AsyncValue.loading();
      final goals = await _repository.getAllGoals();
      state = AsyncValue.data(goals);
      _logger.i('Loaded ${goals.length} goals');
    } catch (e) {
      _logger.e('Error loading goals: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Create new goal
  Future<void> createGoal(GoalModel goal) async {
    try {
      await _repository.createGoal(goal);
      await loadGoals(); // Refresh state
      _logger.i('Goal created: ${goal.name}');
    } catch (e) {
      _logger.e('Error creating goal: $e');
      rethrow;
    }
  }

  /// Create goal from template
  Future<void> createGoalFromTemplate(
    GoalTemplate template, {
    String? routineId,
    String? categoryId,
    List<String>? routineIds,
    String? userId,
    DateTime? customEndDate,
  }) async {
    try {
      final goal = GoalTemplates.createFromTemplate(
        template,
        routineId: routineId,
        categoryId: categoryId,
        routineIds: routineIds,
        userId: userId,
        customEndDate: customEndDate,
      );

      await createGoal(goal);
      _logger.i('Goal created from template: ${template.name}');
    } catch (e) {
      _logger.e('Error creating goal from template: $e');
      rethrow;
    }
  }

  /// Update goal
  Future<void> updateGoal(GoalModel goal) async {
    try {
      await _repository.updateGoal(goal);
      await loadGoals(); // Refresh state
      _logger.i('Goal updated: ${goal.name}');
    } catch (e) {
      _logger.e('Error updating goal: $e');
      rethrow;
    }
  }

  /// Delete goal
  Future<void> deleteGoal(String goalId) async {
    try {
      await _repository.deleteGoal(goalId);
      await loadGoals(); // Refresh state
      _logger.i('Goal deleted: $goalId');
    } catch (e) {
      _logger.e('Error deleting goal: $e');
      rethrow;
    }
  }

  /// Delete all goals
  Future<void> deleteAllGoals() async {
    try {
      await _repository.deleteAllGoals();
      await loadGoals(); // Refresh state
      _logger.i('All goals deleted');
    } catch (e) {
      _logger.e('Error deleting all goals: $e');
      rethrow;
    }
  }

  // ==================== Goal Status Operations ====================

  /// Complete goal
  Future<void> completeGoal(String goalId) async {
    try {
      await _repository.completeGoal(goalId);
      await loadGoals(); // Refresh state
      _logger.i('Goal completed: $goalId');
    } catch (e) {
      _logger.e('Error completing goal: $e');
      rethrow;
    }
  }

  /// Pause goal
  Future<void> pauseGoal(String goalId) async {
    try {
      await _repository.pauseGoal(goalId);
      await loadGoals(); // Refresh state
      _logger.i('Goal paused: $goalId');
    } catch (e) {
      _logger.e('Error pausing goal: $e');
      rethrow;
    }
  }

  /// Resume goal
  Future<void> resumeGoal(String goalId) async {
    try {
      await _repository.resumeGoal(goalId);
      await loadGoals(); // Refresh state
      _logger.i('Goal resumed: $goalId');
    } catch (e) {
      _logger.e('Error resuming goal: $e');
      rethrow;
    }
  }

  /// Fail goal
  Future<void> failGoal(String goalId) async {
    try {
      await _repository.failGoal(goalId);
      await loadGoals(); // Refresh state
      _logger.i('Goal failed: $goalId');
    } catch (e) {
      _logger.e('Error failing goal: $e');
      rethrow;
    }
  }

  /// Mark reward as given
  Future<void> markRewardGiven(String goalId) async {
    try {
      await _repository.markRewardGiven(goalId);
      await loadGoals(); // Refresh state
      _logger.i('Reward marked as given: $goalId');
    } catch (e) {
      _logger.e('Error marking reward as given: $e');
      rethrow;
    }
  }

  // ==================== Progress Tracking ====================

  /// Update goal progress for routine completion
  Future<void> updateProgressForRoutine(
      String routineId, DateTime completionDate) async {
    try {
      await _repository.updateGoalProgressForRoutine(routineId, completionDate);
      await loadGoals(); // Refresh state
      _logger.i('Progress updated for routine: $routineId');
    } catch (e) {
      _logger.e('Error updating progress for routine: $e');
    }
  }

  /// Update goal progress for category completion
  Future<void> updateProgressForCategory(
      String categoryId, DateTime completionDate) async {
    try {
      await _repository.updateGoalProgressForCategory(
          categoryId, completionDate);
      await loadGoals(); // Refresh state
      _logger.i('Progress updated for category: $categoryId');
    } catch (e) {
      _logger.e('Error updating progress for category: $e');
    }
  }

  /// Recalculate all progress
  Future<void> recalculateAllProgress() async {
    try {
      await _repository.recalculateAllProgress();
      await loadGoals(); // Refresh state
      _logger.i('All progress recalculated');
    } catch (e) {
      _logger.e('Error recalculating all progress: $e');
      rethrow;
    }
  }

  /// Check and update expired goals
  Future<void> checkExpiredGoals() async {
    try {
      await _repository.checkAndUpdateExpiredGoals();
      await loadGoals(); // Refresh state
      _logger.i('Expired goals checked and updated');
    } catch (e) {
      _logger.e('Error checking expired goals: $e');
    }
  }
}

// Main goals provider
final goalProvider =
    StateNotifierProvider<GoalNotifier, AsyncValue<List<GoalModel>>>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GoalNotifier(repository);
});

// ==================== Derived Providers ====================

/// Active goals provider
final activeGoalsProvider = Provider<AsyncValue<List<GoalModel>>>((ref) {
  final goalsAsync = ref.watch(goalProvider);
  return goalsAsync.when(
    data: (goals) => AsyncValue.data(
      goals.where((goal) => goal.status == GoalStatus.active).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Completed goals provider
final completedGoalsProvider = Provider<AsyncValue<List<GoalModel>>>((ref) {
  final goalsAsync = ref.watch(goalProvider);
  return goalsAsync.when(
    data: (goals) => AsyncValue.data(
      goals.where((goal) => goal.status == GoalStatus.completed).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Paused goals provider
final pausedGoalsProvider = Provider<AsyncValue<List<GoalModel>>>((ref) {
  final goalsAsync = ref.watch(goalProvider);
  return goalsAsync.when(
    data: (goals) => AsyncValue.data(
      goals.where((goal) => goal.status == GoalStatus.paused).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Failed goals provider
final failedGoalsProvider = Provider<AsyncValue<List<GoalModel>>>((ref) {
  final goalsAsync = ref.watch(goalProvider);
  return goalsAsync.when(
    data: (goals) => AsyncValue.data(
      goals.where((goal) => goal.status == GoalStatus.failed).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Overdue goals provider
final overdueGoalsProvider = Provider<AsyncValue<List<GoalModel>>>((ref) {
  final goalsAsync = ref.watch(goalProvider);
  return goalsAsync.when(
    data: (goals) => AsyncValue.data(
      goals
          .where((goal) => goal.status == GoalStatus.active && goal.isOverdue)
          .toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Goals near completion provider (80%+)
final goalsNearCompletionProvider =
    Provider<AsyncValue<List<GoalModel>>>((ref) {
  final goalsAsync = ref.watch(goalProvider);
  return goalsAsync.when(
    data: (goals) => AsyncValue.data(
      goals
          .where((goal) =>
              goal.status == GoalStatus.active && goal.isNearCompletion)
          .toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Goals by difficulty provider
final goalsByDifficultyProvider =
    Provider.family<AsyncValue<List<GoalModel>>, GoalDifficulty>(
        (ref, difficulty) {
  final goalsAsync = ref.watch(goalProvider);
  return goalsAsync.when(
    data: (goals) => AsyncValue.data(
      goals.where((goal) => goal.difficulty == difficulty).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Goals by routine provider
final goalsByRoutineProvider =
    Provider.family<AsyncValue<List<GoalModel>>, String>((ref, routineId) {
  final goalsAsync = ref.watch(goalProvider);
  return goalsAsync.when(
    data: (goals) => AsyncValue.data(
      goals
          .where((goal) =>
              goal.routineId == routineId ||
              goal.routineIds.contains(routineId))
          .toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Goals by category provider
final goalsByCategoryProvider =
    Provider.family<AsyncValue<List<GoalModel>>, String>((ref, categoryId) {
  final goalsAsync = ref.watch(goalProvider);
  return goalsAsync.when(
    data: (goals) => AsyncValue.data(
      goals.where((goal) => goal.categoryId == categoryId).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Individual goal provider
final goalByIdProvider =
    Provider.family<AsyncValue<GoalModel?>, String>((ref, goalId) {
  final goalsAsync = ref.watch(goalProvider);
  return goalsAsync.when(
    data: (goals) {
      try {
        final goal = goals.firstWhere((goal) => goal.id == goalId);
        return AsyncValue.data(goal);
      } catch (e) {
        return const AsyncValue.data(null);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// ==================== Statistics Providers ====================

/// Goal statistics provider
final goalStatisticsProvider = FutureProvider<GoalStatistics>((ref) async {
  final repository = ref.watch(goalRepositoryProvider);
  await repository.initialize();
  return repository.getGoalStatistics();
});

/// Goal statistics notifier for real-time updates
class GoalStatisticsNotifier extends StateNotifier<AsyncValue<GoalStatistics>> {
  final GoalRepository _repository;
  final Logger _logger = Logger();

  GoalStatisticsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _repository.initialize();
      await loadStatistics();
    } catch (e) {
      _logger.e('Error initializing GoalStatisticsNotifier: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> loadStatistics() async {
    try {
      state = const AsyncValue.loading();
      final stats = await _repository.getGoalStatistics();
      state = AsyncValue.data(stats);
      _logger.i('Goal statistics loaded');
    } catch (e) {
      _logger.e('Error loading goal statistics: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final goalStatisticsNotifierProvider =
    StateNotifierProvider<GoalStatisticsNotifier, AsyncValue<GoalStatistics>>(
        (ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GoalStatisticsNotifier(repository);
});

// ==================== Search Provider ====================

/// Goal search provider
final goalSearchProvider =
    StateNotifierProvider<GoalSearchNotifier, String>((ref) {
  return GoalSearchNotifier();
});

class GoalSearchNotifier extends StateNotifier<String> {
  GoalSearchNotifier() : super('');

  void updateSearchQuery(String query) {
    state = query;
  }

  void clearSearch() {
    state = '';
  }
}

/// Filtered goals based on search
final filteredGoalsProvider = Provider<AsyncValue<List<GoalModel>>>((ref) {
  final goalsAsync = ref.watch(goalProvider);
  final searchQuery = ref.watch(goalSearchProvider);

  return goalsAsync.when(
    data: (goals) {
      if (searchQuery.isEmpty) {
        return AsyncValue.data(goals);
      }

      final lowerQuery = searchQuery.toLowerCase();
      final filteredGoals = goals
          .where((goal) =>
              goal.name.toLowerCase().contains(lowerQuery) ||
              goal.description.toLowerCase().contains(lowerQuery) ||
              goal.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
          .toList();

      return AsyncValue.data(filteredGoals);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// ==================== Helper Providers ====================

/// Goal templates provider
final goalTemplatesProvider = Provider<List<GoalTemplate>>((ref) {
  return GoalTemplates.templates;
});

/// Goal templates by difficulty
final goalTemplatesByDifficultyProvider =
    Provider.family<List<GoalTemplate>, GoalDifficulty>((ref, difficulty) {
  final templates = ref.watch(goalTemplatesProvider);
  return templates
      .where((template) => template.difficulty == difficulty)
      .toList();
});

/// Goal templates by type
final goalTemplatesByTypeProvider =
    Provider.family<List<GoalTemplate>, GoalType>((ref, type) {
  final templates = ref.watch(goalTemplatesProvider);
  return templates.where((template) => template.type == type).toList();
});

/// Goal count by status
final goalCountByStatusProvider = Provider<Map<GoalStatus, int>>((ref) {
  final goalsAsync = ref.watch(goalProvider);
  return goalsAsync.when(
    data: (goals) {
      final counts = <GoalStatus, int>{};
      for (final status in GoalStatus.values) {
        counts[status] = goals.where((goal) => goal.status == status).length;
      }
      return counts;
    },
    loading: () => <GoalStatus, int>{},
    error: (error, stack) => <GoalStatus, int>{},
  );
});

/// Total milestones completed
final totalMilestonesCompletedProvider = Provider<int>((ref) {
  final goalsAsync = ref.watch(goalProvider);
  return goalsAsync.when(
    data: (goals) {
      return goals.fold<int>(
        0,
        (total, goal) => total + goal.completedMilestones.length,
      );
    },
    loading: () => 0,
    error: (error, stack) => 0,
  );
});

/// Average completion rate
final averageCompletionRateProvider = Provider<double>((ref) {
  final goalsAsync = ref.watch(goalProvider);
  return goalsAsync.when(
    data: (goals) {
      if (goals.isEmpty) return 0.0;

      final totalProgress = goals.fold<double>(
        0.0,
        (sum, goal) => sum + goal.progressPercentage,
      );

      return totalProgress / goals.length;
    },
    loading: () => 0.0,
    error: (error, stack) => 0.0,
  );
});
