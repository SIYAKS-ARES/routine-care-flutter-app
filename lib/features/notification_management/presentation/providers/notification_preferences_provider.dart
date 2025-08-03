import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../../shared/services/enhanced_notification_service.dart';

// Provider for notification service
final notificationServiceProvider =
    Provider<EnhancedNotificationService>((ref) {
  return EnhancedNotificationService();
});

// Provider for notification preferences
final notificationPreferencesProvider = StateNotifierProvider<
    NotificationPreferencesNotifier,
    AsyncValue<NotificationPreferences>>((ref) {
  final notificationService = ref.read(notificationServiceProvider);
  return NotificationPreferencesNotifier(notificationService);
});

class NotificationPreferencesNotifier
    extends StateNotifier<AsyncValue<NotificationPreferences>> {
  final EnhancedNotificationService _notificationService;

  NotificationPreferencesNotifier(this._notificationService)
      : super(const AsyncValue.loading()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      state = const AsyncValue.loading();

      // Get current user ID (replace with actual user management)
      const userId = 'default_user';

      // Load preferences from service
      await _notificationService.initialize();

      // For now, create default preferences
      // In real implementation, this would load from Firestore
      final preferences = NotificationPreferences(
        userId: userId,
        notificationsEnabled: true,
        routineRemindersEnabled: true,
        streakWarningsEnabled: true,
        achievementNotificationsEnabled: true,
        motivationalMessagesEnabled: true,
        dailySummaryEnabled: false,
        weeklyReportEnabled: true,
        doNotDisturbEnabled: false,
        soundEnabled: true,
        vibrationEnabled: true,
        smartTimingEnabled: true,
        contextAwareEnabled: true,
        maxDailyNotifications: 5,
        preferredTone: NotificationTone.gentle,
        snoozeEnabled: true,
        snoozeMinutes: 10,
        maxSnoozeCount: 3,
      );

      state = AsyncValue.data(preferences);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updatePreferences(NotificationPreferences preferences) async {
    try {
      // Update service
      await _notificationService.updateNotificationPreferences(preferences);

      // Update state
      state = AsyncValue.data(preferences);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> resetToDefaults() async {
    try {
      final currentPrefs = state.value;
      if (currentPrefs != null) {
        final defaultPrefs = NotificationPreferences(
          userId: currentPrefs.userId,
        );

        await updatePreferences(defaultPrefs);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void refresh() {
    _loadPreferences();
  }
}

// Provider for notification history
final notificationHistoryProvider =
    FutureProvider.family<List<NotificationModel>, String>((ref, userId) async {
  final notificationService = ref.read(notificationServiceProvider);
  return await notificationService.getNotificationHistory(userId);
});

// Provider for scheduled notifications
final scheduledNotificationsProvider =
    FutureProvider<List<NotificationModel>>((ref) async {
  final notificationService = ref.read(notificationServiceProvider);
  return await notificationService.getScheduledNotifications();
});

// Provider for notification analytics
final notificationAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  // Mock analytics data
  // In real implementation, this would fetch from analytics service
  return {
    'totalSent': 24,
    'totalOpened': 18,
    'openRate': 0.75,
    'bestTime': '09:00',
    'worstTime': '22:00',
    'weeklyTrend': [12, 15, 18, 22, 19, 16, 14],
    'typeBreakdown': {
      'routine': 10,
      'streak': 4,
      'achievement': 3,
      'motivational': 7,
    },
  };
});
