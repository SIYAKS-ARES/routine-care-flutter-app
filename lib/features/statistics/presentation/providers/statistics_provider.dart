import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../routine_management/data/repositories/routine_repository.dart';
import '../../../../core/di/injection.dart';

// Data Models
class StatisticsData {
  final int totalDays;
  final int activeDays;
  final double averageIntensity;
  final int currentStreak;
  final int longestStreak;
  final double completionRate;

  StatisticsData({
    required this.totalDays,
    required this.activeDays,
    required this.averageIntensity,
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRate,
  });
}

class WeeklyProgress {
  final DateTime weekStart;
  final double completionRate;
  final int completedDays;
  final int totalRoutines;

  WeeklyProgress({
    required this.weekStart,
    required this.completionRate,
    required this.completedDays,
    required this.totalRoutines,
  });
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int progress;
  final int target;
  final AchievementType type;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.isUnlocked,
    this.unlockedAt,
    required this.progress,
    required this.target,
    required this.type,
  });

  double get progressPercentage =>
      target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
}

enum AchievementType {
  streak,
  completion,
  consistency,
  milestone,
}

// Repository provider
final statisticsRepositoryProvider = Provider<RoutineRepository>((ref) {
  return getIt<RoutineRepository>();
});

// Statistics providers
final completionStatsProvider =
    FutureProvider.family<StatisticsData, int>((ref, days) async {
  final repository = ref.watch(statisticsRepositoryProvider);
  final endDate = DateTime.now();
  final startDate = endDate.subtract(Duration(days: days));

  try {
    final heatMapData = await repository.getHeatMapData(startDate, endDate);

    // Calculate statistics
    final totalDays = days;
    final activeDays = heatMapData.keys.length;
    final averageIntensity = heatMapData.isEmpty
        ? 0.0
        : heatMapData.values.reduce((a, b) => a + b) / heatMapData.length;
    final currentStreak = _calculateCurrentStreak(heatMapData, endDate);
    final longestStreak = _calculateLongestStreak(heatMapData);

    return StatisticsData(
      totalDays: totalDays,
      activeDays: activeDays,
      averageIntensity: averageIntensity,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      completionRate: activeDays / totalDays,
    );
  } catch (e) {
    Logger().e('Error calculating statistics: $e');
    // Return empty statistics on error
    return StatisticsData(
      totalDays: days,
      activeDays: 0,
      averageIntensity: 0.0,
      currentStreak: 0,
      longestStreak: 0,
      completionRate: 0.0,
    );
  }
});

final weeklyProgressProvider =
    FutureProvider<List<WeeklyProgress>>((ref) async {
  final repository = ref.watch(statisticsRepositoryProvider);
  final endDate = DateTime.now();
  final startDate = endDate.subtract(const Duration(days: 84)); // 12 weeks

  try {
    final heatMapData = await repository.getHeatMapData(startDate, endDate);
    final weeklyData = <WeeklyProgress>[];

    // Group data by weeks
    DateTime currentWeekStart = _getWeekStart(startDate);

    while (currentWeekStart.isBefore(endDate)) {
      final weekEnd = currentWeekStart.add(const Duration(days: 6));
      final weekData = heatMapData.entries
          .where((entry) =>
              entry.key.isAfter(
                  currentWeekStart.subtract(const Duration(days: 1))) &&
              entry.key.isBefore(weekEnd.add(const Duration(days: 1))))
          .toList();

      final completedDays = weekData.where((entry) => entry.value > 0).length;
      final totalIntensity =
          weekData.fold(0, (sum, entry) => sum + entry.value);
      final averageIntensity =
          weekData.isEmpty ? 0.0 : totalIntensity / weekData.length;

      weeklyData.add(WeeklyProgress(
        weekStart: currentWeekStart,
        completionRate: completedDays / 7,
        completedDays: completedDays,
        totalRoutines: (averageIntensity * 3).round(), // Estimated routines
      ));

      currentWeekStart = currentWeekStart.add(const Duration(days: 7));
    }

    return weeklyData;
  } catch (e) {
    Logger().e('Error calculating weekly progress: $e');
    return [];
  }
});

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final stats =
      await ref.watch(completionStatsProvider(365).future); // 1 year of data

  final achievements = <Achievement>[
    // Streak Achievements
    Achievement(
      id: 'first_streak',
      title: 'Getting Started',
      description: 'Complete routines for 3 consecutive days',
      iconName: 'emoji_events',
      isUnlocked: stats.longestStreak >= 3,
      unlockedAt: stats.longestStreak >= 3 ? DateTime.now() : null,
      progress: stats.longestStreak.clamp(0, 3),
      target: 3,
      type: AchievementType.streak,
    ),
    Achievement(
      id: 'week_warrior',
      title: 'Week Warrior',
      description: 'Complete routines for 7 consecutive days',
      iconName: 'military_tech',
      isUnlocked: stats.longestStreak >= 7,
      unlockedAt: stats.longestStreak >= 7 ? DateTime.now() : null,
      progress: stats.longestStreak.clamp(0, 7),
      target: 7,
      type: AchievementType.streak,
    ),
    Achievement(
      id: 'month_master',
      title: 'Month Master',
      description: 'Complete routines for 30 consecutive days',
      iconName: 'workspace_premium',
      isUnlocked: stats.longestStreak >= 30,
      unlockedAt: stats.longestStreak >= 30 ? DateTime.now() : null,
      progress: stats.longestStreak.clamp(0, 30),
      target: 30,
      type: AchievementType.streak,
    ),
    Achievement(
      id: 'legendary',
      title: 'Legendary',
      description: 'Complete routines for 100 consecutive days',
      iconName: 'diamond',
      isUnlocked: stats.longestStreak >= 100,
      unlockedAt: stats.longestStreak >= 100 ? DateTime.now() : null,
      progress: stats.longestStreak.clamp(0, 100),
      target: 100,
      type: AchievementType.streak,
    ),

    // Completion Achievements
    Achievement(
      id: 'perfectionist',
      title: 'Perfectionist',
      description: 'Achieve 100% completion rate for 7 days',
      iconName: 'star',
      isUnlocked: stats.completionRate >= 1.0 && stats.activeDays >= 7,
      unlockedAt: stats.completionRate >= 1.0 && stats.activeDays >= 7
          ? DateTime.now()
          : null,
      progress: stats.completionRate >= 1.0 ? stats.activeDays.clamp(0, 7) : 0,
      target: 7,
      type: AchievementType.completion,
    ),
    Achievement(
      id: 'consistent',
      title: 'Mr. Consistent',
      description: 'Maintain 80% completion rate for 30 days',
      iconName: 'trending_up',
      isUnlocked: stats.completionRate >= 0.8 && stats.totalDays >= 30,
      unlockedAt: stats.completionRate >= 0.8 && stats.totalDays >= 30
          ? DateTime.now()
          : null,
      progress: stats.completionRate >= 0.8 ? stats.totalDays.clamp(0, 30) : 0,
      target: 30,
      type: AchievementType.consistency,
    ),

    // Milestone Achievements
    Achievement(
      id: 'hundred_days',
      title: 'Century Club',
      description: 'Complete routines for 100 total days',
      iconName: 'confirmation_number',
      isUnlocked: stats.activeDays >= 100,
      unlockedAt: stats.activeDays >= 100 ? DateTime.now() : null,
      progress: stats.activeDays.clamp(0, 100),
      target: 100,
      type: AchievementType.milestone,
    ),
    Achievement(
      id: 'high_intensity',
      title: 'High Achiever',
      description: 'Maintain average intensity above 8.0',
      iconName: 'rocket_launch',
      isUnlocked: stats.averageIntensity >= 8.0,
      unlockedAt: stats.averageIntensity >= 8.0 ? DateTime.now() : null,
      progress: (stats.averageIntensity * 10).round().clamp(0, 80),
      target: 80,
      type: AchievementType.milestone,
    ),
  ];

  return achievements;
});

// Helper functions
int _calculateCurrentStreak(Map<DateTime, int> heatMapData, DateTime endDate) {
  int streak = 0;
  DateTime currentDate = DateTime(endDate.year, endDate.month, endDate.day);

  while (
      heatMapData.containsKey(currentDate) && heatMapData[currentDate]! > 0) {
    streak++;
    currentDate = currentDate.subtract(const Duration(days: 1));
  }

  return streak;
}

int _calculateLongestStreak(Map<DateTime, int> heatMapData) {
  if (heatMapData.isEmpty) return 0;

  final sortedDates = heatMapData.keys.toList()..sort();
  int longestStreak = 0;
  int currentStreak = 0;
  DateTime? previousDate;

  for (final date in sortedDates) {
    if (heatMapData[date]! > 0) {
      if (previousDate == null || date.difference(previousDate).inDays == 1) {
        currentStreak++;
      } else {
        longestStreak =
            longestStreak > currentStreak ? longestStreak : currentStreak;
        currentStreak = 1;
      }
      previousDate = date;
    } else {
      longestStreak =
          longestStreak > currentStreak ? longestStreak : currentStreak;
      currentStreak = 0;
      previousDate = null;
    }
  }

  return longestStreak > currentStreak ? longestStreak : currentStreak;
}

DateTime _getWeekStart(DateTime date) {
  final weekday = date.weekday;
  return date.subtract(Duration(days: weekday - 1));
}
