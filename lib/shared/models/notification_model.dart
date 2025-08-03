import 'package:flutter/material.dart';

enum NotificationType {
  routineReminder, // Rutin hatırlatıcısı
  streakWarning, // Streak uyarısı
  streakMilestone, // Streak milestone kutlaması
  motivational, // Motivasyonel mesajlar
  achievement, // Başarı bildirimleri
  dailySummary, // Günlük özet
  weeklyReport, // Haftalık rapor
  custom, // Özel bildirimler
}

enum NotificationPriority {
  low, // Düşük - sessiz
  normal, // Normal - standart
  high, // Yüksek - önemli
  urgent, // Acil - streak kırılma riski
}

enum ReminderFrequency {
  once, // Tek seferlik
  daily, // Günlük
  weekly, // Haftalık
  biWeekly, // İki haftada bir
  monthly, // Aylık
  custom, // Özel aralık
}

enum NotificationTone {
  gentle, // Nazik ton
  motivational, // Motivasyonel ton
  urgent, // Acil ton
  celebratory, // Kutlama tonu
  friendly, // Arkadaşça ton
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime scheduledTime;
  final NotificationPriority priority;
  final String? imageUrl;
  final String? actionUrl;
  final bool isRead;
  final bool isDelivered;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? userId;
  final String? routineId;
  final String? streakId;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    required this.scheduledTime,
    this.priority = NotificationPriority.normal,
    this.imageUrl,
    this.actionUrl,
    this.isRead = false,
    this.isDelivered = false,
    required this.createdAt,
    this.deliveredAt,
    this.readAt,
    this.userId,
    this.routineId,
    this.streakId,
  });

  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? scheduledTime,
    NotificationPriority? priority,
    String? imageUrl,
    String? actionUrl,
    bool? isRead,
    bool? isDelivered,
    DateTime? createdAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    String? userId,
    String? routineId,
    String? streakId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      priority: priority ?? this.priority,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      userId: userId ?? this.userId,
      routineId: routineId ?? this.routineId,
      streakId: streakId ?? this.streakId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'body': body,
      'data': data,
      'scheduledTime': scheduledTime.millisecondsSinceEpoch,
      'priority': priority.name,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'isRead': isRead,
      'isDelivered': isDelivered,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
      'readAt': readAt?.millisecondsSinceEpoch,
      'userId': userId,
      'routineId': routineId,
      'streakId': streakId,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.custom,
      ),
      title: json['title'] as String,
      body: json['body'] as String,
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(json['scheduledTime']),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      imageUrl: json['imageUrl'] as String?,
      actionUrl: json['actionUrl'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      isDelivered: json['isDelivered'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['deliveredAt'])
          : null,
      readAt: json['readAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['readAt'])
          : null,
      userId: json['userId'] as String?,
      routineId: json['routineId'] as String?,
      streakId: json['streakId'] as String?,
    );
  }

  // Utility getters
  bool get isOverdue => scheduledTime.isBefore(DateTime.now()) && !isDelivered;
  bool get isPending => scheduledTime.isAfter(DateTime.now()) && !isDelivered;
  bool get isActive => !isRead && isDelivered;

  Duration get timeUntilScheduled => scheduledTime.difference(DateTime.now());
  Duration? get timeSinceDelivered =>
      deliveredAt?.let((d) => DateTime.now().difference(d));

  String get typeDisplayName {
    switch (type) {
      case NotificationType.routineReminder:
        return 'Rutin Hatırlatıcısı';
      case NotificationType.streakWarning:
        return 'Seri Uyarısı';
      case NotificationType.streakMilestone:
        return 'Seri Başarısı';
      case NotificationType.motivational:
        return 'Motivasyon';
      case NotificationType.achievement:
        return 'Başarı';
      case NotificationType.dailySummary:
        return 'Günlük Özet';
      case NotificationType.weeklyReport:
        return 'Haftalık Rapor';
      case NotificationType.custom:
        return 'Özel';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case NotificationType.routineReminder:
        return Icons.schedule;
      case NotificationType.streakWarning:
        return Icons.warning;
      case NotificationType.streakMilestone:
        return Icons.local_fire_department;
      case NotificationType.motivational:
        return Icons.favorite;
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.dailySummary:
        return Icons.today;
      case NotificationType.weeklyReport:
        return Icons.insights;
      case NotificationType.custom:
        return Icons.notifications;
    }
  }

  Color get typeColor {
    switch (type) {
      case NotificationType.routineReminder:
        return Colors.blue;
      case NotificationType.streakWarning:
        return Colors.orange;
      case NotificationType.streakMilestone:
        return Colors.amber;
      case NotificationType.motivational:
        return Colors.pink;
      case NotificationType.achievement:
        return Colors.green;
      case NotificationType.dailySummary:
        return Colors.indigo;
      case NotificationType.weeklyReport:
        return Colors.purple;
      case NotificationType.custom:
        return Colors.grey;
    }
  }
}

class ReminderSchedule {
  final String id;
  final String name;
  final NotificationType type;
  final ReminderFrequency frequency;
  final TimeOfDay time;
  final List<int> daysOfWeek; // 1-7 (Monday-Sunday)
  final bool isEnabled;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? customIntervalDays;
  final String? routineId;
  final Map<String, dynamic> settings;

  const ReminderSchedule({
    required this.id,
    required this.name,
    required this.type,
    required this.frequency,
    required this.time,
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7], // All days by default
    this.isEnabled = true,
    this.startDate,
    this.endDate,
    this.customIntervalDays,
    this.routineId,
    this.settings = const {},
  });

  ReminderSchedule copyWith({
    String? id,
    String? name,
    NotificationType? type,
    ReminderFrequency? frequency,
    TimeOfDay? time,
    List<int>? daysOfWeek,
    bool? isEnabled,
    DateTime? startDate,
    DateTime? endDate,
    int? customIntervalDays,
    String? routineId,
    Map<String, dynamic>? settings,
  }) {
    return ReminderSchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      time: time ?? this.time,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isEnabled: isEnabled ?? this.isEnabled,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      customIntervalDays: customIntervalDays ?? this.customIntervalDays,
      routineId: routineId ?? this.routineId,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'frequency': frequency.name,
      'time': {'hour': time.hour, 'minute': time.minute},
      'daysOfWeek': daysOfWeek,
      'isEnabled': isEnabled,
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'customIntervalDays': customIntervalDays,
      'routineId': routineId,
      'settings': settings,
    };
  }

  factory ReminderSchedule.fromJson(Map<String, dynamic> json) {
    final timeData = json['time'] as Map<String, dynamic>;

    return ReminderSchedule(
      id: json['id'] as String,
      name: json['name'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.routineReminder,
      ),
      frequency: ReminderFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => ReminderFrequency.daily,
      ),
      time: TimeOfDay(
        hour: timeData['hour'] as int,
        minute: timeData['minute'] as int,
      ),
      daysOfWeek: List<int>.from(json['daysOfWeek'] ?? [1, 2, 3, 4, 5, 6, 7]),
      isEnabled: json['isEnabled'] as bool? ?? true,
      startDate: json['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['endDate'])
          : null,
      customIntervalDays: json['customIntervalDays'] as int?,
      routineId: json['routineId'] as String?,
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }

  // Calculate next scheduled notification time
  DateTime? get nextScheduledTime {
    final now = DateTime.now();
    final todayAtTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);

    switch (frequency) {
      case ReminderFrequency.once:
        return todayAtTime.isAfter(now) ? todayAtTime : null;

      case ReminderFrequency.daily:
        if (daysOfWeek.contains(now.weekday)) {
          if (todayAtTime.isAfter(now)) {
            return todayAtTime;
          }
        }
        // Find next valid day
        for (int i = 1; i <= 7; i++) {
          final nextDay = now.add(Duration(days: i));
          if (daysOfWeek.contains(nextDay.weekday)) {
            return DateTime(nextDay.year, nextDay.month, nextDay.day, time.hour,
                time.minute);
          }
        }
        return null;

      case ReminderFrequency.weekly:
        final nextWeek = now.add(const Duration(days: 7));
        return DateTime(nextWeek.year, nextWeek.month, nextWeek.day, time.hour,
            time.minute);

      case ReminderFrequency.biWeekly:
        final nextBiWeek = now.add(const Duration(days: 14));
        return DateTime(nextBiWeek.year, nextBiWeek.month, nextBiWeek.day,
            time.hour, time.minute);

      case ReminderFrequency.monthly:
        final nextMonth =
            DateTime(now.year, now.month + 1, now.day, time.hour, time.minute);
        return nextMonth;

      case ReminderFrequency.custom:
        if (customIntervalDays != null) {
          final nextCustom = now.add(Duration(days: customIntervalDays!));
          return DateTime(nextCustom.year, nextCustom.month, nextCustom.day,
              time.hour, time.minute);
        }
        return null;
    }
  }

  bool get isActiveToday {
    if (!isEnabled) return false;

    final now = DateTime.now();

    // Check if today is a valid day
    if (!daysOfWeek.contains(now.weekday)) return false;

    // Check date range
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;

    return true;
  }

  String get frequencyDisplayName {
    switch (frequency) {
      case ReminderFrequency.once:
        return 'Tek Seferlik';
      case ReminderFrequency.daily:
        return 'Günlük';
      case ReminderFrequency.weekly:
        return 'Haftalık';
      case ReminderFrequency.biWeekly:
        return 'İki Haftada Bir';
      case ReminderFrequency.monthly:
        return 'Aylık';
      case ReminderFrequency.custom:
        return customIntervalDays != null
            ? '$customIntervalDays Günde Bir'
            : 'Özel';
    }
  }

  String get timeDisplayName {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<String> get daysDisplayNames {
    const dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return daysOfWeek.map((day) => dayNames[day - 1]).toList();
  }
}

class NotificationPreferences {
  final String userId;
  final bool notificationsEnabled;
  final bool routineRemindersEnabled;
  final bool streakWarningsEnabled;
  final bool achievementNotificationsEnabled;
  final bool motivationalMessagesEnabled;
  final bool dailySummaryEnabled;
  final bool weeklyReportEnabled;

  // Do Not Disturb settings
  final bool doNotDisturbEnabled;
  final TimeOfDay? doNotDisturbStart;
  final TimeOfDay? doNotDisturbEnd;
  final List<int> doNotDisturbDays;

  // Sound and vibration
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String? customSoundPath;

  // Smart features
  final bool smartTimingEnabled;
  final bool contextAwareEnabled;
  final int maxDailyNotifications;
  final NotificationTone preferredTone;

  // Snooze settings
  final bool snoozeEnabled;
  final int snoozeMinutes;
  final int maxSnoozeCount;

  const NotificationPreferences({
    required this.userId,
    this.notificationsEnabled = true,
    this.routineRemindersEnabled = true,
    this.streakWarningsEnabled = true,
    this.achievementNotificationsEnabled = true,
    this.motivationalMessagesEnabled = true,
    this.dailySummaryEnabled = false,
    this.weeklyReportEnabled = true,
    this.doNotDisturbEnabled = false,
    this.doNotDisturbStart,
    this.doNotDisturbEnd,
    this.doNotDisturbDays = const [],
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.customSoundPath,
    this.smartTimingEnabled = true,
    this.contextAwareEnabled = true,
    this.maxDailyNotifications = 5,
    this.preferredTone = NotificationTone.gentle,
    this.snoozeEnabled = true,
    this.snoozeMinutes = 10,
    this.maxSnoozeCount = 3,
  });

  NotificationPreferences copyWith({
    String? userId,
    bool? notificationsEnabled,
    bool? routineRemindersEnabled,
    bool? streakWarningsEnabled,
    bool? achievementNotificationsEnabled,
    bool? motivationalMessagesEnabled,
    bool? dailySummaryEnabled,
    bool? weeklyReportEnabled,
    bool? doNotDisturbEnabled,
    TimeOfDay? doNotDisturbStart,
    TimeOfDay? doNotDisturbEnd,
    List<int>? doNotDisturbDays,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? customSoundPath,
    bool? smartTimingEnabled,
    bool? contextAwareEnabled,
    int? maxDailyNotifications,
    NotificationTone? preferredTone,
    bool? snoozeEnabled,
    int? snoozeMinutes,
    int? maxSnoozeCount,
  }) {
    return NotificationPreferences(
      userId: userId ?? this.userId,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      routineRemindersEnabled:
          routineRemindersEnabled ?? this.routineRemindersEnabled,
      streakWarningsEnabled:
          streakWarningsEnabled ?? this.streakWarningsEnabled,
      achievementNotificationsEnabled: achievementNotificationsEnabled ??
          this.achievementNotificationsEnabled,
      motivationalMessagesEnabled:
          motivationalMessagesEnabled ?? this.motivationalMessagesEnabled,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      weeklyReportEnabled: weeklyReportEnabled ?? this.weeklyReportEnabled,
      doNotDisturbEnabled: doNotDisturbEnabled ?? this.doNotDisturbEnabled,
      doNotDisturbStart: doNotDisturbStart ?? this.doNotDisturbStart,
      doNotDisturbEnd: doNotDisturbEnd ?? this.doNotDisturbEnd,
      doNotDisturbDays: doNotDisturbDays ?? this.doNotDisturbDays,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      customSoundPath: customSoundPath ?? this.customSoundPath,
      smartTimingEnabled: smartTimingEnabled ?? this.smartTimingEnabled,
      contextAwareEnabled: contextAwareEnabled ?? this.contextAwareEnabled,
      maxDailyNotifications:
          maxDailyNotifications ?? this.maxDailyNotifications,
      preferredTone: preferredTone ?? this.preferredTone,
      snoozeEnabled: snoozeEnabled ?? this.snoozeEnabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      maxSnoozeCount: maxSnoozeCount ?? this.maxSnoozeCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'notificationsEnabled': notificationsEnabled,
      'routineRemindersEnabled': routineRemindersEnabled,
      'streakWarningsEnabled': streakWarningsEnabled,
      'achievementNotificationsEnabled': achievementNotificationsEnabled,
      'motivationalMessagesEnabled': motivationalMessagesEnabled,
      'dailySummaryEnabled': dailySummaryEnabled,
      'weeklyReportEnabled': weeklyReportEnabled,
      'doNotDisturbEnabled': doNotDisturbEnabled,
      'doNotDisturbStart': doNotDisturbStart != null
          ? {
              'hour': doNotDisturbStart!.hour,
              'minute': doNotDisturbStart!.minute
            }
          : null,
      'doNotDisturbEnd': doNotDisturbEnd != null
          ? {'hour': doNotDisturbEnd!.hour, 'minute': doNotDisturbEnd!.minute}
          : null,
      'doNotDisturbDays': doNotDisturbDays,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'customSoundPath': customSoundPath,
      'smartTimingEnabled': smartTimingEnabled,
      'contextAwareEnabled': contextAwareEnabled,
      'maxDailyNotifications': maxDailyNotifications,
      'preferredTone': preferredTone.name,
      'snoozeEnabled': snoozeEnabled,
      'snoozeMinutes': snoozeMinutes,
      'maxSnoozeCount': maxSnoozeCount,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTimeOfDay(Map<String, dynamic>? timeData) {
      if (timeData == null) return null;
      return TimeOfDay(
        hour: timeData['hour'] as int,
        minute: timeData['minute'] as int,
      );
    }

    return NotificationPreferences(
      userId: json['userId'] as String,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      routineRemindersEnabled: json['routineRemindersEnabled'] as bool? ?? true,
      streakWarningsEnabled: json['streakWarningsEnabled'] as bool? ?? true,
      achievementNotificationsEnabled:
          json['achievementNotificationsEnabled'] as bool? ?? true,
      motivationalMessagesEnabled:
          json['motivationalMessagesEnabled'] as bool? ?? true,
      dailySummaryEnabled: json['dailySummaryEnabled'] as bool? ?? false,
      weeklyReportEnabled: json['weeklyReportEnabled'] as bool? ?? true,
      doNotDisturbEnabled: json['doNotDisturbEnabled'] as bool? ?? false,
      doNotDisturbStart: parseTimeOfDay(json['doNotDisturbStart']),
      doNotDisturbEnd: parseTimeOfDay(json['doNotDisturbEnd']),
      doNotDisturbDays: List<int>.from(json['doNotDisturbDays'] ?? []),
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      customSoundPath: json['customSoundPath'] as String?,
      smartTimingEnabled: json['smartTimingEnabled'] as bool? ?? true,
      contextAwareEnabled: json['contextAwareEnabled'] as bool? ?? true,
      maxDailyNotifications: json['maxDailyNotifications'] as int? ?? 5,
      preferredTone: NotificationTone.values.firstWhere(
        (e) => e.name == json['preferredTone'],
        orElse: () => NotificationTone.gentle,
      ),
      snoozeEnabled: json['snoozeEnabled'] as bool? ?? true,
      snoozeMinutes: json['snoozeMinutes'] as int? ?? 10,
      maxSnoozeCount: json['maxSnoozeCount'] as int? ?? 3,
    );
  }

  // Check if notifications should be shown during DND period
  bool get isInDoNotDisturbPeriod {
    if (!doNotDisturbEnabled ||
        doNotDisturbStart == null ||
        doNotDisturbEnd == null) {
      return false;
    }

    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    final currentWeekday = now.weekday;

    // Check if today is a DND day
    if (doNotDisturbDays.isNotEmpty &&
        !doNotDisturbDays.contains(currentWeekday)) {
      return false;
    }

    // Compare times
    final startMinutes =
        doNotDisturbStart!.hour * 60 + doNotDisturbStart!.minute;
    final endMinutes = doNotDisturbEnd!.hour * 60 + doNotDisturbEnd!.minute;
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;

    if (startMinutes <= endMinutes) {
      // Same day period (e.g., 10:00 - 18:00)
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Overnight period (e.g., 22:00 - 06:00)
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  bool isNotificationTypeEnabled(NotificationType type) {
    if (!notificationsEnabled) return false;

    switch (type) {
      case NotificationType.routineReminder:
        return routineRemindersEnabled;
      case NotificationType.streakWarning:
        return streakWarningsEnabled;
      case NotificationType.streakMilestone:
      case NotificationType.achievement:
        return achievementNotificationsEnabled;
      case NotificationType.motivational:
        return motivationalMessagesEnabled;
      case NotificationType.dailySummary:
        return dailySummaryEnabled;
      case NotificationType.weeklyReport:
        return weeklyReportEnabled;
      case NotificationType.custom:
        return true; // Always allow custom notifications
    }
  }
}

// Extension to add helper method
extension DurationExtension on DateTime? {
  T? let<T>(T Function(DateTime) fn) => this != null ? fn(this!) : null;
}
