class GoalStatistics {
  final int totalGoals;
  final int activeGoals;
  final int completedGoals;
  final int pausedGoals;
  final int failedGoals;
  final int expiredGoals;
  final double averageCompletionRate;
  final int totalMilestonesCompleted;
  final DateTime lastUpdated;

  const GoalStatistics({
    required this.totalGoals,
    required this.activeGoals,
    required this.completedGoals,
    required this.pausedGoals,
    required this.failedGoals,
    required this.expiredGoals,
    required this.averageCompletionRate,
    required this.totalMilestonesCompleted,
    required this.lastUpdated,
  });

  GoalStatistics copyWith({
    int? totalGoals,
    int? activeGoals,
    int? completedGoals,
    int? pausedGoals,
    int? failedGoals,
    int? expiredGoals,
    double? averageCompletionRate,
    int? totalMilestonesCompleted,
    DateTime? lastUpdated,
  }) {
    return GoalStatistics(
      totalGoals: totalGoals ?? this.totalGoals,
      activeGoals: activeGoals ?? this.activeGoals,
      completedGoals: completedGoals ?? this.completedGoals,
      pausedGoals: pausedGoals ?? this.pausedGoals,
      failedGoals: failedGoals ?? this.failedGoals,
      expiredGoals: expiredGoals ?? this.expiredGoals,
      averageCompletionRate:
          averageCompletionRate ?? this.averageCompletionRate,
      totalMilestonesCompleted:
          totalMilestonesCompleted ?? this.totalMilestonesCompleted,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalGoals': totalGoals,
        'activeGoals': activeGoals,
        'completedGoals': completedGoals,
        'pausedGoals': pausedGoals,
        'failedGoals': failedGoals,
        'expiredGoals': expiredGoals,
        'averageCompletionRate': averageCompletionRate,
        'totalMilestonesCompleted': totalMilestonesCompleted,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory GoalStatistics.fromJson(Map<String, dynamic> json) => GoalStatistics(
        totalGoals: json['totalGoals'] ?? 0,
        activeGoals: json['activeGoals'] ?? 0,
        completedGoals: json['completedGoals'] ?? 0,
        pausedGoals: json['pausedGoals'] ?? 0,
        failedGoals: json['failedGoals'] ?? 0,
        expiredGoals: json['expiredGoals'] ?? 0,
        averageCompletionRate:
            (json['averageCompletionRate'] ?? 0.0).toDouble(),
        totalMilestonesCompleted: json['totalMilestonesCompleted'] ?? 0,
        lastUpdated: DateTime.parse(json['lastUpdated']),
      );

  factory GoalStatistics.empty() => GoalStatistics(
        totalGoals: 0,
        activeGoals: 0,
        completedGoals: 0,
        pausedGoals: 0,
        failedGoals: 0,
        expiredGoals: 0,
        averageCompletionRate: 0.0,
        totalMilestonesCompleted: 0,
        lastUpdated: DateTime.now(),
      );

  // Helper getters
  double get completionRate {
    if (totalGoals == 0) return 0.0;
    return (completedGoals / totalGoals) * 100;
  }

  double get successRate {
    if (totalGoals == 0) return 0.0;
    return (completedGoals / (completedGoals + failedGoals + expiredGoals)) *
        100;
  }

  int get inProgressGoals => activeGoals + pausedGoals;

  bool get hasGoals => totalGoals > 0;
  bool get hasActiveGoals => activeGoals > 0;
  bool get hasCompletedGoals => completedGoals > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalStatistics &&
          runtimeType == other.runtimeType &&
          totalGoals == other.totalGoals &&
          activeGoals == other.activeGoals &&
          completedGoals == other.completedGoals &&
          pausedGoals == other.pausedGoals &&
          failedGoals == other.failedGoals &&
          expiredGoals == other.expiredGoals &&
          averageCompletionRate == other.averageCompletionRate &&
          totalMilestonesCompleted == other.totalMilestonesCompleted;

  @override
  int get hashCode =>
      totalGoals.hashCode ^
      activeGoals.hashCode ^
      completedGoals.hashCode ^
      pausedGoals.hashCode ^
      failedGoals.hashCode ^
      expiredGoals.hashCode ^
      averageCompletionRate.hashCode ^
      totalMilestonesCompleted.hashCode;

  @override
  String toString() =>
      'GoalStatistics(total: $totalGoals, active: $activeGoals, completed: $completedGoals)';
}
