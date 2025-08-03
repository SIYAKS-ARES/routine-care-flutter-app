import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/routine_model.dart';
import '../models/streak_model.dart';
import 'firestore_service.dart';

class SmartNotificationScheduler {
  static final SmartNotificationScheduler _instance =
      SmartNotificationScheduler._internal();
  factory SmartNotificationScheduler() => _instance;
  SmartNotificationScheduler._internal();

  final FirestoreService _firestoreService = FirestoreService();

  // User behavior cache
  final Map<String, UserBehaviorProfile> _behaviorCache = {};

  // Scheduling patterns
  final Map<String, SchedulingPattern> _schedulingPatterns = {};

  // Context cache
  final Map<String, NotificationContext> _contextCache = {};

  // Initialize with default patterns
  Future<void> initialize() async {
    await _loadDefaultSchedulingPatterns();
    await _loadUserBehaviorProfiles();
  }

  Future<void> _loadDefaultSchedulingPatterns() async {
    // Morning routine pattern
    _schedulingPatterns['morning_routine'] = SchedulingPattern(
      id: 'morning_routine',
      name: 'Sabah Rutini',
      optimalHours: [6, 7, 8, 9],
      preferredDays: [1, 2, 3, 4, 5], // Weekdays
      contextFactors: ['energy_level', 'available_time', 'location'],
      successRate: 0.75,
    );

    // Evening routine pattern
    _schedulingPatterns['evening_routine'] = SchedulingPattern(
      id: 'evening_routine',
      name: 'Akşam Rutini',
      optimalHours: [18, 19, 20, 21],
      preferredDays: [1, 2, 3, 4, 5, 6, 7], // All days
      contextFactors: ['stress_level', 'available_time', 'location'],
      successRate: 0.68,
    );

    // Motivational message pattern
    _schedulingPatterns['motivational'] = SchedulingPattern(
      id: 'motivational',
      name: 'Motivasyon Mesajları',
      optimalHours: [10, 11, 14, 15, 16],
      preferredDays: [1, 2, 3, 4, 5],
      contextFactors: ['mood', 'activity_level'],
      successRate: 0.45,
    );

    // Streak warning pattern
    _schedulingPatterns['streak_warning'] = SchedulingPattern(
      id: 'streak_warning',
      name: 'Seri Uyarıları',
      optimalHours: [16, 17, 18, 19, 20],
      preferredDays: [1, 2, 3, 4, 5, 6, 7],
      contextFactors: ['streak_risk', 'time_remaining', 'user_availability'],
      successRate: 0.82,
    );
  }

  Future<void> _loadUserBehaviorProfiles() async {
    // In a real implementation, this would load from Firestore
    // For now, we'll create default profiles
  }

  // Main scheduling method
  Future<DateTime> calculateOptimalTime(
    NotificationModel notification,
    String userId,
  ) async {
    final behaviorProfile = await _getUserBehaviorProfile(userId);
    final context = await _getCurrentContext(userId);
    final pattern = _getSchedulingPattern(notification.type);

    // Apply multiple optimization strategies
    final timeOptions =
        _generateTimeOptions(notification, pattern, behaviorProfile);
    final contextScores =
        await _scoreTimeOptionsWithContext(timeOptions, context);
    final behaviorScores =
        _scoreTimeOptionsWithBehavior(timeOptions, behaviorProfile);

    // Combine scores and select optimal time
    final finalScores = _combineScores(contextScores, behaviorScores);
    final optimalTime = _selectOptimalTime(timeOptions, finalScores);

    // Learn from this decision
    await _recordSchedulingDecision(notification, optimalTime, userId);

    return optimalTime;
  }

  Future<UserBehaviorProfile> _getUserBehaviorProfile(String userId) async {
    if (_behaviorCache.containsKey(userId)) {
      return _behaviorCache[userId]!;
    }

    try {
      final doc = await _firestoreService.getDocument('user_behavior', userId);

      UserBehaviorProfile profile;
      if (doc != null) {
        profile = UserBehaviorProfile.fromJson(doc);
      } else {
        profile = UserBehaviorProfile.createDefault(userId);
        await _saveUserBehaviorProfile(profile);
      }

      _behaviorCache[userId] = profile;
      return profile;
    } catch (e) {
      debugPrint('Error loading user behavior profile: $e');
      final defaultProfile = UserBehaviorProfile.createDefault(userId);
      _behaviorCache[userId] = defaultProfile;
      return defaultProfile;
    }
  }

  Future<NotificationContext> _getCurrentContext(String userId) async {
    final cacheKey = '${userId}_${DateTime.now().day}';

    if (_contextCache.containsKey(cacheKey)) {
      return _contextCache[cacheKey]!;
    }

    final context = NotificationContext(
      userId: userId,
      timestamp: DateTime.now(),
      dayOfWeek: DateTime.now().weekday,
      timeOfDay: TimeOfDay.fromDateTime(DateTime.now()),
      isWeekend: DateTime.now().weekday >= 6,
      batteryLevel: await _getBatteryLevel(),
      networkStatus: await _getNetworkStatus(),
      appUsageToday: await _getAppUsageToday(userId),
      lastNotificationResponse: await _getLastNotificationResponse(userId),
      currentStreakRisks: await _getCurrentStreakRisks(userId),
      pendingRoutines: await _getPendingRoutines(userId),
    );

    _contextCache[cacheKey] = context;
    return context;
  }

  SchedulingPattern _getSchedulingPattern(NotificationType type) {
    switch (type) {
      case NotificationType.routineReminder:
        return _schedulingPatterns['morning_routine'] ?? _getDefaultPattern();
      case NotificationType.streakWarning:
        return _schedulingPatterns['streak_warning'] ?? _getDefaultPattern();
      case NotificationType.motivational:
        return _schedulingPatterns['motivational'] ?? _getDefaultPattern();
      default:
        return _getDefaultPattern();
    }
  }

  SchedulingPattern _getDefaultPattern() {
    return SchedulingPattern(
      id: 'default',
      name: 'Varsayılan',
      optimalHours: [9, 12, 15, 18],
      preferredDays: [1, 2, 3, 4, 5, 6, 7],
      contextFactors: [],
      successRate: 0.5,
    );
  }

  List<DateTime> _generateTimeOptions(
    NotificationModel notification,
    SchedulingPattern pattern,
    UserBehaviorProfile behaviorProfile,
  ) {
    final baseTime = notification.scheduledTime;
    final options = <DateTime>[];

    // Generate options based on pattern optimal hours
    for (final hour in pattern.optimalHours) {
      final optionTime = DateTime(
        baseTime.year,
        baseTime.month,
        baseTime.day,
        hour,
        baseTime.minute,
      );

      // Only add future times
      if (optionTime.isAfter(DateTime.now())) {
        options.add(optionTime);
      }
    }

    // Add user's historically successful times
    for (final hour in behaviorProfile.successfulNotificationHours) {
      final optionTime = DateTime(
        baseTime.year,
        baseTime.month,
        baseTime.day,
        hour,
        baseTime.minute,
      );

      if (optionTime.isAfter(DateTime.now()) && !options.contains(optionTime)) {
        options.add(optionTime);
      }
    }

    // If no options, use original time
    if (options.isEmpty) {
      options.add(baseTime);
    }

    return options;
  }

  Future<Map<DateTime, double>> _scoreTimeOptionsWithContext(
    List<DateTime> timeOptions,
    NotificationContext context,
  ) async {
    final scores = <DateTime, double>{};

    for (final time in timeOptions) {
      double score = 0.5; // Base score

      // Time of day scoring
      final hour = time.hour;
      if (hour >= 6 && hour <= 9) {
        score += 0.2; // Morning bonus
      } else if (hour >= 18 && hour <= 21) {
        score += 0.15; // Evening bonus
      } else if (hour >= 22 || hour <= 5) {
        score -= 0.3; // Late night penalty
      }

      // Day of week scoring
      if (context.isWeekend) {
        if (hour >= 8 && hour <= 20) {
          score += 0.1; // Weekend flexibility
        }
      } else {
        if (hour >= 7 && hour <= 9 || hour >= 17 && hour <= 19) {
          score += 0.15; // Weekday routine times
        }
      }

      // Battery level impact
      if (context.batteryLevel < 20) {
        score -= 0.1; // Low battery penalty
      }

      // App usage pattern
      if (context.appUsageToday > 30) {
        score += 0.1; // User is active today
      }

      // Last notification response
      if (context.lastNotificationResponse != null) {
        final timeSinceLastResponse = DateTime.now()
            .difference(context.lastNotificationResponse!.timestamp);

        if (timeSinceLastResponse.inHours < 2) {
          score -= 0.2; // Don't spam too soon
        } else if (timeSinceLastResponse.inHours > 6) {
          score += 0.1; // Good time gap
        }
      }

      scores[time] = score.clamp(0.0, 1.0);
    }

    return scores;
  }

  Map<DateTime, double> _scoreTimeOptionsWithBehavior(
    List<DateTime> timeOptions,
    UserBehaviorProfile behaviorProfile,
  ) {
    final scores = <DateTime, double>{};

    for (final time in timeOptions) {
      double score = 0.5; // Base score

      // Historical success rate for this hour
      final hour = time.hour;
      final hourSuccessRate = behaviorProfile.getSuccessRateForHour(hour);
      score +=
          (hourSuccessRate - 0.5) * 0.4; // Adjust based on historical success

      // Day of week preference
      final dayOfWeek = time.weekday;
      final daySuccessRate = behaviorProfile.getSuccessRateForDay(dayOfWeek);
      score += (daySuccessRate - 0.5) * 0.3;

      // Personal optimal times
      if (behaviorProfile.personalOptimalHours.contains(hour)) {
        score += 0.2;
      }

      // Avoid low-response periods
      if (behaviorProfile.lowResponseHours.contains(hour)) {
        score -= 0.3;
      }

      scores[time] = score.clamp(0.0, 1.0);
    }

    return scores;
  }

  Map<DateTime, double> _combineScores(
    Map<DateTime, double> contextScores,
    Map<DateTime, double> behaviorScores,
  ) {
    final combinedScores = <DateTime, double>{};

    for (final time in contextScores.keys) {
      final contextScore = contextScores[time] ?? 0.5;
      final behaviorScore = behaviorScores[time] ?? 0.5;

      // Weight: 60% behavior, 40% context
      final combinedScore = (behaviorScore * 0.6) + (contextScore * 0.4);
      combinedScores[time] = combinedScore;
    }

    return combinedScores;
  }

  DateTime _selectOptimalTime(
    List<DateTime> timeOptions,
    Map<DateTime, double> finalScores,
  ) {
    if (timeOptions.isEmpty) {
      return DateTime.now().add(const Duration(hours: 1));
    }

    // Find time with highest score
    DateTime bestTime = timeOptions.first;
    double bestScore = finalScores[bestTime] ?? 0.0;

    for (final time in timeOptions) {
      final score = finalScores[time] ?? 0.0;
      if (score > bestScore) {
        bestScore = score;
        bestTime = time;
      }
    }

    return bestTime;
  }

  // Context-aware methods
  Future<bool> shouldDelayNotification(
    NotificationModel notification,
    String userId,
  ) async {
    final context = await _getCurrentContext(userId);
    final behaviorProfile = await _getUserBehaviorProfile(userId);

    // Check Do Not Disturb
    if (await _isInDoNotDisturbPeriod(userId)) {
      return true;
    }

    // Check user activity
    if (context.appUsageToday == 0) {
      return true; // User not active today
    }

    // Check battery level
    if (context.batteryLevel < 10) {
      return true; // Very low battery
    }

    // Check recent notification fatigue
    if (await _hasNotificationFatigue(userId)) {
      return true;
    }

    // Check historical success rate for current time
    final currentHour = DateTime.now().hour;
    final successRate = behaviorProfile.getSuccessRateForHour(currentHour);
    if (successRate < 0.2) {
      return true; // Poor historical performance
    }

    return false;
  }

  Future<Duration> calculateOptimalDelay(
    NotificationModel notification,
    String userId,
  ) async {
    final behaviorProfile = await _getUserBehaviorProfile(userId);
    final nextOptimalHour = _findNextOptimalHour(behaviorProfile);

    if (nextOptimalHour != null) {
      final now = DateTime.now();
      final nextOptimalTime = DateTime(
        now.year,
        now.month,
        now.day,
        nextOptimalHour,
        now.minute,
      );

      if (nextOptimalTime.isBefore(now)) {
        // Next day
        nextOptimalTime.add(const Duration(days: 1));
      }

      return nextOptimalTime.difference(now);
    }

    // Default delay: 1-3 hours
    return Duration(hours: 1 + math.Random().nextInt(3));
  }

  int? _findNextOptimalHour(UserBehaviorProfile behaviorProfile) {
    final currentHour = DateTime.now().hour;

    // Find next optimal hour after current time
    for (int i = 1; i <= 24; i++) {
      final checkHour = (currentHour + i) % 24;
      if (behaviorProfile.personalOptimalHours.contains(checkHour)) {
        return checkHour;
      }
    }

    return null;
  }

  // Analytics and learning
  Future<void> _recordSchedulingDecision(
    NotificationModel notification,
    DateTime scheduledTime,
    String userId,
  ) async {
    final decision = SchedulingDecision(
      notificationId: notification.id,
      originalTime: notification.scheduledTime,
      optimizedTime: scheduledTime,
      userId: userId,
      timestamp: DateTime.now(),
      reasoning: 'Smart scheduling optimization',
    );

    try {
      await _firestoreService.addDocument(
        'scheduling_decisions',
        decision.toJson(),
      );
    } catch (e) {
      debugPrint('Error recording scheduling decision: $e');
    }
  }

  Future<void> updateUserBehaviorFromResponse(
    String userId,
    String notificationId,
    NotificationResponse response,
  ) async {
    final behaviorProfile = await _getUserBehaviorProfile(userId);
    behaviorProfile.addResponse(response);

    await _saveUserBehaviorProfile(behaviorProfile);
    _behaviorCache[userId] = behaviorProfile; // Update cache
  }

  Future<void> _saveUserBehaviorProfile(UserBehaviorProfile profile) async {
    try {
      await _firestoreService.setDocument(
        'user_behavior',
        profile.userId,
        profile.toJson(),
      );
    } catch (e) {
      debugPrint('Error saving user behavior profile: $e');
    }
  }

  // Helper methods for context gathering
  Future<double> _getBatteryLevel() async {
    // Mock implementation - in real app, use battery_plus package
    return 75.0;
  }

  Future<String> _getNetworkStatus() async {
    // Mock implementation - in real app, use connectivity_plus
    return 'wifi';
  }

  Future<int> _getAppUsageToday(String userId) async {
    // Mock implementation - track app opens/time spent
    return 15; // minutes
  }

  Future<NotificationResponse?> _getLastNotificationResponse(
      String userId) async {
    try {
      final docs = await _firestoreService.getCollectionWithQuery(
        'notification_responses',
        'userId',
        userId,
      );

      if (docs.isNotEmpty) {
        docs.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
        return NotificationResponse.fromJson(docs.first);
      }
    } catch (e) {
      debugPrint('Error getting last notification response: $e');
    }

    return null;
  }

  Future<List<String>> _getCurrentStreakRisks(String userId) async {
    // This would integrate with streak service
    return [];
  }

  Future<List<String>> _getPendingRoutines(String userId) async {
    // This would integrate with routine service
    return [];
  }

  Future<bool> _isInDoNotDisturbPeriod(String userId) async {
    // Check user's DND settings
    return false;
  }

  Future<bool> _hasNotificationFatigue(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final docs = await _firestoreService.getCollectionWithQuery(
        'notifications',
        'userId',
        userId,
      );

      final todayNotifications = docs.where((doc) {
        final createdAt = DateTime.fromMillisecondsSinceEpoch(doc['createdAt']);
        return createdAt.isAfter(startOfDay);
      }).length;

      return todayNotifications >= 5; // Max 5 notifications per day
    } catch (e) {
      debugPrint('Error checking notification fatigue: $e');
      return false;
    }
  }
}

// Supporting classes
class UserBehaviorProfile {
  final String userId;
  final Map<int, double> hourlySuccessRates; // Hour -> Success rate
  final Map<int, double> dailySuccessRates; // Day of week -> Success rate
  final List<int> personalOptimalHours;
  final List<int> lowResponseHours;
  final List<int> successfulNotificationHours;
  final DateTime lastUpdated;
  final int totalNotifications;
  final int totalResponses;

  UserBehaviorProfile({
    required this.userId,
    required this.hourlySuccessRates,
    required this.dailySuccessRates,
    required this.personalOptimalHours,
    required this.lowResponseHours,
    required this.successfulNotificationHours,
    required this.lastUpdated,
    required this.totalNotifications,
    required this.totalResponses,
  });

  factory UserBehaviorProfile.createDefault(String userId) {
    return UserBehaviorProfile(
      userId: userId,
      hourlySuccessRates: {for (int i = 0; i < 24; i++) i: 0.5},
      dailySuccessRates: {for (int i = 1; i <= 7; i++) i: 0.5},
      personalOptimalHours: [9, 12, 18],
      lowResponseHours: [0, 1, 2, 3, 4, 5, 23],
      successfulNotificationHours: [9, 12, 18],
      lastUpdated: DateTime.now(),
      totalNotifications: 0,
      totalResponses: 0,
    );
  }

  double getSuccessRateForHour(int hour) {
    return hourlySuccessRates[hour] ?? 0.5;
  }

  double getSuccessRateForDay(int dayOfWeek) {
    return dailySuccessRates[dayOfWeek] ?? 0.5;
  }

  void addResponse(NotificationResponse response) {
    final hour = response.timestamp.hour;
    final dayOfWeek = response.timestamp.weekday;

    // Update hourly success rate
    final currentHourlyRate = hourlySuccessRates[hour] ?? 0.5;
    final newHourlyRate = response.wasSuccessful
        ? (currentHourlyRate * 0.9) + 0.1
        : (currentHourlyRate * 0.9);
    hourlySuccessRates[hour] = newHourlyRate.clamp(0.0, 1.0);

    // Update daily success rate
    final currentDailyRate = dailySuccessRates[dayOfWeek] ?? 0.5;
    final newDailyRate = response.wasSuccessful
        ? (currentDailyRate * 0.9) + 0.1
        : (currentDailyRate * 0.9);
    dailySuccessRates[dayOfWeek] = newDailyRate.clamp(0.0, 1.0);

    // Update optimal hours
    if (response.wasSuccessful && !personalOptimalHours.contains(hour)) {
      personalOptimalHours.add(hour);
      personalOptimalHours.sort();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'hourlySuccessRates': hourlySuccessRates,
      'dailySuccessRates': dailySuccessRates,
      'personalOptimalHours': personalOptimalHours,
      'lowResponseHours': lowResponseHours,
      'successfulNotificationHours': successfulNotificationHours,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'totalNotifications': totalNotifications,
      'totalResponses': totalResponses,
    };
  }

  factory UserBehaviorProfile.fromJson(Map<String, dynamic> json) {
    return UserBehaviorProfile(
      userId: json['userId'],
      hourlySuccessRates: Map<int, double>.from(json['hourlySuccessRates']
              ?.map((k, v) => MapEntry(int.parse(k), v.toDouble())) ??
          {}),
      dailySuccessRates: Map<int, double>.from(json['dailySuccessRates']
              ?.map((k, v) => MapEntry(int.parse(k), v.toDouble())) ??
          {}),
      personalOptimalHours: List<int>.from(json['personalOptimalHours'] ?? []),
      lowResponseHours: List<int>.from(json['lowResponseHours'] ?? []),
      successfulNotificationHours:
          List<int>.from(json['successfulNotificationHours'] ?? []),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated']),
      totalNotifications: json['totalNotifications'] ?? 0,
      totalResponses: json['totalResponses'] ?? 0,
    );
  }
}

class SchedulingPattern {
  final String id;
  final String name;
  final List<int> optimalHours;
  final List<int> preferredDays;
  final List<String> contextFactors;
  final double successRate;

  const SchedulingPattern({
    required this.id,
    required this.name,
    required this.optimalHours,
    required this.preferredDays,
    required this.contextFactors,
    required this.successRate,
  });
}

class NotificationContext {
  final String userId;
  final DateTime timestamp;
  final int dayOfWeek;
  final TimeOfDay timeOfDay;
  final bool isWeekend;
  final double batteryLevel;
  final String networkStatus;
  final int appUsageToday;
  final NotificationResponse? lastNotificationResponse;
  final List<String> currentStreakRisks;
  final List<String> pendingRoutines;

  const NotificationContext({
    required this.userId,
    required this.timestamp,
    required this.dayOfWeek,
    required this.timeOfDay,
    required this.isWeekend,
    required this.batteryLevel,
    required this.networkStatus,
    required this.appUsageToday,
    this.lastNotificationResponse,
    required this.currentStreakRisks,
    required this.pendingRoutines,
  });
}

class NotificationResponse {
  final String notificationId;
  final String userId;
  final DateTime timestamp;
  final String action; // 'opened', 'dismissed', 'snoozed', 'ignored'
  final Duration? responseTime;
  final bool wasSuccessful;

  const NotificationResponse({
    required this.notificationId,
    required this.userId,
    required this.timestamp,
    required this.action,
    this.responseTime,
    required this.wasSuccessful,
  });

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'action': action,
      'responseTime': responseTime?.inMilliseconds,
      'wasSuccessful': wasSuccessful,
    };
  }

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      notificationId: json['notificationId'],
      userId: json['userId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      action: json['action'],
      responseTime: json['responseTime'] != null
          ? Duration(milliseconds: json['responseTime'])
          : null,
      wasSuccessful: json['wasSuccessful'],
    );
  }
}

class SchedulingDecision {
  final String notificationId;
  final DateTime originalTime;
  final DateTime optimizedTime;
  final String userId;
  final DateTime timestamp;
  final String reasoning;

  const SchedulingDecision({
    required this.notificationId,
    required this.originalTime,
    required this.optimizedTime,
    required this.userId,
    required this.timestamp,
    required this.reasoning,
  });

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'originalTime': originalTime.millisecondsSinceEpoch,
      'optimizedTime': optimizedTime.millisecondsSinceEpoch,
      'userId': userId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'reasoning': reasoning,
    };
  }
}
