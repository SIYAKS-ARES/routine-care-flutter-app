import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/streak_model.dart';
import '../../../../shared/models/routine_model.dart';
import '../../../../shared/services/streak_service.dart';
import '../../../../shared/services/firestore_service.dart';
import '../../../../shared/services/notification_service.dart';

// Streak Service Provider
final streakServiceProvider = Provider<StreakService>((ref) {
  final firestoreService = FirestoreService();
  final notificationService = NotificationService();

  return StreakService(firestoreService, notificationService);
});

// Streak Notifier
class StreakNotifier extends AsyncNotifier<List<StreakModel>> {
  @override
  Future<List<StreakModel>> build() async {
    // Mock user ID - replace with actual auth provider
    const userId = 'mock_user_id';

    final streakService = ref.watch(streakServiceProvider);
    return await streakService.getAllStreaks(userId);
  }

  Future<void> onRoutineCompleted(RoutineModel routine) async {
    // Mock user ID - replace with actual auth provider
    const userId = 'mock_user_id';

    final streakService = ref.read(streakServiceProvider);

    try {
      final updatedStreaks = await streakService.onRoutineCompleted(
        routine,
        userId,
      );

      // Check for milestone achievements
      for (final streak in updatedStreaks) {
        _checkMilestoneAchievement(streak);
      }

      // Refresh streaks
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('Error completing routine streak: $e');
    }
  }

  Future<void> resetStreak(String streakId) async {
    // Mock user ID - replace with actual auth provider
    const userId = 'mock_user_id';

    final streakService = ref.read(streakServiceProvider);

    try {
      await streakService.resetStreak(streakId, userId);
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('Error resetting streak: $e');
    }
  }

  void _checkMilestoneAchievement(StreakModel streak) {
    final currentMilestone = streak.currentMilestone;
    final previousStreak = streak.currentStreak - 1;
    final previousMilestone =
        StreakMilestone.getCurrentMilestone(previousStreak);

    // Yeni milestone'a ulaşıldı mı?
    if (currentMilestone != null && currentMilestone != previousMilestone) {
      // Milestone achievement'ı trigger et
      ref
          .read(streakCelebrationProvider.notifier)
          .triggerMilestoneCelebration(streak, currentMilestone);
    }
  }
}

final streakNotifierProvider =
    AsyncNotifierProvider<StreakNotifier, List<StreakModel>>(
  () => StreakNotifier(),
);

// Streak Statistics Notifier
class StreakStatisticsNotifier extends AsyncNotifier<StreakStatistics> {
  @override
  Future<StreakStatistics> build() async {
    // Mock user ID - replace with actual auth provider
    const userId = 'mock_user_id';

    final streakService = ref.watch(streakServiceProvider);
    return await streakService.calculateStreakStatistics(userId);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final streakStatisticsProvider =
    AsyncNotifierProvider<StreakStatisticsNotifier, StreakStatistics>(
  () => StreakStatisticsNotifier(),
);

// Streak Celebration State
class StreakCelebrationState {
  final bool showingCelebration;
  final StreakModel? celebratingStreak;
  final StreakMilestone? celebratingMilestone;

  const StreakCelebrationState({
    this.showingCelebration = false,
    this.celebratingStreak,
    this.celebratingMilestone,
  });

  StreakCelebrationState copyWith({
    bool? showingCelebration,
    StreakModel? celebratingStreak,
    StreakMilestone? celebratingMilestone,
  }) {
    return StreakCelebrationState(
      showingCelebration: showingCelebration ?? this.showingCelebration,
      celebratingStreak: celebratingStreak ?? this.celebratingStreak,
      celebratingMilestone: celebratingMilestone ?? this.celebratingMilestone,
    );
  }
}

// Streak Celebration Notifier
class StreakCelebrationNotifier extends Notifier<StreakCelebrationState> {
  @override
  StreakCelebrationState build() {
    return const StreakCelebrationState();
  }

  void triggerMilestoneCelebration(
      StreakModel streak, StreakMilestone milestone) {
    state = state.copyWith(
      showingCelebration: true,
      celebratingStreak: streak,
      celebratingMilestone: milestone,
    );
  }

  void completeCelebration() {
    state = state.copyWith(
      showingCelebration: false,
      celebratingStreak: null,
      celebratingMilestone: null,
    );
  }
}

final streakCelebrationProvider =
    NotifierProvider<StreakCelebrationNotifier, StreakCelebrationState>(
  () => StreakCelebrationNotifier(),
);

// Derived providers
final streaksAtRiskProvider = Provider<List<StreakModel>>((ref) {
  final streaksAsync = ref.watch(streakNotifierProvider);

  return streaksAsync.when(
    data: (streaks) => streaks
        .where((s) => s.isActive && s.riskLevel > 0.3 && s.currentStreak >= 3)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final activeStreaksProvider = Provider<List<StreakModel>>((ref) {
  final streaksAsync = ref.watch(streakNotifierProvider);

  return streaksAsync.when(
    data: (streaks) => streaks.where((s) => s.isActive).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Streak UI State
class StreakUIStateData {
  final StreakModel? selectedStreak;
  final bool showingDetails;
  final Set<String> dismissedWarnings;

  const StreakUIStateData({
    this.selectedStreak,
    this.showingDetails = false,
    this.dismissedWarnings = const {},
  });

  StreakUIStateData copyWith({
    StreakModel? selectedStreak,
    bool? showingDetails,
    Set<String>? dismissedWarnings,
  }) {
    return StreakUIStateData(
      selectedStreak: selectedStreak ?? this.selectedStreak,
      showingDetails: showingDetails ?? this.showingDetails,
      dismissedWarnings: dismissedWarnings ?? this.dismissedWarnings,
    );
  }
}

class StreakUIStateNotifier extends Notifier<StreakUIStateData> {
  @override
  StreakUIStateData build() {
    return const StreakUIStateData();
  }

  void showStreakDetails(StreakModel streak) {
    state = state.copyWith(
      selectedStreak: streak,
      showingDetails: true,
    );
  }

  void hideStreakDetails() {
    state = state.copyWith(
      selectedStreak: null,
      showingDetails: false,
    );
  }

  void dismissWarning(String streakId) {
    final dismissedWarnings = {...state.dismissedWarnings, streakId};
    state = state.copyWith(dismissedWarnings: dismissedWarnings);
  }

  void resetDismissedWarnings() {
    state = state.copyWith(dismissedWarnings: {});
  }
}

final streakUIStateProvider =
    NotifierProvider<StreakUIStateNotifier, StreakUIStateData>(
  () => StreakUIStateNotifier(),
);

// Extension methods for easier usage
extension StreakProviderExtensions on WidgetRef {
  Future<void> completeRoutineWithStreak(RoutineModel routine) async {
    await read(streakNotifierProvider.notifier).onRoutineCompleted(routine);
  }

  List<StreakModel> getActiveStreaks() {
    return watch(activeStreaksProvider);
  }

  List<StreakModel> getStreaksAtRisk() {
    return watch(streaksAtRiskProvider);
  }

  StreakCelebrationState getStreakCelebrationState() {
    return watch(streakCelebrationProvider);
  }

  void showMilestoneCelebration(StreakModel streak, StreakMilestone milestone) {
    read(streakCelebrationProvider.notifier)
        .triggerMilestoneCelebration(streak, milestone);
  }

  void completeMilestoneCelebration() {
    read(streakCelebrationProvider.notifier).completeCelebration();
  }
}
