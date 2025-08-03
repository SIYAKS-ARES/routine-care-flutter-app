import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import '../../../../shared/models/goal_model.dart';
import '../../domain/entities/goal_statistics.dart';

class GoalRepository {
  static const String _boxName = 'goals_box';
  static const String _statisticsBoxName = 'goal_statistics_box';

  final Logger _logger = Logger();
  late Box<Map> _goalBox;
  late Box<Map> _statisticsBox;
  bool _isInitialized = false;

  // Initialize Hive boxes
  Future<void> initialize() async {
    try {
      if (!_isInitialized) {
        _goalBox = await Hive.openBox<Map>(_boxName);
        _statisticsBox = await Hive.openBox<Map>(_statisticsBoxName);
        _isInitialized = true;
        _logger.i('GoalRepository initialized successfully');
      }
    } catch (e) {
      _logger.e('Error initializing GoalRepository: $e');
      throw Exception('Failed to initialize GoalRepository: $e');
    }
  }

  // ==================== CRUD Operations ====================

  /// Create a new goal
  Future<GoalModel> createGoal(GoalModel goal) async {
    try {
      await _ensureInitialized();

      // Check for duplicate names
      final existingGoals = await getAllGoals();
      if (existingGoals
          .any((g) => g.name.toLowerCase() == goal.name.toLowerCase())) {
        throw Exception('Bu isimde bir hedef zaten mevcut');
      }

      await _goalBox.put(goal.id, goal.toJson());
      _logger.i('Goal created: ${goal.name}');

      // Update statistics
      await _updateStatistics();

      return goal;
    } catch (e) {
      _logger.e('Error creating goal: $e');
      rethrow;
    }
  }

  /// Get goal by ID
  Future<GoalModel?> getGoalById(String goalId) async {
    try {
      await _ensureInitialized();
      final data = _goalBox.get(goalId);

      if (data != null) {
        return GoalModel.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      _logger.e('Error getting goal by ID: $e');
      return null;
    }
  }

  /// Get all goals
  Future<List<GoalModel>> getAllGoals() async {
    try {
      await _ensureInitialized();
      final goals = <GoalModel>[];

      for (final data in _goalBox.values) {
        try {
          final goal = GoalModel.fromJson(Map<String, dynamic>.from(data));
          goals.add(goal);
        } catch (e) {
          _logger.w('Error parsing goal data: $e');
        }
      }

      // Sort by creation date (newest first)
      goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return goals;
    } catch (e) {
      _logger.e('Error getting all goals: $e');
      return [];
    }
  }

  /// Get active goals
  Future<List<GoalModel>> getActiveGoals() async {
    try {
      final allGoals = await getAllGoals();
      return allGoals
          .where((goal) => goal.status == GoalStatus.active)
          .toList();
    } catch (e) {
      _logger.e('Error getting active goals: $e');
      return [];
    }
  }

  /// Get completed goals
  Future<List<GoalModel>> getCompletedGoals() async {
    try {
      final allGoals = await getAllGoals();
      return allGoals
          .where((goal) => goal.status == GoalStatus.completed)
          .toList();
    } catch (e) {
      _logger.e('Error getting completed goals: $e');
      return [];
    }
  }

  /// Get goals by routine ID
  Future<List<GoalModel>> getGoalsByRoutineId(String routineId) async {
    try {
      final allGoals = await getAllGoals();
      return allGoals
          .where((goal) =>
              goal.routineId == routineId ||
              goal.routineIds.contains(routineId))
          .toList();
    } catch (e) {
      _logger.e('Error getting goals by routine ID: $e');
      return [];
    }
  }

  /// Get goals by category ID
  Future<List<GoalModel>> getGoalsByCategory(String categoryId) async {
    try {
      final allGoals = await getAllGoals();
      return allGoals.where((goal) => goal.categoryId == categoryId).toList();
    } catch (e) {
      _logger.e('Error getting goals by category: $e');
      return [];
    }
  }

  /// Update goal
  Future<GoalModel> updateGoal(GoalModel goal) async {
    try {
      await _ensureInitialized();

      final updatedGoal = goal.copyWith(
        updatedAt: DateTime.now(),
      );

      await _goalBox.put(goal.id, updatedGoal.toJson());
      _logger.i('Goal updated: ${goal.name}');

      // Update statistics
      await _updateStatistics();

      return updatedGoal;
    } catch (e) {
      _logger.e('Error updating goal: $e');
      rethrow;
    }
  }

  /// Delete goal
  Future<void> deleteGoal(String goalId) async {
    try {
      await _ensureInitialized();
      await _goalBox.delete(goalId);
      _logger.i('Goal deleted: $goalId');

      // Update statistics
      await _updateStatistics();
    } catch (e) {
      _logger.e('Error deleting goal: $e');
      rethrow;
    }
  }

  /// Delete all goals
  Future<void> deleteAllGoals() async {
    try {
      await _ensureInitialized();
      await _goalBox.clear();
      await _statisticsBox.clear();
      _logger.i('All goals deleted');
    } catch (e) {
      _logger.e('Error deleting all goals: $e');
      rethrow;
    }
  }

  // ==================== Progress Tracking ====================

  /// Update goal progress when a routine is completed
  Future<void> updateGoalProgressForRoutine(
      String routineId, DateTime completionDate) async {
    try {
      final goals = await getGoalsByRoutineId(routineId);

      for (final goal in goals) {
        if (goal.status != GoalStatus.active) continue;

        final updatedGoal = await _calculateGoalProgress(goal, completionDate);
        if (updatedGoal != null) {
          await updateGoal(updatedGoal);
        }
      }
    } catch (e) {
      _logger.e('Error updating goal progress for routine: $e');
    }
  }

  /// Update goal progress for category-based goals
  Future<void> updateGoalProgressForCategory(
      String categoryId, DateTime completionDate) async {
    try {
      final goals = await getGoalsByCategory(categoryId);

      for (final goal in goals) {
        if (goal.status != GoalStatus.active) continue;

        final updatedGoal = await _calculateGoalProgress(goal, completionDate);
        if (updatedGoal != null) {
          await updateGoal(updatedGoal);
        }
      }
    } catch (e) {
      _logger.e('Error updating goal progress for category: $e');
    }
  }

  /// Recalculate all goal progress (useful for data sync)
  Future<void> recalculateAllProgress() async {
    try {
      final goals = await getActiveGoals();

      for (final goal in goals) {
        final updatedGoal = await _calculateGoalProgress(goal, DateTime.now());
        if (updatedGoal != null) {
          await updateGoal(updatedGoal);
        }
      }

      _logger.i('All goal progress recalculated');
    } catch (e) {
      _logger.e('Error recalculating all progress: $e');
    }
  }

  /// Calculate goal progress based on type and completion data
  Future<GoalModel?> _calculateGoalProgress(
      GoalModel goal, DateTime completionDate) async {
    try {
      // This would require integration with RoutineRepository to get completion data
      // For now, we'll implement a simplified version

      int newProgress = goal.currentProgress;
      GoalStatus newStatus = goal.status;
      DateTime? completedDate = goal.completedDate;

      // Simple progress increment (in real implementation, this would calculate based on actual data)
      newProgress = goal.currentProgress + 1;

      // Calculate percentage
      final progressPercentage =
          goal.targetValue > 0 ? (newProgress / goal.targetValue) * 100 : 0.0;

      // Check if goal is completed
      if (newProgress >= goal.targetValue) {
        newStatus = GoalStatus.completed;
        completedDate = DateTime.now();
      }

      // Update milestones
      final updatedMilestones = _updateMilestones(goal.milestones, newProgress);

      return goal.copyWith(
        currentProgress: newProgress,
        progressPercentage: progressPercentage,
        status: newStatus,
        completedDate: completedDate,
        milestones: updatedMilestones,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.e('Error calculating goal progress: $e');
      return null;
    }
  }

  /// Update milestone completion status
  List<Milestone> _updateMilestones(
      List<Milestone> milestones, int currentProgress) {
    return milestones.map((milestone) {
      if (!milestone.isCompleted && currentProgress >= milestone.targetValue) {
        return milestone.copyWith(
          isCompleted: true,
          completedDate: DateTime.now(),
          currentProgress: milestone.targetValue,
        );
      } else if (!milestone.isCompleted) {
        return milestone.copyWith(
          currentProgress: currentProgress.clamp(0, milestone.targetValue),
        );
      }
      return milestone;
    }).toList();
  }

  // ==================== Goal Status Management ====================

  /// Mark goal as completed
  Future<GoalModel> completeGoal(String goalId) async {
    try {
      final goal = await getGoalById(goalId);
      if (goal == null) throw Exception('Hedef bulunamadı');

      final completedGoal = goal.copyWith(
        status: GoalStatus.completed,
        completedDate: DateTime.now(),
        currentProgress: goal.targetValue,
        progressPercentage: 100.0,
        updatedAt: DateTime.now(),
      );

      return await updateGoal(completedGoal);
    } catch (e) {
      _logger.e('Error completing goal: $e');
      rethrow;
    }
  }

  /// Pause goal
  Future<GoalModel> pauseGoal(String goalId) async {
    try {
      final goal = await getGoalById(goalId);
      if (goal == null) throw Exception('Hedef bulunamadı');

      final pausedGoal = goal.copyWith(
        status: GoalStatus.paused,
        updatedAt: DateTime.now(),
      );

      return await updateGoal(pausedGoal);
    } catch (e) {
      _logger.e('Error pausing goal: $e');
      rethrow;
    }
  }

  /// Resume paused goal
  Future<GoalModel> resumeGoal(String goalId) async {
    try {
      final goal = await getGoalById(goalId);
      if (goal == null) throw Exception('Hedef bulunamadı');

      final resumedGoal = goal.copyWith(
        status: GoalStatus.active,
        updatedAt: DateTime.now(),
      );

      return await updateGoal(resumedGoal);
    } catch (e) {
      _logger.e('Error resuming goal: $e');
      rethrow;
    }
  }

  /// Mark goal as failed
  Future<GoalModel> failGoal(String goalId) async {
    try {
      final goal = await getGoalById(goalId);
      if (goal == null) throw Exception('Hedef bulunamadı');

      final failedGoal = goal.copyWith(
        status: GoalStatus.failed,
        updatedAt: DateTime.now(),
      );

      return await updateGoal(failedGoal);
    } catch (e) {
      _logger.e('Error failing goal: $e');
      rethrow;
    }
  }

  // ==================== Statistics ====================

  /// Get goal statistics
  Future<GoalStatistics> getGoalStatistics() async {
    try {
      await _ensureInitialized();
      final data = _statisticsBox.get('statistics');

      if (data != null) {
        return GoalStatistics.fromJson(Map<String, dynamic>.from(data));
      }

      // Calculate and store initial statistics
      return await _calculateAndStoreStatistics();
    } catch (e) {
      _logger.e('Error getting goal statistics: $e');
      return GoalStatistics.empty();
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
  Future<GoalStatistics> _calculateAndStoreStatistics() async {
    try {
      final allGoals = await getAllGoals();

      final stats = GoalStatistics(
        totalGoals: allGoals.length,
        activeGoals:
            allGoals.where((g) => g.status == GoalStatus.active).length,
        completedGoals:
            allGoals.where((g) => g.status == GoalStatus.completed).length,
        pausedGoals:
            allGoals.where((g) => g.status == GoalStatus.paused).length,
        failedGoals:
            allGoals.where((g) => g.status == GoalStatus.failed).length,
        expiredGoals:
            allGoals.where((g) => g.status == GoalStatus.expired).length,
        averageCompletionRate: _calculateAverageCompletionRate(allGoals),
        totalMilestonesCompleted: _countCompletedMilestones(allGoals),
        lastUpdated: DateTime.now(),
      );

      await _statisticsBox.put('statistics', stats.toJson());
      return stats;
    } catch (e) {
      _logger.e('Error calculating statistics: $e');
      return GoalStatistics.empty();
    }
  }

  double _calculateAverageCompletionRate(List<GoalModel> goals) {
    if (goals.isEmpty) return 0.0;

    final totalProgress = goals.fold<double>(
      0.0,
      (sum, goal) => sum + goal.progressPercentage,
    );

    return totalProgress / goals.length;
  }

  int _countCompletedMilestones(List<GoalModel> goals) {
    return goals.fold<int>(
      0,
      (count, goal) => count + goal.completedMilestones.length,
    );
  }

  // ==================== Helper Methods ====================

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Search goals by name or description
  Future<List<GoalModel>> searchGoals(String query) async {
    try {
      final allGoals = await getAllGoals();
      final lowerQuery = query.toLowerCase();

      return allGoals
          .where((goal) =>
              goal.name.toLowerCase().contains(lowerQuery) ||
              goal.description.toLowerCase().contains(lowerQuery) ||
              goal.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
          .toList();
    } catch (e) {
      _logger.e('Error searching goals: $e');
      return [];
    }
  }

  /// Get goals by difficulty
  Future<List<GoalModel>> getGoalsByDifficulty(
      GoalDifficulty difficulty) async {
    try {
      final allGoals = await getAllGoals();
      return allGoals.where((goal) => goal.difficulty == difficulty).toList();
    } catch (e) {
      _logger.e('Error getting goals by difficulty: $e');
      return [];
    }
  }

  /// Get overdue goals
  Future<List<GoalModel>> getOverdueGoals() async {
    try {
      final activeGoals = await getActiveGoals();
      return activeGoals.where((goal) => goal.isOverdue).toList();
    } catch (e) {
      _logger.e('Error getting overdue goals: $e');
      return [];
    }
  }

  /// Get goals near completion (80%+)
  Future<List<GoalModel>> getGoalsNearCompletion() async {
    try {
      final activeGoals = await getActiveGoals();
      return activeGoals.where((goal) => goal.isNearCompletion).toList();
    } catch (e) {
      _logger.e('Error getting goals near completion: $e');
      return [];
    }
  }

  /// Update goal rewards status
  Future<GoalModel> markRewardGiven(String goalId) async {
    try {
      final goal = await getGoalById(goalId);
      if (goal == null) throw Exception('Hedef bulunamadı');

      final rewardedGoal = goal.copyWith(
        isRewarded: true,
        updatedAt: DateTime.now(),
      );

      return await updateGoal(rewardedGoal);
    } catch (e) {
      _logger.e('Error marking reward as given: $e');
      rethrow;
    }
  }

  /// Check and update expired goals
  Future<void> checkAndUpdateExpiredGoals() async {
    try {
      final activeGoals = await getActiveGoals();
      final now = DateTime.now();

      for (final goal in activeGoals) {
        if (goal.hasDeadline && goal.endDate!.isBefore(now)) {
          await updateGoal(goal.copyWith(
            status: GoalStatus.expired,
            updatedAt: now,
          ));
        }
      }
    } catch (e) {
      _logger.e('Error checking expired goals: $e');
    }
  }
}
