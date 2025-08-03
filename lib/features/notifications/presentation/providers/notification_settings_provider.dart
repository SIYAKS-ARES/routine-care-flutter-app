import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/routine_model.dart';

// Notification Settings State
class NotificationSettingsState {
  final bool isGlobalEnabled;
  final TimeOfDay? globalReminderTime;
  final bool isLoading;
  final String? error;

  const NotificationSettingsState({
    this.isGlobalEnabled = false,
    this.globalReminderTime,
    this.isLoading = false,
    this.error,
  });

  NotificationSettingsState copyWith({
    bool? isGlobalEnabled,
    TimeOfDay? globalReminderTime,
    bool? isLoading,
    String? error,
  }) {
    return NotificationSettingsState(
      isGlobalEnabled: isGlobalEnabled ?? this.isGlobalEnabled,
      globalReminderTime: globalReminderTime ?? this.globalReminderTime,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notification Settings Notifier
class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettingsState> {
  final Box _hiveBox = Hive.box(AppConstants.hiveBoxName);
  final Logger _logger = Logger();

  static const String _globalEnabledKey = 'notification_global_enabled';
  static const String _globalTimeKey = 'notification_global_time';

  NotificationSettingsNotifier() : super(const NotificationSettingsState()) {
    _loadSettings();
  }

  /// Load settings from local storage
  void _loadSettings() {
    try {
      final isEnabled = _hiveBox.get(_globalEnabledKey, defaultValue: false);
      final timeData = _hiveBox.get(_globalTimeKey);

      TimeOfDay? globalTime;
      if (timeData != null && timeData is Map) {
        globalTime = TimeOfDay(
          hour: timeData['hour'] ?? 9,
          minute: timeData['minute'] ?? 0,
        );
      }

      state = state.copyWith(
        isGlobalEnabled: isEnabled,
        globalReminderTime: globalTime,
        isLoading: false,
      );

      _logger.i(
          'Notification settings loaded: enabled=$isEnabled, time=$globalTime');
    } catch (e) {
      _logger.e('Error loading notification settings: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Ayarlar yüklenirken hata oluştu',
      );
    }
  }

  /// Toggle global notifications on/off
  Future<void> toggleGlobalNotifications(bool enabled) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _hiveBox.put(_globalEnabledKey, enabled);

      state = state.copyWith(
        isGlobalEnabled: enabled,
        isLoading: false,
      );

      _logger.i('Global notifications toggled: $enabled');
    } catch (e) {
      _logger.e('Error toggling global notifications: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Ayarlar kaydedilirken hata oluştu',
      );
    }
  }

  /// Set global reminder time
  Future<void> setGlobalReminderTime(TimeOfDay? time) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      if (time != null) {
        await _hiveBox.put(_globalTimeKey, {
          'hour': time.hour,
          'minute': time.minute,
        });
      } else {
        await _hiveBox.delete(_globalTimeKey);
      }

      state = state.copyWith(
        globalReminderTime: time,
        isLoading: false,
      );

      _logger.i('Global reminder time set: $time');
    } catch (e) {
      _logger.e('Error setting global reminder time: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Zaman ayarı kaydedilirken hata oluştu',
      );
    }
  }

  /// Apply global settings to a routine (if routine doesn't have individual settings)
  CustomTimeOfDay? getEffectiveReminderTime(RoutineModel routine) {
    // If routine has its own reminder time, use that
    if (routine.reminderTime != null) {
      return routine.reminderTime;
    }

    // If global notifications are enabled and have a time, use global time
    if (state.isGlobalEnabled && state.globalReminderTime != null) {
      return CustomTimeOfDay(
        hour: state.globalReminderTime!.hour,
        minute: state.globalReminderTime!.minute,
      );
    }

    // No reminder time
    return null;
  }

  /// Check if notifications should be enabled for a routine
  bool shouldNotifyForRoutine(RoutineModel routine) {
    // If routine has individual reminder time, it should notify
    if (routine.reminderTime != null) {
      return true;
    }

    // If global notifications are enabled and have a time, it should notify
    return state.isGlobalEnabled && state.globalReminderTime != null;
  }

  /// Get formatted time string for display
  String? getFormattedGlobalTime() {
    if (state.globalReminderTime == null) return null;

    final time = state.globalReminderTime!;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset settings to default
  Future<void> resetToDefaults() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _hiveBox.delete(_globalEnabledKey);
      await _hiveBox.delete(_globalTimeKey);

      state = const NotificationSettingsState(isLoading: false);

      _logger.i('Notification settings reset to defaults');
    } catch (e) {
      _logger.e('Error resetting notification settings: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Ayarlar sıfırlanırken hata oluştu',
      );
    }
  }

  /// Export settings for backup
  Map<String, dynamic> exportSettings() {
    return {
      'isGlobalEnabled': state.isGlobalEnabled,
      'globalReminderTime': state.globalReminderTime != null
          ? {
              'hour': state.globalReminderTime!.hour,
              'minute': state.globalReminderTime!.minute,
            }
          : null,
    };
  }

  /// Import settings from backup
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final isEnabled = settings['isGlobalEnabled'] ?? false;
      await _hiveBox.put(_globalEnabledKey, isEnabled);

      final timeData = settings['globalReminderTime'];
      if (timeData != null && timeData is Map) {
        await _hiveBox.put(_globalTimeKey, timeData);
      } else {
        await _hiveBox.delete(_globalTimeKey);
      }

      _loadSettings(); // Reload from storage

      _logger.i('Notification settings imported successfully');
    } catch (e) {
      _logger.e('Error importing notification settings: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Ayarlar içe aktarılırken hata oluştu',
      );
    }
  }
}

// Providers
final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsNotifier, NotificationSettingsState>((ref) {
  return NotificationSettingsNotifier();
});

// Derived providers for easier access
final isGlobalNotificationEnabledProvider = Provider<bool>((ref) {
  return ref.watch(notificationSettingsProvider).isGlobalEnabled;
});

final globalReminderTimeProvider = Provider<TimeOfDay?>((ref) {
  return ref.watch(notificationSettingsProvider).globalReminderTime;
});

final notificationSettingsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(notificationSettingsProvider).isLoading;
});

final notificationSettingsErrorProvider = Provider<String?>((ref) {
  return ref.watch(notificationSettingsProvider).error;
});
