import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../models/routine_model.dart';
import 'notification_service.dart';
import '../../core/di/injection.dart';

class RoutineReminderService {
  static final RoutineReminderService _instance =
      RoutineReminderService._internal();
  factory RoutineReminderService() => _instance;
  RoutineReminderService._internal();

  final Logger _logger = Logger();
  late final NotificationService _notificationService;

  /// Initialize the reminder service
  void initialize() {
    _notificationService = getIt<NotificationService>();
    _logger.i('RoutineReminderService initialized');
  }

  /// Schedule reminder for a routine
  Future<void> scheduleRoutineReminder(RoutineModel routine) async {
    try {
      // Check if routine has reminder time and is active
      if (routine.reminderTime == null || !routine.isActive) {
        _logger
            .d('Routine ${routine.name} has no reminder time or is inactive');
        return;
      }

      // Cancel existing reminder for this routine
      await cancelRoutineReminder(routine.id);

      // Create notification ID from routine ID hash
      final notificationId = routine.id.hashCode.abs();

      // Convert CustomTimeOfDay to TimeOfDay
      final reminderTime = TimeOfDay(
        hour: routine.reminderTime!.hour,
        minute: routine.reminderTime!.minute,
      );

      // Schedule daily notification
      await _notificationService.scheduleDailyNotification(
        id: notificationId,
        title: '⏰ Rutin Hatırlatması',
        body: '${routine.name} rutinini yapmayı unutma!',
        notificationTime: reminderTime,
        payload: 'routine_reminder:${routine.id}',
      );

      _logger.i(
          'Scheduled reminder for routine: ${routine.name} at ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}');
    } catch (e) {
      _logger.e('Failed to schedule routine reminder: $e');
    }
  }

  /// Schedule reminders for multiple routines
  Future<void> scheduleMultipleReminders(List<RoutineModel> routines) async {
    for (final routine in routines) {
      await scheduleRoutineReminder(routine);
    }
    _logger.i('Scheduled reminders for ${routines.length} routines');
  }

  /// Cancel reminder for a specific routine
  Future<void> cancelRoutineReminder(String routineId) async {
    try {
      final notificationId = routineId.hashCode.abs();
      await _notificationService.cancelNotification(notificationId);
      _logger.i('Cancelled reminder for routine: $routineId');
    } catch (e) {
      _logger.e('Failed to cancel routine reminder: $e');
    }
  }

  /// Cancel all routine reminders
  Future<void> cancelAllReminders() async {
    try {
      await _notificationService.cancelAllNotifications();
      _logger.i('Cancelled all routine reminders');
    } catch (e) {
      _logger.e('Failed to cancel all reminders: $e');
    }
  }

  /// Update reminder when routine is modified
  Future<void> updateRoutineReminder(RoutineModel routine) async {
    await scheduleRoutineReminder(routine);
    _logger.i('Updated reminder for routine: ${routine.name}');
  }

  /// Schedule completion reminder (remind user later if not completed)
  Future<void> scheduleCompletionReminder(RoutineModel routine) async {
    try {
      if (routine.isCompleted || routine.reminderTime == null) {
        return;
      }

      // Schedule a follow-up reminder 2 hours after the original time
      final originalTime = routine.reminderTime!;
      final followUpTime = DateTime.now()
          .copyWith(
            hour: originalTime.hour,
            minute: originalTime.minute,
            second: 0,
          )
          .add(const Duration(hours: 2));

      // Only schedule if follow-up time is still today and in the future
      if (followUpTime.isAfter(DateTime.now()) &&
          followUpTime.day == DateTime.now().day) {
        final notificationId = '${routine.id}_followup'.hashCode.abs();

        await _notificationService.scheduleNotification(
          id: notificationId,
          title: '🔔 Rutin Takip Hatırlatması',
          body:
              '${routine.name} rutinini henüz tamamlamadın. Şimdi yapabilir misin?',
          scheduledDate: followUpTime,
          payload: 'routine_followup:${routine.id}',
        );

        _logger.i('Scheduled follow-up reminder for routine: ${routine.name}');
      }
    } catch (e) {
      _logger.e('Failed to schedule completion reminder: $e');
    }
  }

  /// Show celebration notification when routine is completed
  Future<void> showCompletionCelebration(RoutineModel routine) async {
    try {
      final notificationId = '${routine.id}_celebration'.hashCode.abs();

      await _notificationService.showNotification(
        id: notificationId,
        title: '🎉 Tebrikler!',
        body: '${routine.name} rutinini başarıyla tamamladın!',
        payload: 'routine_completed:${routine.id}',
      );

      _logger.i('Showed completion celebration for routine: ${routine.name}');
    } catch (e) {
      _logger.e('Failed to show completion celebration: $e');
    }
  }

  /// Check and request notification permissions
  Future<bool> ensurePermissions() async {
    try {
      if (!_notificationService.isInitialized) {
        await _notificationService.initialize();
      }

      final isEnabled = await _notificationService.areNotificationsEnabled();
      if (!isEnabled) {
        // Request permissions
        return await _notificationService.requestPermissions();
      }

      return true;
    } catch (e) {
      _logger.e('Failed to check/request notification permissions: $e');
      return false;
    }
  }

  /// Get all pending routine reminders
  Future<List<String>> getPendingReminders() async {
    try {
      final pending = await _notificationService.getPendingNotifications();
      return pending
          .where((notification) =>
              notification.payload?.startsWith('routine_reminder:') ?? false)
          .map((notification) =>
              notification.payload!.replaceFirst('routine_reminder:', ''))
          .toList();
    } catch (e) {
      _logger.e('Failed to get pending reminders: $e');
      return [];
    }
  }

  /// Reschedule all active routine reminders
  Future<void> rescheduleAllReminders(List<RoutineModel> routines) async {
    try {
      // Cancel all existing reminders
      await cancelAllReminders();

      // Schedule new reminders for active routines
      final activeRoutines =
          routines.where((r) => r.isActive && r.reminderTime != null).toList();
      await scheduleMultipleReminders(activeRoutines);

      _logger.i(
          'Rescheduled all reminders for ${activeRoutines.length} active routines');
    } catch (e) {
      _logger.e('Failed to reschedule all reminders: $e');
    }
  }

  /// Handle timezone changes or app updates
  Future<void> handleSystemChanges(List<RoutineModel> routines) async {
    _logger.i('Handling system changes, rescheduling reminders...');
    await rescheduleAllReminders(routines);
  }
}
