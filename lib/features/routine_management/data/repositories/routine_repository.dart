import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../../../../shared/models/routine_model.dart';
import '../../../../shared/services/routine_reminder_service.dart';
// import '../../../../shared/services/firestore_service.dart'; // Firebase şimdilik devre dışı
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_helper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/di/injection.dart';

class RoutineRepository {
  static final RoutineRepository _instance = RoutineRepository._internal();
  factory RoutineRepository() => _instance;
  RoutineRepository._internal();

  final Box _hiveBox = Hive.box(AppConstants.hiveBoxName);
  // final FirestoreService _firestoreService = FirestoreService(); // Firebase şimdilik devre dışı
  final Logger _logger = Logger();
  RoutineReminderService? _reminderService;
  bool _isInitialized = false;

  String? _currentUserId;
  final bool _isOnline = false; // Şimdilik false - sadece local storage

  // Initialize repository with user context
  void initialize({String? userId}) {
    _currentUserId = userId;
    try {
      _reminderService = getIt<RoutineReminderService>();
      _isInitialized = true;
      _logger.i('RoutineRepository initialized successfully');
    } catch (e) {
      _logger.w('Failed to initialize RoutineReminderService: $e');
      // Continue without reminder service
    }
    // _checkConnectivity(); // Firebase devre dışı
  }

  RoutineReminderService get _safeReminderService {
    if (!_isInitialized || _reminderService == null) {
      try {
        _reminderService = getIt<RoutineReminderService>();
        _isInitialized = true;
      } catch (e) {
        _logger.w('Failed to get RoutineReminderService: $e');
        throw StateError('RoutineReminderService not available');
      }
    }
    return _reminderService!;
  }

  // Future<void> _checkConnectivity() async {
  //   _isOnline = await _firestoreService.isConnected();
  //   _logger.i('Repository online status: $_isOnline');
  // }

  // Get all routines (hybrid: local + cloud)
  Future<List<RoutineModel>> getRoutines() async {
    try {
      final today = DateHelper.todaysDateFormatted();

      // First, try to get from local storage
      List<RoutineModel> localRoutines = await _getLocalRoutines(today);

      // Firebase şimdilik devre dışı - sadece local storage kullan
      // if (_isOnline && _currentUserId != null) {
      //   try {
      //     final cloudRoutines =
      //         await _firestoreService.getUserRoutines(_currentUserId!);
      //     localRoutines =
      //         await _mergeAndSyncRoutines(localRoutines, cloudRoutines);
      //   } catch (e) {
      //     _logger.w('Cloud sync failed, using local data: $e');
      //   }
      // }

      return localRoutines;
    } catch (e) {
      _logger.e('Error getting routines: $e');
      throw CacheException('Failed to get routines: $e');
    }
  }

  // Get routines stream (real-time updates when online)
  Stream<List<RoutineModel>> getRoutinesStream() async* {
    // Start with local data
    yield await getRoutines();

    // Firebase şimdilik devre dışı
    // if (_isOnline && _currentUserId != null) {
    //   yield* _firestoreService.getUserRoutinesStream(_currentUserId!);
    // }
  }

  // Add new routine
  Future<void> addRoutine(String name) async {
    try {
      final newRoutine = RoutineModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        isCompleted: false,
        createdAt: DateTime.now(),
        userId: _currentUserId,
      );

      // Save locally first
      await _saveRoutineLocally(newRoutine);

      // Schedule reminder if time is set
      if (newRoutine.reminderTime != null) {
        try {
          await _safeReminderService.scheduleRoutineReminder(newRoutine);
        } catch (e) {
          _logger.w('Failed to schedule reminder: $e');
          // Continue without reminder
        }
      }

      // Firebase şimdilik devre dışı
      // if (_isOnline && _currentUserId != null) {
      //   try {
      //     await _firestoreService.createRoutine(newRoutine, _currentUserId!);
      //   } catch (e) {
      //     _logger.w('Failed to sync new routine to cloud: $e');
      //     // Mark for later sync
      //     await _markForSync(newRoutine.id, 'create');
      //   }
      // }

      _logger.i('Routine added: ${newRoutine.name}');
    } catch (e) {
      _logger.e('Error adding routine: $e');
      throw CacheException('Failed to add routine: $e');
    }
  }

  // Add new routine with reminder time
  Future<void> addRoutineWithTime(String name, TimeOfDay? reminderTime) async {
    try {
      CustomTimeOfDay? customTime;
      if (reminderTime != null) {
        customTime = CustomTimeOfDay(
          hour: reminderTime.hour,
          minute: reminderTime.minute,
        );
      }

      final newRoutine = RoutineModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        isCompleted: false,
        createdAt: DateTime.now(),
        userId: _currentUserId,
        reminderTime: customTime,
      );

      // Save locally first
      await _saveRoutineLocally(newRoutine);

      // Schedule reminder if time is set
      if (newRoutine.reminderTime != null) {
        try {
          await _safeReminderService.scheduleRoutineReminder(newRoutine);
        } catch (e) {
          _logger.w('Failed to schedule reminder: $e');
          // Continue without reminder
        }
      }

      // Firebase şimdilik devre dışı
      // if (_isOnline && _currentUserId != null) {
      //   try {
      //     await _firestoreService.createRoutine(newRoutine, _currentUserId!);
      //   } catch (e) {
      //     _logger.w('Failed to sync new routine to cloud: $e');
      //     // Mark for later sync
      //     await _markForSync(newRoutine.id, 'create');
      //   }
      // }

      _logger.i('Routine added with time: ${newRoutine.name}');
    } catch (e) {
      _logger.e('Error adding routine with time: $e');
      throw CacheException('Failed to add routine with time: $e');
    }
  }

  // Update routine
  Future<void> updateRoutine(RoutineModel routine) async {
    try {
      // Update locally first
      await _updateRoutineLocally(routine);

      // Update reminder
      try {
        await _safeReminderService.updateRoutineReminder(routine);
      } catch (e) {
        _logger.w('Failed to update reminder: $e');
        // Continue without reminder update
      }

      // Firebase şimdilik devre dışı
      // if (_isOnline && _currentUserId != null) {
      //   try {
      //     await _firestoreService.updateRoutine(routine, _currentUserId!);
      //   } catch (e) {
      //     _logger.w('Failed to sync routine update to cloud: $e');
      //     await _markForSync(routine.id, 'update');
      //   }
      // }

      _logger.i('Routine updated: ${routine.name}');
    } catch (e) {
      _logger.e('Error updating routine: $e');
      throw CacheException('Failed to update routine: $e');
    }
  }

  // Toggle routine completion
  Future<void> toggleRoutineCompletion(String routineId) async {
    try {
      final routines =
          await _getLocalRoutines(DateHelper.todaysDateFormatted());
      final routineIndex = routines.indexWhere((r) => r.id == routineId);

      if (routineIndex == -1) {
        throw const CacheException('Routine not found');
      }

      final updatedRoutine = routines[routineIndex].copyWith(
        isCompleted: !routines[routineIndex].isCompleted,
        lastCompletedAt:
            !routines[routineIndex].isCompleted ? DateTime.now() : null,
      );

      await updateRoutine(updatedRoutine);

      // Handle notification actions based on completion status
      if (updatedRoutine.isCompleted) {
        // Show celebration notification
        try {
          await _safeReminderService.showCompletionCelebration(updatedRoutine);
        } catch (e) {
          _logger.w('Failed to show celebration: $e');
        }

        // Save completion statistics
        if (_currentUserId != null) {
          await _saveCompletionStats(routineId, DateTime.now());
        }
      } else {
        // Schedule follow-up reminder if routine was uncompleted
        try {
          await _safeReminderService.scheduleCompletionReminder(updatedRoutine);
        } catch (e) {
          _logger.w('Failed to schedule completion reminder: $e');
        }
      }
    } catch (e) {
      _logger.e('Error toggling routine completion: $e');
      throw CacheException('Failed to toggle routine completion: $e');
    }
  }

  // Delete routine
  Future<void> deleteRoutine(String routineId) async {
    try {
      // Mark as inactive locally
      final routines =
          await _getLocalRoutines(DateHelper.todaysDateFormatted());
      final routine = routines.firstWhere((r) => r.id == routineId);
      final updatedRoutine = routine.copyWith(isActive: false);

      await _updateRoutineLocally(updatedRoutine);

      // Cancel any scheduled reminders for this routine
      try {
        await _safeReminderService.cancelRoutineReminder(routineId);
      } catch (e) {
        _logger.w('Failed to cancel reminder: $e');
        // Continue without reminder cancellation
      }

      // Firebase şimdilik devre dışı
      // if (_isOnline && _currentUserId != null) {
      //   try {
      //     await _firestoreService.deleteRoutine(routineId, _currentUserId!);
      //   } catch (e) {
      //     _logger.w('Failed to sync routine deletion to cloud: $e');
      //     await _markForSync(routineId, 'delete');
      //   }
      // }

      _logger.i('Routine deleted: $routineId');
    } catch (e) {
      _logger.e('Error deleting routine: $e');
      throw CacheException('Failed to delete routine: $e');
    }
  }

  // Get heat map data
  Future<Map<DateTime, int>> getHeatMapData(
      DateTime startDate, DateTime endDate) async {
    try {
      // Firebase şimdilik devre dışı - sadece local heat map kullan
      // if (_isOnline && _currentUserId != null) {
      //   try {
      //     return await _firestoreService.getRoutineCompletionHeatMap(
      //         _currentUserId!, startDate, endDate);
      //   } catch (e) {
      //     _logger.w('Failed to get heat map from cloud, using local: $e');
      //   }
      // }

      // Fallback to local heat map calculation
      return _calculateLocalHeatMap(startDate, endDate);
    } catch (e) {
      _logger.e('Error getting heat map data: $e');
      return {};
    }
  }

  // Private Methods
  Future<List<RoutineModel>> _getLocalRoutines(String today) async {
    List<dynamic> routineList = _hiveBox.get(today) ??
        _hiveBox.get(AppConstants.currentRoutineListKey) ??
        [];

    // If no data for today, copy from current list and reset completion
    if (_hiveBox.get(today) == null && routineList.isNotEmpty) {
      routineList = List.from(routineList);
      for (int i = 0; i < routineList.length; i++) {
        if (routineList[i] is List && routineList[i].length >= 2) {
          routineList[i][1] = false; // Reset completion status
        }
      }
    }

    return routineList
        .asMap()
        .entries
        .where((entry) => entry.value is List && entry.value.length >= 2)
        .map((entry) => RoutineModel(
              id: entry.key.toString(),
              name: entry.value[0].toString(),
              isCompleted: entry.value[1] as bool,
              createdAt: DateTime.now(),
              userId: _currentUserId,
            ))
        .where((routine) => routine.isActive)
        .toList();
  }

  Future<void> _saveRoutineLocally(RoutineModel routine) async {
    final today = DateHelper.todaysDateFormatted();
    final routines = await _getLocalRoutines(today);
    routines.add(routine);
    await _saveRoutinesLocally(routines);
  }

  Future<void> _updateRoutineLocally(RoutineModel routine) async {
    final today = DateHelper.todaysDateFormatted();
    final routines = await _getLocalRoutines(today);
    final index = routines.indexWhere((r) => r.id == routine.id);

    if (index != -1) {
      routines[index] = routine;
      await _saveRoutinesLocally(routines);
    }
  }

  Future<void> _saveRoutinesLocally(List<RoutineModel> routines) async {
    final today = DateHelper.todaysDateFormatted();
    final routineList = routines
        .where((routine) => routine.isActive)
        .map((routine) => [routine.name, routine.isCompleted])
        .toList();

    await _hiveBox.put(today, routineList);
    await _hiveBox.put(AppConstants.currentRoutineListKey, routineList);

    // Calculate and save percentage
    final completedCount = routines.where((r) => r.isCompleted).length;
    final percentage =
        routines.isEmpty ? 0.0 : completedCount / routines.length;
    await _hiveBox.put(
        'PERCENTAGE_SUMMARY_$today', percentage.toStringAsFixed(1));
  }

  Future<List<RoutineModel>> _mergeAndSyncRoutines(
      List<RoutineModel> localRoutines,
      List<RoutineModel> cloudRoutines) async {
    // Simple merge strategy: cloud data takes precedence for structure,
    // local data takes precedence for today's completion status
    final Map<String, RoutineModel> mergedRoutines = {};

    // Add cloud routines
    for (final routine in cloudRoutines) {
      mergedRoutines[routine.name] = routine;
    }

    // Merge local completion status for today
    for (final localRoutine in localRoutines) {
      if (mergedRoutines.containsKey(localRoutine.name)) {
        mergedRoutines[localRoutine.name] = mergedRoutines[localRoutine.name]!
            .copyWith(isCompleted: localRoutine.isCompleted);
      }
    }

    final result = mergedRoutines.values.toList();
    await _saveRoutinesLocally(result);

    return result;
  }

  Future<void> _saveCompletionStats(
      String routineId, DateTime completionDate) async {
    // Firebase şimdilik devre dışı - sadece local storage kullan
    // if (_isOnline && _currentUserId != null) {
    //   try {
    //     await _firestoreService.saveRoutineCompletion(
    //         routineId, _currentUserId!, completionDate);
    //   } catch (e) {
    //     _logger.w('Failed to save completion stats to cloud: $e');
    //   }
    // }
  }

  Future<void> _markForSync(String routineId, String operation) async {
    // Store operations that need to be synced when back online
    final pendingSyncs =
        _hiveBox.get('pending_syncs', defaultValue: <Map<String, dynamic>>[]);
    pendingSyncs.add({
      'routineId': routineId,
      'operation': operation,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _hiveBox.put('pending_syncs', pendingSyncs);
  }

  // Reorder routines
  Future<void> reorderRoutines(List<RoutineModel> reorderedRoutines) async {
    try {
      await _saveRoutinesLocally(reorderedRoutines);

      // Firebase şimdilik devre dışı - local storage kullan
      // if (_isOnline && _currentUserId != null) {
      //   try {
      //     await _firestoreService.batchUpdateRoutineOrder(reorderedRoutines, _currentUserId!);
      //   } catch (e) {
      //     _logger.w('Failed to sync routine order to cloud: $e');
      //     await _markForSync('reorder', 'reorder');
      //   }
      // }

      _logger.i('Routines reordered successfully');
    } catch (e) {
      _logger.e('Error reordering routines: $e');
      throw CacheException('Failed to reorder routines: $e');
    }
  }

  Map<DateTime, int> _calculateLocalHeatMap(
      DateTime startDate, DateTime endDate) {
    final Map<DateTime, int> heatMap = {};
    final daysBetween = endDate.difference(startDate).inDays;

    for (int i = 0; i <= daysBetween; i++) {
      final currentDate = startDate.add(Duration(days: i));
      final yyyymmdd = DateHelper.convertDateTimeToString(currentDate);

      final percentageString =
          _hiveBox.get('PERCENTAGE_SUMMARY_$yyyymmdd') ?? '0.0';
      final percentage = double.tryParse(percentageString) ?? 0.0;

      heatMap[DateTime(currentDate.year, currentDate.month, currentDate.day)] =
          (10 * percentage).toInt();
    }

    return heatMap;
  }
}
