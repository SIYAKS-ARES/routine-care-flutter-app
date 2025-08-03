import 'package:flutter/material.dart';
import 'dart:math' as math;

enum StreakType {
  overall, // Genel aktivite streaki
  routine, // Belirli rutin streaki
  category, // Kategori bazlı streak
  daily, // Günlük tamamlama streaki
  perfect, // Mükemmel gün streaki (tüm rutinler)
}

enum StreakStatus {
  active, // Aktif streak
  broken, // Kırılmış streak
  paused, // Duraklatılmış streak
  recovering, // Toparlanma modunda
}

enum StreakMilestone {
  day3(3, '🔥', 'İlk Adım', 'Harika başlangıç!'),
  day7(7, '🔥🔥', 'Haftalık Kahraman', 'Bir hafta boyunca harikasın!'),
  day14(14, '🔥🔥🔥', 'İki Hafta Ustası', 'Kararlılığın takdire şayan!'),
  day30(30, '🔥🔥🔥🔥', 'Aylık Efsane', 'Bu bir alışkanlık artık!'),
  day50(50, '🔥🔥🔥🔥🔥', 'Süper Seri', 'Efsane seviyedesin!'),
  day100(100, '🏆🔥🏆', 'Yüzlük Şampiyon', 'İnanılmaz kararlılık!'),
  day200(200, '💎🔥💎', 'Elit Seviye', 'Sen bir efsanesin!'),
  day365(365, '👑🔥👑', 'Yıllık Kral', 'Tam bir alışkanlık ustası!');

  const StreakMilestone(this.days, this.emoji, this.title, this.description);

  final int days;
  final String emoji;
  final String title;
  final String description;

  static StreakMilestone? getNextMilestone(int currentStreak) {
    for (final milestone in StreakMilestone.values) {
      if (currentStreak < milestone.days) {
        return milestone;
      }
    }
    return null; // Tüm milestones geçilmiş
  }

  static StreakMilestone? getCurrentMilestone(int currentStreak) {
    StreakMilestone? current;
    for (final milestone in StreakMilestone.values) {
      if (currentStreak >= milestone.days) {
        current = milestone;
      } else {
        break;
      }
    }
    return current;
  }

  static List<StreakMilestone> getAchievedMilestones(int currentStreak) {
    return StreakMilestone.values
        .where((milestone) => currentStreak >= milestone.days)
        .toList();
  }

  Color get color {
    switch (this) {
      case StreakMilestone.day3:
        return Colors.orange;
      case StreakMilestone.day7:
        return Colors.red;
      case StreakMilestone.day14:
        return Colors.purple;
      case StreakMilestone.day30:
        return Colors.blue;
      case StreakMilestone.day50:
        return Colors.indigo;
      case StreakMilestone.day100:
        return Colors.amber;
      case StreakMilestone.day200:
        return Colors.cyan;
      case StreakMilestone.day365:
        return Colors.pink;
    }
  }
}

class StreakModel {
  final String id;
  final StreakType type;
  final String? routineId;
  final String? categoryId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletionDate;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final StreakStatus status;
  final Map<String, dynamic> metadata;

  // Streak korunma özellikleri
  final bool allowWeekendBreaks;
  final bool allowOneSkipPerWeek;
  final int maxAllowedSkips;
  final int currentSkips;

  const StreakModel({
    required this.id,
    required this.type,
    this.routineId,
    this.categoryId,
    required this.currentStreak,
    required this.longestStreak,
    this.lastCompletionDate,
    required this.createdAt,
    required this.lastUpdated,
    this.status = StreakStatus.active,
    this.metadata = const {},
    this.allowWeekendBreaks = false,
    this.allowOneSkipPerWeek = false,
    this.maxAllowedSkips = 0,
    this.currentSkips = 0,
  });

  // Streak durumu kontrolleri
  bool get isActive => status == StreakStatus.active && currentStreak > 0;
  bool get isBroken => status == StreakStatus.broken;
  bool get canRecover =>
      status == StreakStatus.broken &&
      lastCompletionDate != null &&
      DateTime.now().difference(lastCompletionDate!).inDays <= 2;

  // Streak milestone kontrolleri
  StreakMilestone? get currentMilestone =>
      StreakMilestone.getCurrentMilestone(currentStreak);
  StreakMilestone? get nextMilestone =>
      StreakMilestone.getNextMilestone(currentStreak);
  List<StreakMilestone> get achievedMilestones =>
      StreakMilestone.getAchievedMilestones(currentStreak);

  // Bugün tamamlanmış mı?
  bool get isCompletedToday {
    if (lastCompletionDate == null) return false;
    final today = DateTime.now();
    final lastCompletion = lastCompletionDate!;
    return today.year == lastCompletion.year &&
        today.month == lastCompletion.month &&
        today.day == lastCompletion.day;
  }

  // Streak devam etmesi için kalan gün sayısı
  int get daysUntilBreak {
    if (lastCompletionDate == null) return 0;
    final daysSinceLastCompletion =
        DateTime.now().difference(lastCompletionDate!).inDays;
    return math.max(0, 1 - daysSinceLastCompletion);
  }

  // Risk seviyesi (0.0 = güvenli, 1.0 = büyük risk)
  double get riskLevel {
    if (isCompletedToday) return 0.0;
    final daysSince =
        DateTime.now().difference(lastCompletionDate ?? DateTime.now()).inDays;
    return (daysSince / 2.0).clamp(0.0, 1.0);
  }

  // Streak progress to next milestone (0.0 - 1.0)
  double get progressToNextMilestone {
    final next = nextMilestone;
    if (next == null) return 1.0;

    final previous = StreakMilestone.getCurrentMilestone(currentStreak);
    final previousDays = previous?.days ?? 0;
    final nextDays = next.days;

    if (nextDays <= previousDays) return 1.0;

    return (currentStreak - previousDays) / (nextDays - previousDays);
  }

  StreakModel copyWith({
    String? id,
    StreakType? type,
    String? routineId,
    String? categoryId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletionDate,
    DateTime? createdAt,
    DateTime? lastUpdated,
    StreakStatus? status,
    Map<String, dynamic>? metadata,
    bool? allowWeekendBreaks,
    bool? allowOneSkipPerWeek,
    int? maxAllowedSkips,
    int? currentSkips,
  }) {
    return StreakModel(
      id: id ?? this.id,
      type: type ?? this.type,
      routineId: routineId ?? this.routineId,
      categoryId: categoryId ?? this.categoryId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      allowWeekendBreaks: allowWeekendBreaks ?? this.allowWeekendBreaks,
      allowOneSkipPerWeek: allowOneSkipPerWeek ?? this.allowOneSkipPerWeek,
      maxAllowedSkips: maxAllowedSkips ?? this.maxAllowedSkips,
      currentSkips: currentSkips ?? this.currentSkips,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'routineId': routineId,
        'categoryId': categoryId,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastCompletionDate': lastCompletionDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'lastUpdated': lastUpdated.toIso8601String(),
        'status': status.name,
        'metadata': metadata,
        'allowWeekendBreaks': allowWeekendBreaks,
        'allowOneSkipPerWeek': allowOneSkipPerWeek,
        'maxAllowedSkips': maxAllowedSkips,
        'currentSkips': currentSkips,
      };

  factory StreakModel.fromJson(Map<String, dynamic> json) => StreakModel(
        id: json['id'],
        type: StreakType.values.firstWhere((e) => e.name == json['type']),
        routineId: json['routineId'],
        categoryId: json['categoryId'],
        currentStreak: json['currentStreak'],
        longestStreak: json['longestStreak'],
        lastCompletionDate: json['lastCompletionDate'] != null
            ? DateTime.parse(json['lastCompletionDate'])
            : null,
        createdAt: DateTime.parse(json['createdAt']),
        lastUpdated: DateTime.parse(json['lastUpdated']),
        status: StreakStatus.values.firstWhere((e) => e.name == json['status']),
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
        allowWeekendBreaks: json['allowWeekendBreaks'] ?? false,
        allowOneSkipPerWeek: json['allowOneSkipPerWeek'] ?? false,
        maxAllowedSkips: json['maxAllowedSkips'] ?? 0,
        currentSkips: json['currentSkips'] ?? 0,
      );

  @override
  String toString() =>
      'StreakModel(id: $id, type: $type, currentStreak: $currentStreak, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Streak istatistikleri
class StreakStatistics {
  final int totalStreaks;
  final int activeStreaks;
  final int brokenStreaks;
  final int longestOverallStreak;
  final int currentOverallStreak;
  final Map<StreakType, int> streaksByType;
  final Map<StreakMilestone, int> milestonesAchieved;
  final DateTime? lastStreakDate;
  final double averageStreakLength;
  final int totalDaysWithStreaks;
  final DateTime calculatedAt;

  const StreakStatistics({
    required this.totalStreaks,
    required this.activeStreaks,
    required this.brokenStreaks,
    required this.longestOverallStreak,
    required this.currentOverallStreak,
    required this.streaksByType,
    required this.milestonesAchieved,
    this.lastStreakDate,
    required this.averageStreakLength,
    required this.totalDaysWithStreaks,
    required this.calculatedAt,
  });

  double get streakConsistency =>
      totalStreaks > 0 ? activeStreaks / totalStreaks : 0.0;
  double get milestonePower =>
      milestonesAchieved.length / StreakMilestone.values.length;

  Map<String, dynamic> toJson() => {
        'totalStreaks': totalStreaks,
        'activeStreaks': activeStreaks,
        'brokenStreaks': brokenStreaks,
        'longestOverallStreak': longestOverallStreak,
        'currentOverallStreak': currentOverallStreak,
        'streaksByType': streaksByType.map((k, v) => MapEntry(k.name, v)),
        'milestonesAchieved':
            milestonesAchieved.map((k, v) => MapEntry(k.name, v)),
        'lastStreakDate': lastStreakDate?.toIso8601String(),
        'averageStreakLength': averageStreakLength,
        'totalDaysWithStreaks': totalDaysWithStreaks,
        'calculatedAt': calculatedAt.toIso8601String(),
      };

  factory StreakStatistics.fromJson(Map<String, dynamic> json) =>
      StreakStatistics(
        totalStreaks: json['totalStreaks'],
        activeStreaks: json['activeStreaks'],
        brokenStreaks: json['brokenStreaks'],
        longestOverallStreak: json['longestOverallStreak'],
        currentOverallStreak: json['currentOverallStreak'],
        streaksByType: Map<StreakType, int>.from((json['streaksByType'] as Map)
            .map((k, v) =>
                MapEntry(StreakType.values.firstWhere((e) => e.name == k), v))),
        milestonesAchieved: Map<StreakMilestone, int>.from(
            (json['milestonesAchieved'] as Map).map((k, v) => MapEntry(
                StreakMilestone.values.firstWhere((e) => e.name == k), v))),
        lastStreakDate: json['lastStreakDate'] != null
            ? DateTime.parse(json['lastStreakDate'])
            : null,
        averageStreakLength: json['averageStreakLength'].toDouble(),
        totalDaysWithStreaks: json['totalDaysWithStreaks'],
        calculatedAt: DateTime.parse(json['calculatedAt']),
      );
}

// Streak event for tracking changes
class StreakEvent {
  final String streakId;
  final StreakEventType type;
  final int oldValue;
  final int newValue;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const StreakEvent({
    required this.streakId,
    required this.type,
    required this.oldValue,
    required this.newValue,
    required this.timestamp,
    this.data = const {},
  });

  Map<String, dynamic> toJson() => {
        'streakId': streakId,
        'type': type.name,
        'oldValue': oldValue,
        'newValue': newValue,
        'timestamp': timestamp.toIso8601String(),
        'data': data,
      };

  factory StreakEvent.fromJson(Map<String, dynamic> json) => StreakEvent(
        streakId: json['streakId'],
        type: StreakEventType.values.firstWhere((e) => e.name == json['type']),
        oldValue: json['oldValue'],
        newValue: json['newValue'],
        timestamp: DateTime.parse(json['timestamp']),
        data: Map<String, dynamic>.from(json['data'] ?? {}),
      );
}

enum StreakEventType {
  increased, // Streak artırıldı
  broken, // Streak kırıldı
  recovered, // Streak kurtarıldı
  milestone, // Milestone ulaşıldı
  reset, // Streak sıfırlandı
}
