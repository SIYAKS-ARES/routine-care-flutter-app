class UserProgress {
  final int routineCompletions;
  final int goalCompletions;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> categoryCompletions; // categoryId -> completion count
  final int totalTimeSpent; // in minutes
  final int consecutiveDays;
  final bool perfectWeekAchieved;
  final Map<String, dynamic> customData; // for custom achievements
  final DateTime lastUpdated;
  final DateTime createdAt;

  const UserProgress({
    required this.routineCompletions,
    required this.goalCompletions,
    required this.currentStreak,
    required this.longestStreak,
    required this.categoryCompletions,
    required this.totalTimeSpent,
    required this.consecutiveDays,
    required this.perfectWeekAchieved,
    required this.customData,
    required this.lastUpdated,
    required this.createdAt,
  });

  UserProgress copyWith({
    int? routineCompletions,
    int? goalCompletions,
    int? currentStreak,
    int? longestStreak,
    Map<String, int>? categoryCompletions,
    int? totalTimeSpent,
    int? consecutiveDays,
    bool? perfectWeekAchieved,
    Map<String, dynamic>? customData,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return UserProgress(
      routineCompletions: routineCompletions ?? this.routineCompletions,
      goalCompletions: goalCompletions ?? this.goalCompletions,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      categoryCompletions: categoryCompletions ?? this.categoryCompletions,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      perfectWeekAchieved: perfectWeekAchieved ?? this.perfectWeekAchieved,
      customData: customData ?? this.customData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'routineCompletions': routineCompletions,
        'goalCompletions': goalCompletions,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'categoryCompletions': categoryCompletions,
        'totalTimeSpent': totalTimeSpent,
        'consecutiveDays': consecutiveDays,
        'perfectWeekAchieved': perfectWeekAchieved,
        'customData': customData,
        'lastUpdated': lastUpdated.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
        routineCompletions: json['routineCompletions'] ?? 0,
        goalCompletions: json['goalCompletions'] ?? 0,
        currentStreak: json['currentStreak'] ?? 0,
        longestStreak: json['longestStreak'] ?? 0,
        categoryCompletions:
            Map<String, int>.from(json['categoryCompletions'] ?? {}),
        totalTimeSpent: json['totalTimeSpent'] ?? 0,
        consecutiveDays: json['consecutiveDays'] ?? 0,
        perfectWeekAchieved: json['perfectWeekAchieved'] ?? false,
        customData: Map<String, dynamic>.from(json['customData'] ?? {}),
        lastUpdated: DateTime.parse(json['lastUpdated']),
        createdAt: DateTime.parse(json['createdAt']),
      );

  factory UserProgress.initial() {
    final now = DateTime.now();
    return UserProgress(
      routineCompletions: 0,
      goalCompletions: 0,
      currentStreak: 0,
      longestStreak: 0,
      categoryCompletions: {},
      totalTimeSpent: 0,
      consecutiveDays: 0,
      perfectWeekAchieved: false,
      customData: {},
      lastUpdated: now,
      createdAt: now,
    );
  }

  // Helper methods
  int getCategoryCompletions(String categoryId) =>
      categoryCompletions[categoryId] ?? 0;

  UserProgress incrementRoutineCompletions({int count = 1}) {
    return copyWith(
      routineCompletions: routineCompletions + count,
      lastUpdated: DateTime.now(),
    );
  }

  UserProgress incrementGoalCompletions({int count = 1}) {
    return copyWith(
      goalCompletions: goalCompletions + count,
      lastUpdated: DateTime.now(),
    );
  }

  UserProgress updateStreak(int newStreak) {
    return copyWith(
      currentStreak: newStreak,
      longestStreak: newStreak > longestStreak ? newStreak : longestStreak,
      lastUpdated: DateTime.now(),
    );
  }

  UserProgress incrementCategoryCompletions(String categoryId,
      {int count = 1}) {
    final newCompletions = Map<String, int>.from(categoryCompletions);
    newCompletions[categoryId] = (newCompletions[categoryId] ?? 0) + count;

    return copyWith(
      categoryCompletions: newCompletions,
      lastUpdated: DateTime.now(),
    );
  }

  UserProgress addTimeSpent(int minutes) {
    return copyWith(
      totalTimeSpent: totalTimeSpent + minutes,
      lastUpdated: DateTime.now(),
    );
  }

  UserProgress updateConsecutiveDays(int days) {
    return copyWith(
      consecutiveDays: days,
      lastUpdated: DateTime.now(),
    );
  }

  UserProgress markPerfectWeek() {
    return copyWith(
      perfectWeekAchieved: true,
      lastUpdated: DateTime.now(),
    );
  }

  UserProgress updateCustomData(String key, dynamic value) {
    final newCustomData = Map<String, dynamic>.from(customData);
    newCustomData[key] = value;

    return copyWith(
      customData: newCustomData,
      lastUpdated: DateTime.now(),
    );
  }

  // Getters for quick access
  bool get hasCompletedRoutines => routineCompletions > 0;
  bool get hasCompletedGoals => goalCompletions > 0;
  bool get hasStreak => currentStreak > 0;
  bool get hasLongStreak => longestStreak >= 7;
  bool get hasSpentSignificantTime => totalTimeSpent >= 60; // 1 hour

  String get totalTimeFormatted {
    final hours = totalTimeSpent ~/ 60;
    final minutes = totalTimeSpent % 60;

    if (hours > 0) {
      return '${hours}s ${minutes}dk';
    } else {
      return '${minutes}dk';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProgress &&
          runtimeType == other.runtimeType &&
          routineCompletions == other.routineCompletions &&
          goalCompletions == other.goalCompletions &&
          currentStreak == other.currentStreak &&
          longestStreak == other.longestStreak &&
          totalTimeSpent == other.totalTimeSpent &&
          consecutiveDays == other.consecutiveDays &&
          perfectWeekAchieved == other.perfectWeekAchieved;

  @override
  int get hashCode =>
      routineCompletions.hashCode ^
      goalCompletions.hashCode ^
      currentStreak.hashCode ^
      longestStreak.hashCode ^
      totalTimeSpent.hashCode ^
      consecutiveDays.hashCode ^
      perfectWeekAchieved.hashCode;

  @override
  String toString() =>
      'UserProgress(routines: $routineCompletions, goals: $goalCompletions, streak: $currentStreak)';
}
