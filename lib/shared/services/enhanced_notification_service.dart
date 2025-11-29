import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_model.dart';
import '../models/routine_model.dart';
import '../models/streak_model.dart';

class EnhancedNotificationService {
  static final EnhancedNotificationService _instance =
      EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _firebaseMessaging;
  
  FirebaseMessaging? get _firebaseMessagingInstance {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    _firebaseMessaging ??= FirebaseMessaging.instance;
    return _firebaseMessaging;
  }

  final StreamController<NotificationModel> _notificationStreamController =
      StreamController<NotificationModel>.broadcast();

  // Notification templates cache
  final Map<NotificationType, List<NotificationTemplate>> _templateCache = {};

  // Analytics data
  final Map<String, NotificationAnalytics> _analyticsCache = {};

  bool _isInitialized = false;
  String? _fcmToken;
  NotificationPreferences? _currentPreferences;

  // Streams
  Stream<NotificationModel> get notificationStream =>
      _notificationStreamController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeLocalNotifications();
      await _initializeFirebaseMessaging();
      await _loadNotificationTemplates();

      _isInitialized = true;
      debugPrint('Enhanced Notification Service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize notification service: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestNotificationPermissions();
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Check if Firebase is initialized
      final messaging = _firebaseMessagingInstance;
      if (messaging == null) {
        debugPrint('Firebase not initialized - skipping Firebase Messaging setup');
        return;
      }

      // Request permission for iOS
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission for notifications');

        // Get FCM token
        _fcmToken = await messaging.getToken();
        debugPrint('FCM Token: $_fcmToken');

        // Listen to token refresh
        messaging.onTokenRefresh.listen((token) {
          _fcmToken = token;
          _updateFCMTokenInFirestore(token);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background messages
        FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      }
    } catch (e) {
      debugPrint('Failed to initialize Firebase Messaging: $e');
      // Continue without Firebase Messaging - app will work with local notifications only
    }
  }

  Future<void> _requestNotificationPermissions() async {
    final status = await Permission.notification.request();
    if (status.isDenied) {
      debugPrint('Notification permission denied');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload != null) {
        final data = jsonDecode(payload);
        final notification = NotificationModel.fromJson(data);

        // Mark as read
        _markNotificationAsRead(notification.id);

        // Emit to stream
        _notificationStreamController.add(notification.copyWith(isRead: true));

        // Track analytics
        _trackNotificationAction(notification.id, 'tapped');
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');

    // Show as local notification if app is in foreground
    _showLocalNotificationFromRemote(message);
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Background message opened: ${message.messageId}');
    // Handle navigation or other actions
  }

  Future<void> _showLocalNotificationFromRemote(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'routine_care_channel',
      'Routine Care',
      channelDescription: 'Routine Care notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Routine Care',
      message.notification?.body ?? 'You have a new notification',
      details,
      payload: jsonEncode(message.data),
    );
  }

  // Main notification methods
  Future<void> scheduleNotification(NotificationModel notification) async {
    if (!_isInitialized) await initialize();

    // Check preferences
    final prefs =
        await _getNotificationPreferences(notification.userId ?? 'default');
    if (!prefs.isNotificationTypeEnabled(notification.type)) {
      debugPrint('Notification type ${notification.type} is disabled');
      return;
    }

    // Check DND period
    if (prefs.isInDoNotDisturbPeriod &&
        notification.priority != NotificationPriority.urgent) {
      debugPrint('Notification blocked by Do Not Disturb');
      await _rescheduleForAfterDND(notification, prefs);
      return;
    }

    // Apply smart timing if enabled
    if (prefs.smartTimingEnabled) {
      final optimizedTime = await _optimizeNotificationTiming(notification);
      notification = notification.copyWith(scheduledTime: optimizedTime);
    }

    await _scheduleLocalNotification(notification);
    await _saveNotificationToFirestore(notification);

    // Track analytics
    _trackNotificationScheduled(notification);
  }

  Future<void> _scheduleLocalNotification(
      NotificationModel notification) async {
    final androidDetails = AndroidNotificationDetails(
      'routine_care_${notification.type.name}',
      notification.typeDisplayName,
      channelDescription: 'Notifications for ${notification.typeDisplayName}',
      importance: _getAndroidImportance(notification.priority),
      priority: _getAndroidPriority(notification.priority),
      icon: '@mipmap/ic_launcher',
      color: notification.typeColor,
      enableVibration: _currentPreferences?.vibrationEnabled ?? true,
      playSound: _currentPreferences?.soundEnabled ?? true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.zonedSchedule(
      notification.hashCode,
      notification.title,
      notification.body,
      tz.TZDateTime.from(notification.scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode(notification.toJson()),
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Routine-specific notifications
  Future<void> scheduleRoutineReminder(
    RoutineModel routine,
    DateTime reminderTime,
    String userId,
  ) async {
    final template =
        await _getNotificationTemplate(NotificationType.routineReminder);

    final notification = NotificationModel(
      id: 'routine_reminder_${routine.id}_${reminderTime.millisecondsSinceEpoch}',
      type: NotificationType.routineReminder,
      title: template.getTitle({'routineName': routine.name}),
      body: template.getBody(
          {'routineName': routine.name, 'time': _formatTime(reminderTime)}),
      scheduledTime: reminderTime,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
      userId: userId,
      routineId: routine.id,
      data: {
        'routineId': routine.id,
        'routineName': routine.name,
        'categoryId': routine.categoryId,
      },
    );

    await scheduleNotification(notification);
  }

  // Streak-specific notifications
  Future<void> scheduleStreakWarning(
    StreakModel streak,
    String userId,
  ) async {
    final template =
        await _getNotificationTemplate(NotificationType.streakWarning);
    final hoursLeft = _calculateHoursUntilEndOfDay();

    final notification = NotificationModel(
      id: 'streak_warning_${streak.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.streakWarning,
      title: template.getTitle({'streakDays': streak.currentStreak.toString()}),
      body: template.getBody({
        'streakDays': streak.currentStreak.toString(),
        'hoursLeft': hoursLeft.toString(),
      }),
      scheduledTime:
          DateTime.now().add(const Duration(minutes: 5)), // Show immediately
      priority: NotificationPriority.high,
      createdAt: DateTime.now(),
      userId: userId,
      streakId: streak.id,
      data: {
        'streakId': streak.id,
        'streakType': streak.type.name,
        'currentStreak': streak.currentStreak,
        'riskLevel': streak.riskLevel,
      },
    );

    await scheduleNotification(notification);
  }

  Future<void> scheduleStreakMilestone(
    StreakModel streak,
    StreakMilestone milestone,
    String userId,
  ) async {
    final template =
        await _getNotificationTemplate(NotificationType.streakMilestone);

    final notification = NotificationModel(
      id: 'streak_milestone_${streak.id}_${milestone.days}',
      type: NotificationType.streakMilestone,
      title: template.getTitle({
        'milestone': milestone.title,
        'emoji': milestone.emoji,
      }),
      body: template.getBody({
        'streakDays': streak.currentStreak.toString(),
        'milestone': milestone.title,
        'description': milestone.description,
      }),
      scheduledTime: DateTime.now(),
      priority: NotificationPriority.high,
      createdAt: DateTime.now(),
      userId: userId,
      streakId: streak.id,
      data: {
        'streakId': streak.id,
        'milestoneId': milestone.name,
        'milestoneDays': milestone.days,
        'celebration': true,
      },
    );

    await scheduleNotification(notification);
  }

  // Motivational notifications
  Future<void> scheduleMotivationalMessage(String userId) async {
    final template = await _getRandomMotivationalTemplate();

    final notification = NotificationModel(
      id: 'motivational_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.motivational,
      title: template.getTitle({}),
      body: template.getBody({}),
      scheduledTime: await _getOptimalMotivationalTime(userId),
      priority: NotificationPriority.low,
      createdAt: DateTime.now(),
      userId: userId,
      data: {
        'motivational': true,
        'templateId': template.id,
      },
    );

    await scheduleNotification(notification);
  }

  // Daily summary
  Future<void> scheduleDailySummary(
      String userId, Map<String, dynamic> summaryData) async {
    final template =
        await _getNotificationTemplate(NotificationType.dailySummary);

    final notification = NotificationModel(
      id: 'daily_summary_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.dailySummary,
      title: template.getTitle(summaryData),
      body: template.getBody(summaryData),
      scheduledTime:
          DateTime.now().add(const Duration(hours: 1)), // 1 hour from now
      priority: NotificationPriority.low,
      createdAt: DateTime.now(),
      userId: userId,
      data: summaryData,
    );

    await scheduleNotification(notification);
  }

  // Weekly report
  Future<void> scheduleWeeklyReport(
      String userId, Map<String, dynamic> reportData) async {
    final template =
        await _getNotificationTemplate(NotificationType.weeklyReport);

    final notification = NotificationModel(
      id: 'weekly_report_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.weeklyReport,
      title: template.getTitle(reportData),
      body: template.getBody(reportData),
      scheduledTime: DateTime.now(),
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
      userId: userId,
      data: reportData,
    );

    await scheduleNotification(notification);
  }

  // Management methods
  Future<void> cancelNotification(String notificationId) async {
    await _localNotifications.cancel(notificationId.hashCode);
    await _removeNotificationFromFirestore(notificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> cancelNotificationsByType(NotificationType type) async {
    // This would require keeping track of scheduled notifications
    // For now, we'll implement a basic version
    final scheduledNotifications = await getScheduledNotifications();
    for (final notification in scheduledNotifications) {
      if (notification.type == type) {
        await cancelNotification(notification.id);
      }
    }
  }

  Future<List<NotificationModel>> getScheduledNotifications() async {
    // Firestore entegrasyonu henüz yok, şimdilik boş liste döndür
    return [];
  }

  Future<List<NotificationModel>> getNotificationHistory(String userId) async {
    // Firestore entegrasyonu henüz yok, şimdilik boş liste döndür
    return [];
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _markNotificationAsRead(notificationId);
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final notifications = await getNotificationHistory(userId);
      for (final notification in notifications.where((n) => !n.isRead)) {
        await _markNotificationAsRead(notification.id);
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // Smart scheduling methods
  Future<DateTime> _optimizeNotificationTiming(
      NotificationModel notification) async {
    final userId = notification.userId ?? 'default';
    final userBehavior = await _getUserBehaviorData(userId);

    if (userBehavior.isEmpty) {
      return notification.scheduledTime; // Return original time if no data
    }

    // Analyze user's most active times
    final optimalHour = _findOptimalHour(userBehavior, notification.type);

    var optimizedTime = notification.scheduledTime;
    if (optimalHour != null) {
      optimizedTime = DateTime(
        optimizedTime.year,
        optimizedTime.month,
        optimizedTime.day,
        optimalHour,
        optimizedTime.minute,
      );
    }

    return optimizedTime;
  }

  Future<void> _rescheduleForAfterDND(
    NotificationModel notification,
    NotificationPreferences prefs,
  ) async {
    if (prefs.doNotDisturbEnd == null) return;

    final now = DateTime.now();
    final dndEndTime = DateTime(
      now.year,
      now.month,
      now.day,
      prefs.doNotDisturbEnd!.hour,
      prefs.doNotDisturbEnd!.minute,
    );

    // If DND end is tomorrow, schedule for tomorrow
    final rescheduledTime = dndEndTime.isBefore(now)
        ? dndEndTime.add(const Duration(days: 1))
        : dndEndTime
            .add(const Duration(minutes: 15)); // 15 minutes after DND ends

    final rescheduledNotification = notification.copyWith(
      scheduledTime: rescheduledTime,
    );

    await scheduleNotification(rescheduledNotification);
  }

  // Helper methods
  Importance _getAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.urgent:
        return Importance.max;
    }
  }

  Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.urgent:
        return Priority.max;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  int _calculateHoursUntilEndOfDay() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return endOfDay.difference(now).inHours;
  }

  // Firestore operations
  Future<void> _saveNotificationToFirestore(
      NotificationModel notification) async {
    // Firestore entegrasyonu henüz yok, şimdilik no-op
  }

  Future<void> _removeNotificationFromFirestore(String notificationId) async {
    // Firestore entegrasyonu henüz yok, şimdilik no-op
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    // Firestore entegrasyonu henüz yok, şimdilik sadece analytics tarafında işleniyor
  }

  Future<void> _updateFCMTokenInFirestore(String token) async {
    // Firestore entegrasyonu henüz yok, token yalnızca localde tutuluyor
  }

  // Preferences management
  Future<NotificationPreferences> _getNotificationPreferences(
      String userId) async {
    if (_currentPreferences?.userId == userId) {
      return _currentPreferences!;
    }

    // Firestore entegrasyonu henüz yok, sadece bellek içi prefs kullan
    _currentPreferences ??= NotificationPreferences(userId: userId);
    return _currentPreferences!;
  }

  Future<void> updateNotificationPreferences(
      NotificationPreferences preferences) async {
    _currentPreferences = preferences;
    // Firestore entegrasyonu henüz yok, prefs sadece bellek içinde güncelleniyor
  }

  // Template management
  Future<void> _loadNotificationTemplates() async {
    // Load from assets or Firestore
    // For now, we'll use hardcoded templates
    _templateCache[NotificationType.routineReminder] = [
      NotificationTemplate(
        id: 'routine_reminder_1',
        type: NotificationType.routineReminder,
        title: 'Rutin Zamanı! ⏰',
        body: '{{routineName}} rutinini yapmayı unutma!',
      ),
      NotificationTemplate(
        id: 'routine_reminder_2',
        type: NotificationType.routineReminder,
        title: '{{routineName}} için hazır mısın?',
        body:
            'Kendine iyi bakma zamanı! {{time}} için planlanmış rutinini tamamla.',
      ),
    ];

    _templateCache[NotificationType.streakWarning] = [
      NotificationTemplate(
        id: 'streak_warning_1',
        type: NotificationType.streakWarning,
        title: '🔥 Serin Risk Altında!',
        body:
            '{{streakDays}} günlük harika serin kırılmasın! Sadece {{hoursLeft}} saat kaldı.',
      ),
      NotificationTemplate(
        id: 'streak_warning_2',
        type: NotificationType.streakWarning,
        title: '⚠️ Serini Koruma Zamanı',
        body: '{{streakDays}} günlük muhteşem başarın için bugün harekete geç!',
      ),
    ];

    _templateCache[NotificationType.streakMilestone] = [
      NotificationTemplate(
        id: 'streak_milestone_1',
        type: NotificationType.streakMilestone,
        title: '🎉 {{emoji}} {{milestone}} Başarısı!',
        body: 'İnanılmaz! {{streakDays}} günlük serin var. {{description}}',
      ),
    ];

    _templateCache[NotificationType.motivational] = [
      NotificationTemplate(
        id: 'motivational_1',
        type: NotificationType.motivational,
        title: 'Sen Harikasın! ✨',
        body: 'Bugün kendine iyi bakma konusunda ne kadar başarılısın?',
      ),
      NotificationTemplate(
        id: 'motivational_2',
        type: NotificationType.motivational,
        title: 'Küçük Adımlar, Büyük Değişimler 💪',
        body: 'Her gün biraz daha iyi hissetmek için küçük bir şey yap!',
      ),
      NotificationTemplate(
        id: 'motivational_3',
        type: NotificationType.motivational,
        title: 'Kendine Zaman Ayır 🌸',
        body: 'Sen de değerlisin. Bugün kendini önceleyecek misin?',
      ),
    ];
  }

  Future<NotificationTemplate> _getNotificationTemplate(
      NotificationType type) async {
    final templates = _templateCache[type] ?? [];
    if (templates.isEmpty) {
      return NotificationTemplate(
        id: 'default',
        type: type,
        title: 'Routine Care',
        body: 'You have a notification',
      );
    }

    return templates[math.Random().nextInt(templates.length)];
  }

  Future<NotificationTemplate> _getRandomMotivationalTemplate() async {
    return await _getNotificationTemplate(NotificationType.motivational);
  }

  Future<DateTime> _getOptimalMotivationalTime(String userId) async {
    // Analyze user behavior and return optimal time
    // For now, return a time between 10 AM and 8 PM
    final now = DateTime.now();
    final random = math.Random();
    final hour = 10 + random.nextInt(10); // 10 AM to 8 PM

    return DateTime(now.year, now.month, now.day, hour, random.nextInt(60));
  }

  // Analytics methods
  void _trackNotificationScheduled(NotificationModel notification) {
    final analytics = _getOrCreateAnalytics(notification.id);
    analytics.scheduledAt = DateTime.now();
    analytics.type = notification.type;
  }

  void _trackNotificationAction(String notificationId, String action) {
    final analytics = _getOrCreateAnalytics(notificationId);
    analytics.actions.add(NotificationAction(action, DateTime.now()));
  }

  NotificationAnalytics _getOrCreateAnalytics(String notificationId) {
    return _analyticsCache.putIfAbsent(
      notificationId,
      () => NotificationAnalytics(notificationId),
    );
  }

  // User behavior analysis (mock implementation)
  Future<Map<String, dynamic>> _getUserBehaviorData(String userId) async {
    // In real implementation, this would analyze user's app usage patterns
    return {};
  }

  int? _findOptimalHour(
      Map<String, dynamic> behaviorData, NotificationType type) {
    // In real implementation, this would use ML to find optimal notification times
    return null;
  }

  void dispose() {
    _notificationStreamController.close();
  }
}

// Notification template class
class NotificationTemplate {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> metadata;

  const NotificationTemplate({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.metadata = const {},
  });

  String getTitle(Map<String, dynamic> variables) {
    return _replaceVariables(title, variables);
  }

  String getBody(Map<String, dynamic> variables) {
    return _replaceVariables(body, variables);
  }

  String _replaceVariables(String template, Map<String, dynamic> variables) {
    String result = template;
    for (final entry in variables.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value.toString());
    }
    return result;
  }
}

// Analytics classes
class NotificationAnalytics {
  final String notificationId;
  DateTime? scheduledAt;
  DateTime? deliveredAt;
  DateTime? readAt;
  NotificationType? type;
  final List<NotificationAction> actions = [];

  NotificationAnalytics(this.notificationId);

  Duration? get deliveryDelay => scheduledAt != null && deliveredAt != null
      ? deliveredAt!.difference(scheduledAt!)
      : null;

  Duration? get readDelay => deliveredAt != null && readAt != null
      ? readAt!.difference(deliveredAt!)
      : null;

  bool get wasRead => readAt != null;
  bool get wasTapped => actions.any((a) => a.action == 'tapped');
}

class NotificationAction {
  final String action;
  final DateTime timestamp;

  const NotificationAction(this.action, this.timestamp);
}
