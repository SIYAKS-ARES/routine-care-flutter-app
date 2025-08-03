import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../../shared/models/routine_model.dart';
import '../../data/repositories/routine_repository.dart';
import '../../../../core/di/injection.dart';

// Repository provider
final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return getIt<RoutineRepository>();
});

// Routine state management
class RoutineNotifier extends StateNotifier<AsyncValue<List<RoutineModel>>> {
  final RoutineRepository _repository;
  final Logger _logger = Logger();

  RoutineNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadRoutines();
  }

  // Initialize with user context (call when user logs in)
  void initialize({String? userId}) {
    _repository.initialize(userId: userId);
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    try {
      state = const AsyncValue.loading();
      final routines = await _repository.getRoutines();
      state = AsyncValue.data(routines);
    } catch (error, stackTrace) {
      _logger.e('Error loading routines: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addRoutine(String name) async {
    if (name.trim().isEmpty) return;

    try {
      await _repository.addRoutine(name.trim());
      await _loadRoutines(); // Refresh the list
    } catch (error) {
      _logger.e('Error adding routine: $error');
      // Keep current state, show error via snackbar in UI
    }
  }

  Future<void> addRoutineWithTime(String name, TimeOfDay? reminderTime) async {
    if (name.trim().isEmpty) return;

    try {
      await _repository.addRoutineWithTime(name.trim(), reminderTime);
      await _loadRoutines(); // Refresh the list
    } catch (error) {
      _logger.e('Error adding routine with time: $error');
      // Keep current state, show error via snackbar in UI
    }
  }

  Future<void> updateRoutineName(String routineId, String newName) async {
    if (newName.trim().isEmpty) return;

    final currentState = state.value;
    if (currentState == null) return;

    try {
      final routineIndex = currentState.indexWhere((r) => r.id == routineId);
      if (routineIndex == -1) return;

      final updatedRoutine =
          currentState[routineIndex].copyWith(name: newName.trim());
      await _repository.updateRoutine(updatedRoutine);
      await _loadRoutines(); // Refresh the list
    } catch (error) {
      _logger.e('Error updating routine name: $error');
    }
  }

  Future<void> updateRoutineWithTime(
      String routineId, String newName, TimeOfDay? reminderTime) async {
    if (newName.trim().isEmpty) return;

    final currentState = state.value;
    if (currentState == null) return;

    try {
      final routineIndex = currentState.indexWhere((r) => r.id == routineId);
      if (routineIndex == -1) return;

      CustomTimeOfDay? customTime;
      if (reminderTime != null) {
        customTime = CustomTimeOfDay(
          hour: reminderTime.hour,
          minute: reminderTime.minute,
        );
      }

      final updatedRoutine = currentState[routineIndex].copyWith(
        name: newName.trim(),
        reminderTime: customTime,
      );
      await _repository.updateRoutine(updatedRoutine);
      await _loadRoutines(); // Refresh the list
    } catch (error) {
      _logger.e('Error updating routine with time: $error');
    }
  }

  Future<void> toggleRoutineCompletion(String routineId) async {
    try {
      await _repository.toggleRoutineCompletion(routineId);
      await _loadRoutines(); // Refresh the list
    } catch (error) {
      _logger.e('Error toggling routine completion: $error');
    }
  }

  Future<void> deleteRoutine(String routineId) async {
    try {
      await _repository.deleteRoutine(routineId);
      await _loadRoutines(); // Refresh the list
    } catch (error) {
      _logger.e('Error deleting routine: $error');
    }
  }

  Future<void> reorderRoutines(int oldIndex, int newIndex) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // Create a mutable copy of the list
      final routines = List<RoutineModel>.from(currentState);

      // Handle the reorder logic (standard Flutter approach)
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      // Move the item
      final item = routines.removeAt(oldIndex);
      routines.insert(newIndex, item);

      // Update state immediately for smooth UI
      state = AsyncValue.data(routines);

      // Save the new order to repository
      await _repository.reorderRoutines(routines);
    } catch (error) {
      _logger.e('Error reordering routines: $error');
      // Reload on error to restore correct state
      await _loadRoutines();
    }
  }

  // Force refresh from cloud (pull-to-refresh)
  Future<void> refresh() async {
    await _loadRoutines();
  }

  // Get routine stream for real-time updates
  Stream<List<RoutineModel>> getRoutinesStream() {
    return _repository.getRoutinesStream();
  }
}

// Provider for the routine notifier
final routineNotifierProvider =
    StateNotifierProvider<RoutineNotifier, AsyncValue<List<RoutineModel>>>(
        (ref) {
  final repository = ref.watch(routineRepositoryProvider);
  return RoutineNotifier(repository);
});

// Heat map data provider
class HeatMapData {
  final Map<DateTime, int> heatMapDataSet;
  final DateTime startDate;

  HeatMapData({
    required this.heatMapDataSet,
    required this.startDate,
  });
}

final heatMapDataProvider = FutureProvider<HeatMapData>((ref) async {
  final repository = ref.watch(routineRepositoryProvider);
  final endDate = DateTime.now();
  final startDate =
      DateTime(endDate.year - 1, endDate.month, endDate.day); // 1 year back

  final heatMapData = await repository.getHeatMapData(startDate, endDate);

  return HeatMapData(
    heatMapDataSet: heatMapData,
    startDate: startDate,
  );
});

// Statistics providers
final completionStatsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, days) async {
  final repository = ref.watch(routineRepositoryProvider);
  final endDate = DateTime.now();
  final startDate = endDate.subtract(Duration(days: days));

  final heatMapData = await repository.getHeatMapData(startDate, endDate);

  // Calculate statistics
  final totalDays = days;
  final activeDays = heatMapData.keys.length;
  final averageIntensity = heatMapData.isEmpty
      ? 0.0
      : heatMapData.values.reduce((a, b) => a + b) / heatMapData.length;
  final currentStreak = _calculateCurrentStreak(heatMapData, endDate);
  final longestStreak = _calculateLongestStreak(heatMapData);

  return {
    'totalDays': totalDays,
    'activeDays': activeDays,
    'averageIntensity': averageIntensity,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'completionRate': activeDays / totalDays,
  };
});

// Helper functions for streak calculation
int _calculateCurrentStreak(Map<DateTime, int> heatMapData, DateTime endDate) {
  int streak = 0;
  DateTime currentDate = DateTime(endDate.year, endDate.month, endDate.day);

  while (
      heatMapData.containsKey(currentDate) && heatMapData[currentDate]! > 0) {
    streak++;
    currentDate = currentDate.subtract(const Duration(days: 1));
  }

  return streak;
}

int _calculateLongestStreak(Map<DateTime, int> heatMapData) {
  if (heatMapData.isEmpty) return 0;

  final sortedDates = heatMapData.keys.toList()..sort();
  int longestStreak = 0;
  int currentStreak = 0;
  DateTime? previousDate;

  for (final date in sortedDates) {
    if (heatMapData[date]! > 0) {
      if (previousDate == null || date.difference(previousDate).inDays == 1) {
        currentStreak++;
      } else {
        longestStreak =
            longestStreak > currentStreak ? longestStreak : currentStreak;
        currentStreak = 1;
      }
      previousDate = date;
    } else {
      longestStreak =
          longestStreak > currentStreak ? longestStreak : currentStreak;
      currentStreak = 0;
      previousDate = null;
    }
  }

  return longestStreak > currentStreak ? longestStreak : currentStreak;
}
