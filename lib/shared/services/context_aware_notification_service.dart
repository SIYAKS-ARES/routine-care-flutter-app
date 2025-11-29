import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/streak_model.dart';
import 'enhanced_notification_service.dart';
import 'notification_service.dart';
import 'smart_notification_scheduler.dart';
import 'streak_service.dart';
import 'firestore_service.dart';

class ContextAwareNotificationService {
  static final ContextAwareNotificationService _instance =
      ContextAwareNotificationService._internal();
  factory ContextAwareNotificationService() => _instance;
  ContextAwareNotificationService._internal();

  final EnhancedNotificationService _notificationService =
      EnhancedNotificationService();
  final SmartNotificationScheduler _scheduler = SmartNotificationScheduler();
  late final StreakService _streakService;
  final FirestoreService _firestoreService = FirestoreService();

  Timer? _contextMonitoringTimer;
  Timer? _streakMonitoringTimer;
  Timer? _motivationalTimer;

  bool _isInitialized = false;
  String? _currentUserId;

  // Context cache
  final Map<String, UserContext> _contextCache = {};

  // Notification queue for intelligent batching
  final List<PendingNotification> _notificationQueue = [];

  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;

    _currentUserId = userId;

    _streakService = StreakService(_firestoreService, NotificationService());

    await _notificationService.initialize();
    await _scheduler.initialize();

    // Start context monitoring
    _startContextMonitoring();

    // Start streak risk monitoring
    _startStreakRiskMonitoring();

    // Start motivational message scheduling
    _startMotivationalScheduling();

    _isInitialized = true;
    debugPrint(
        'Context-aware notification service initialized for user: $userId');
  }

  void _startContextMonitoring() {
    _contextMonitoringTimer?.cancel();
    _contextMonitoringTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _updateUserContext(),
    );
  }

  void _startStreakRiskMonitoring() {
    _streakMonitoringTimer?.cancel();
    _streakMonitoringTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _monitorStreakRisks(),
    );
  }

  void _startMotivationalScheduling() {
    _motivationalTimer?.cancel();
    _motivationalTimer = Timer.periodic(
      const Duration(hours: 2),
      (_) => _considerMotivationalMessage(),
    );
  }

  // Main context-aware notification methods
  Future<void> scheduleContextAwareNotification({
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? routineId,
    String? streakId,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    if (!_isInitialized || _currentUserId == null) return;

    final pendingNotification = PendingNotification(
      type: type,
      title: title,
      body: body,
      data: data ?? {},
      routineId: routineId,
      streakId: streakId,
      priority: priority,
      createdAt: DateTime.now(),
      userId: _currentUserId!,
    );

    // Immediate delivery for urgent notifications
    if (priority == NotificationPriority.urgent) {
      await _deliverNotificationImmediately(pendingNotification);
      return;
    }

    // Add to queue for intelligent scheduling
    _notificationQueue.add(pendingNotification);
    await _processNotificationQueue();
  }

  Future<void> _updateUserContext() async {
    if (_currentUserId == null) return;

    try {
      final context = await _gatherUserContext(_currentUserId!);
      _contextCache[_currentUserId!] = context;

      // Adjust scheduled notifications based on context
      await _adjustScheduledNotifications(context);
    } catch (e) {
      debugPrint('Error updating user context: $e');
    }
  }

  Future<UserContext> _gatherUserContext(String userId) async {
    final now = DateTime.now();

    // Gather various context signals
    final appActivity = await _getAppActivityLevel(userId);
    final routineProgress = await _getRoutineProgress(userId);
    final streakStatus = await _getStreakStatus(userId);
    final notificationHistory = await _getRecentNotificationHistory(userId);
    final timeContext = _getTimeContext();
    final behaviorPattern = await _getBehaviorPattern(userId);

    return UserContext(
      userId: userId,
      timestamp: now,
      appActivityLevel: appActivity,
      routineCompletionRate: routineProgress.completionRate,
      pendingRoutines: routineProgress.pendingCount,
      overdueRoutines: routineProgress.overdueCount,
      activeStreaks: streakStatus.activeStreaks,
      streaksAtRisk: streakStatus.streaksAtRisk,
      streaksInDanger: streakStatus.streaksInDanger,
      recentNotificationCount: notificationHistory.recentCount,
      lastNotificationResponse: notificationHistory.lastResponse,
      timeOfDay: timeContext.timeOfDay,
      isWeekend: timeContext.isWeekend,
      isWorkingHours: timeContext.isWorkingHours,
      isOptimalTime: behaviorPattern.isOptimalTime,
      stressLevel: await _estimateStressLevel(userId),
      motivationLevel: await _estimateMotivationLevel(userId),
      availabilityScore: await _calculateAvailabilityScore(userId),
    );
  }

  Future<void> _monitorStreakRisks() async {
    if (_currentUserId == null) return;

    try {
      final streaks = await _streakService.getAllActiveStreaks(_currentUserId!);

      for (final streak in streaks) {
        // Yüksek risk: riskLevel 0.8 ve üzeri
        if (streak.riskLevel >= 0.8) {
          await _handleHighRiskStreak(streak);
          // Orta risk: 0.5 - 0.8 aralığı
        } else if (streak.riskLevel >= 0.5) {
          await _handleMediumRiskStreak(streak);
        }
      }
    } catch (e) {
      debugPrint('Error monitoring streak risks: $e');
    }
  }

  Future<void> _handleHighRiskStreak(StreakModel streak) async {
    final context = _contextCache[_currentUserId];
    if (context == null) return;

    // Yüksek riskli streakler için anında dikkat
    final hoursLeft = _calculateHoursUntilEndOfDay();

    if (hoursLeft <= 3 && !context.hasRecentStreakWarning) {
      await scheduleContextAwareNotification(
        type: NotificationType.streakWarning,
        title: '🚨 Seri Risk Altında!',
        body:
            '${streak.currentStreak} günlük harika serin kırılmasın! Sadece $hoursLeft saat kaldı.',
        priority: NotificationPriority.urgent,
        streakId: streak.id,
        data: {
          'streakDays': streak.currentStreak,
          'hoursLeft': hoursLeft,
          'riskLevel': 'high',
          'contextAware': true,
        },
      );
    }
  }

  Future<void> _handleMediumRiskStreak(StreakModel streak) async {
    final context = _contextCache[_currentUserId];
    if (context == null || !context.isOptimalTime) return;

    // Orta riskli streakler için nazik hatırlatmalar
    await scheduleContextAwareNotification(
      type: NotificationType.streakWarning,
      title: '⚡ Serin Devam Etsin',
      body:
          '${streak.currentStreak} günlük başarın devam etsin! Bugün kendine zaman ayırdın mı?',
      priority: NotificationPriority.normal,
      streakId: streak.id,
      data: {
        'streakDays': streak.currentStreak,
        'riskLevel': 'medium',
        'contextAware': true,
      },
    );
  }

  Future<void> _considerMotivationalMessage() async {
    if (_currentUserId == null) return;

    final context = _contextCache[_currentUserId];
    if (context == null) return;

    // Kullanıcıya motivasyon mesajı göndermek gerekiyor mu?
    if (_shouldSendMotivationalMessage(context)) {
      final message = await _generateContextualMotivationalMessage(context);

      await scheduleContextAwareNotification(
        type: NotificationType.motivational,
        title: message.title,
        body: message.body,
        priority: NotificationPriority.low,
        data: {
          'motivationType': message.type,
          'contextAware': true,
          'userContext': context.toSummary(),
        },
      );
    }
  }

  bool _shouldSendMotivationalMessage(UserContext context) {
    // Stresli veya çok sayıda yakın zamanda gönderilmiş bildirim varsa gönderme
    if (context.stressLevel > 0.7 || context.recentNotificationCount > 3) {
      return false;
    }

    // Motivasyon düzeyi düşük ve optimal zaman ise gönder
    if (context.motivationLevel < 0.4 && context.isOptimalTime) {
      return true;
    }

    // Kullanıcı uzun süredir aktif değilse gönder
    if (context.appActivityLevel < 0.3 && context.isOptimalTime) {
      return true;
    }

    // Aktif kullanıcılar için ara sıra motivasyon
    if (context.routineCompletionRate > 0.8 &&
        math.Random().nextDouble() < 0.3) {
      return true;
    }

    return false;
  }

  Future<MotivationalMessage> _generateContextualMotivationalMessage(
      UserContext context) async {
    if (context.routineCompletionRate > 0.8) {
      return const MotivationalMessage(
        title: 'Harika Gidiyorsun! ⭐',
        body:
            'Rutinlerindeki bu tutarlılık gerçekten etkileyici. Kendini ne kadar güzel geliştiriyorsun!',
        type: 'achievement_recognition',
      );
    }

    if (context.streaksAtRisk > 0) {
      return const MotivationalMessage(
        title: 'Güçlüsün! 💪',
        body:
            'Zorlu günler olabilir, ama sen her zaman yolunu buluyorsun. Bugün de küçük bir adım at.',
        type: 'streak_encouragement',
      );
    }

    if (context.pendingRoutines > 2) {
      return const MotivationalMessage(
        title: 'Bir Adım Bir Adım 🌟',
        body:
            'Çok şey biriken olmuş gibi görünüyor. Küçük bir şeyle başla, momentum gelecektir.',
        type: 'overwhelm_support',
      );
    }

    if (context.appActivityLevel < 0.3) {
      return const MotivationalMessage(
        title: 'Selam Yabancı! 👋',
        body:
            'Seni görmeyeli uzun zaman oldu. Bugün kendine nasıl iyi bakacaksın?',
        type: 'reconnection',
      );
    }

    // Varsayılan motivasyon mesajı
    const messages = [
      MotivationalMessage(
        title: 'Sen Değerlisin ✨',
        body: 'Bugün kendine zaman ayırmayı unutma. Sen buna değersin.',
        type: 'self_care',
      ),
      MotivationalMessage(
        title: 'Küçük Adımlar 🌱',
        body:
            'Her büyük değişim küçük adımlarla başlar. Bugün hangi küçük adımı atacaksın?',
        type: 'progress',
      ),
      MotivationalMessage(
        title: 'Bugün de Güzel Geçsin 🌸',
        body:
            'Yeni bir gün, yeni fırsatlar. Kendine karşı sabırlı ve nazik ol.',
        type: 'daily_encouragement',
      ),
    ];

    return messages[math.Random().nextInt(messages.length)];
  }

  Future<void> _processNotificationQueue() async {
    if (_notificationQueue.isEmpty) return;

    final context = _contextCache[_currentUserId];
    if (context == null) return;

    // Sıralama: öncelik ve bağlam uygunluğu
    _notificationQueue.sort((a, b) {
      final aPriority = a.priority.index;
      final bPriority = b.priority.index;

      if (aPriority != bPriority) {
        return bPriority.compareTo(aPriority); // Yüksek öncelikli önce
      }

      return a.createdAt
          .compareTo(b.createdAt); // Aynı öncelikli için eski önce
    });

    // Bildirimleri bağlama göre işleme
    final now = DateTime.now();
    final notifications = _notificationQueue
        .where((n) {
          // Çok sayıda yakın zamanda gönderilmiş bildirim varsa işleme alma
          if (context.recentNotificationCount >= 3) {
            return n.priority == NotificationPriority.urgent;
          }

          // Kullanıcı müsait görünmüyorsa işleme alma
          if (context.availabilityScore < 0.3) {
            return n.priority.index >= NotificationPriority.high.index;
          }

          // Optimal zaman değilse ve düşük öncelikli ise işleme alma
          if (!context.isOptimalTime &&
              n.priority == NotificationPriority.low) {
            return false;
          }

          return true;
        })
        .take(2)
        .toList(); // En fazla 2 bildirim aynı anda

    for (final notification in notifications) {
      await _deliverNotificationImmediately(notification);
      _notificationQueue.remove(notification);
    }
  }

  Future<void> _deliverNotificationImmediately(
      PendingNotification pending) async {
    final notification = NotificationModel(
      id: 'context_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}',
      type: pending.type,
      title: pending.title,
      body: pending.body,
      scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
      priority: pending.priority,
      createdAt: pending.createdAt,
      userId: pending.userId,
      routineId: pending.routineId,
      streakId: pending.streakId,
      data: pending.data,
    );

    await _notificationService.scheduleNotification(notification);
  }

  Future<void> _adjustScheduledNotifications(UserContext context) async {
    // Bu, mevcut bağlama göre zaten planlanmış bildirimleri ayarlayacaktır
    // Örneğin, düşük öncelikli bildirimleri erteleme
    // Uygulama, bildirim servisi yeteneklerine bağlıdır
  }

  // Bağlam toplama yardımcı yöntemleri
  Future<double> _getAppActivityLevel(String userId) async {
    // Mock uygulama - gerçek uygulamada, uygulama kullanımını izleme
    return 0.7; // %70 aktivite düzeyi
  }

  Future<RoutineProgress> _getRoutineProgress(String userId) async {
    // Mock uygulama - gerçek uygulamada, rutin servisinden alma
    return RoutineProgress(
      completionRate: 0.8,
      pendingCount: 2,
      overdueCount: 1,
    );
  }

  Future<StreakStatus> _getStreakStatus(String userId) async {
    try {
      final streaks = await _streakService.getAllActiveStreaks(userId);

      int atRisk = 0;
      int inDanger = 0;

      for (final streak in streaks) {
        // Yüksek risk: riskLevel 0.8 ve üzeri
        if (streak.riskLevel >= 0.8) {
          inDanger++;
          // Orta risk: 0.5 - 0.8 aralığı
        } else if (streak.riskLevel >= 0.5) {
          atRisk++;
        }
      }

      return StreakStatus(
        activeStreaks: streaks.length,
        streaksAtRisk: atRisk,
        streaksInDanger: inDanger,
      );
    } catch (e) {
      return StreakStatus(
          activeStreaks: 0, streaksAtRisk: 0, streaksInDanger: 0);
    }
  }

  Future<NotificationHistory> _getRecentNotificationHistory(
      String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final notifications =
          await _notificationService.getNotificationHistory(userId);
      final recentNotifications =
          notifications.where((n) => n.createdAt.isAfter(startOfDay)).toList();

      return NotificationHistory(
        recentCount: recentNotifications.length,
        lastResponse:
            recentNotifications.isNotEmpty ? recentNotifications.first : null,
      );
    } catch (e) {
      return NotificationHistory(recentCount: 0, lastResponse: null);
    }
  }

  TimeContext _getTimeContext() {
    final now = DateTime.now();
    final hour = now.hour;

    return TimeContext(
      timeOfDay: hour < 12
          ? 'morning'
          : hour < 18
              ? 'afternoon'
              : 'evening',
      isWeekend: now.weekday >= 6,
      isWorkingHours: hour >= 9 && hour <= 17 && now.weekday < 6,
    );
  }

  Future<BehaviorPattern> _getBehaviorPattern(String userId) async {
    // This would analyze user's historical behavior
    // For now, return mock data
    final hour = DateTime.now().hour;
    final isOptimal = (hour >= 9 && hour <= 11) || (hour >= 15 && hour <= 17);

    return BehaviorPattern(isOptimalTime: isOptimal);
  }

  Future<double> _estimateStressLevel(String userId) async {
    // Mock implementation - in real app, analyze various signals
    // High overdue tasks, low completion rate, many notifications = high stress
    final context = _contextCache[userId];
    if (context == null) return 0.3;

    double stress = 0.0;

    if (context.overdueRoutines > 2) stress += 0.3;
    if (context.routineCompletionRate < 0.5) stress += 0.2;
    if (context.recentNotificationCount > 5) stress += 0.3;
    if (context.streaksInDanger > 0) stress += 0.4;

    return stress.clamp(0.0, 1.0);
  }

  Future<double> _estimateMotivationLevel(String userId) async {
    // Mock implementation - in real app, analyze engagement patterns
    final context = _contextCache[userId];
    if (context == null) return 0.6;

    double motivation = 0.6; // Base level

    if (context.routineCompletionRate > 0.8) motivation += 0.3;
    if (context.activeStreaks > 2) motivation += 0.2;
    if (context.appActivityLevel > 0.7) motivation += 0.1;
    if (context.overdueRoutines > 3) motivation -= 0.3;

    return motivation.clamp(0.0, 1.0);
  }

  Future<double> _calculateAvailabilityScore(String userId) async {
    // Mock implementation - consider time of day, app activity, etc.
    final context = _contextCache[userId];
    if (context == null) return 0.5;

    double availability = 0.5;

    if (context.isOptimalTime) availability += 0.3;
    if (context.appActivityLevel > 0.5) availability += 0.2;
    if (context.isWorkingHours) availability -= 0.2;
    if (context.stressLevel > 0.7) availability -= 0.3;

    return availability.clamp(0.0, 1.0);
  }

  int _calculateHoursUntilEndOfDay() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return endOfDay.difference(now).inHours;
  }

  void dispose() {
    _contextMonitoringTimer?.cancel();
    _streakMonitoringTimer?.cancel();
    _motivationalTimer?.cancel();
  }
}

// Supporting classes
class UserContext {
  final String userId;
  final DateTime timestamp;
  final double appActivityLevel;
  final double routineCompletionRate;
  final int pendingRoutines;
  final int overdueRoutines;
  final int activeStreaks;
  final int streaksAtRisk;
  final int streaksInDanger;
  final int recentNotificationCount;
  final NotificationModel? lastNotificationResponse;
  final String timeOfDay;
  final bool isWeekend;
  final bool isWorkingHours;
  final bool isOptimalTime;
  final double stressLevel;
  final double motivationLevel;
  final double availabilityScore;

  const UserContext({
    required this.userId,
    required this.timestamp,
    required this.appActivityLevel,
    required this.routineCompletionRate,
    required this.pendingRoutines,
    required this.overdueRoutines,
    required this.activeStreaks,
    required this.streaksAtRisk,
    required this.streaksInDanger,
    required this.recentNotificationCount,
    this.lastNotificationResponse,
    required this.timeOfDay,
    required this.isWeekend,
    required this.isWorkingHours,
    required this.isOptimalTime,
    required this.stressLevel,
    required this.motivationLevel,
    required this.availabilityScore,
  });

  bool get hasRecentStreakWarning {
    if (lastNotificationResponse == null) return false;

    final wasStreakWarning =
        lastNotificationResponse!.type == NotificationType.streakWarning;
    final wasRecent =
        DateTime.now().difference(lastNotificationResponse!.createdAt).inHours <
            2;

    return wasStreakWarning && wasRecent;
  }

  Map<String, dynamic> toSummary() {
    return {
      'appActivity': appActivityLevel,
      'routineCompletion': routineCompletionRate,
      'pendingRoutines': pendingRoutines,
      'stressLevel': stressLevel,
      'motivationLevel': motivationLevel,
      'timeOfDay': timeOfDay,
      'isOptimalTime': isOptimalTime,
    };
  }
}

class PendingNotification {
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String? routineId;
  final String? streakId;
  final NotificationPriority priority;
  final DateTime createdAt;
  final String userId;

  const PendingNotification({
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    this.routineId,
    this.streakId,
    required this.priority,
    required this.createdAt,
    required this.userId,
  });
}

class MotivationalMessage {
  final String title;
  final String body;
  final String type;

  const MotivationalMessage({
    required this.title,
    required this.body,
    required this.type,
  });
}

class RoutineProgress {
  final double completionRate;
  final int pendingCount;
  final int overdueCount;

  const RoutineProgress({
    required this.completionRate,
    required this.pendingCount,
    required this.overdueCount,
  });
}

class StreakStatus {
  final int activeStreaks;
  final int streaksAtRisk;
  final int streaksInDanger;

  const StreakStatus({
    required this.activeStreaks,
    required this.streaksAtRisk,
    required this.streaksInDanger,
  });
}

class NotificationHistory {
  final int recentCount;
  final NotificationModel? lastResponse;

  const NotificationHistory({
    required this.recentCount,
    this.lastResponse,
  });
}

class TimeContext {
  final String timeOfDay;
  final bool isWeekend;
  final bool isWorkingHours;

  const TimeContext({
    required this.timeOfDay,
    required this.isWeekend,
    required this.isWorkingHours,
  });
}

class BehaviorPattern {
  final bool isOptimalTime;

  const BehaviorPattern({required this.isOptimalTime});
}
