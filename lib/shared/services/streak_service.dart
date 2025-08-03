import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/streak_model.dart';
import '../models/routine_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class StreakService {
  final FirestoreService _firestoreService;
  final NotificationService _notificationService;

  // Streak data caching
  final Map<String, StreakModel> _streakCache = {};
  final StreamController<StreakModel> _streakUpdateController =
      StreamController.broadcast();

  StreakService(this._firestoreService, this._notificationService);

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Stream for real-time streak updates
  Stream<StreakModel> get streakUpdates => _streakUpdateController.stream;

  // Ana rutin tamamlama işlemi
  Future<List<StreakModel>> onRoutineCompleted(
      RoutineModel routine, String userId) async {
    final updatedStreaks = <StreakModel>[];

    try {
      // 1. Routine-specific streak güncelle
      final routineStreak = await _updateRoutineStreak(routine, userId);
      if (routineStreak != null) {
        updatedStreaks.add(routineStreak);
      }

      // 2. Category streak güncelle
      if (routine.categoryId?.isNotEmpty ?? false) {
        final categoryStreak =
            await _updateCategoryStreak(routine.categoryId!, userId);
        if (categoryStreak != null) {
          updatedStreaks.add(categoryStreak);
        }
      }

      // 3. Overall/daily streak güncelle
      final overallStreak = await _updateOverallStreak(userId);
      if (overallStreak != null) {
        updatedStreaks.add(overallStreak);
      }

      // 4. Milestone detections
      for (final streak in updatedStreaks) {
        await _checkMilestoneAchievements(streak);
      }

      return updatedStreaks;
    } catch (e) {
      debugPrint('Error updating streaks: $e');
      return [];
    }
  }

  // Belirli routine için streak güncelle
  Future<StreakModel?> _updateRoutineStreak(
      RoutineModel routine, String userId) async {
    final streakId = 'routine_${routine.id}';
    final existingStreak = await getStreakById(streakId, userId);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (existingStreak == null) {
      // Yeni streak oluştur
      final newStreak = StreakModel(
        id: streakId,
        type: StreakType.routine,
        routineId: routine.id,
        currentStreak: 1,
        longestStreak: 1,
        lastCompletionDate: today,
        createdAt: now,
        lastUpdated: now,
        status: StreakStatus.active,
      );

      await _saveStreak(newStreak, userId);
      return newStreak;
    }

    // Mevcut streak güncelle
    return await _updateExistingStreak(existingStreak, today, userId);
  }

  // Kategori streak'i güncelle
  Future<StreakModel?> _updateCategoryStreak(
      String categoryId, String userId) async {
    final streakId = 'category_$categoryId';
    final existingStreak = await getStreakById(streakId, userId);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (existingStreak == null) {
      final newStreak = StreakModel(
        id: streakId,
        type: StreakType.category,
        categoryId: categoryId,
        currentStreak: 1,
        longestStreak: 1,
        lastCompletionDate: today,
        createdAt: now,
        lastUpdated: now,
        status: StreakStatus.active,
      );

      await _saveStreak(newStreak, userId);
      return newStreak;
    }

    return await _updateExistingStreak(existingStreak, today, userId);
  }

  // Genel streak güncelle (günlük aktivite)
  Future<StreakModel?> _updateOverallStreak(String userId) async {
    const streakId = 'overall_daily';
    final existingStreak = await getStreakById(streakId, userId);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (existingStreak == null) {
      final newStreak = StreakModel(
        id: streakId,
        type: StreakType.overall,
        currentStreak: 1,
        longestStreak: 1,
        lastCompletionDate: today,
        createdAt: now,
        lastUpdated: now,
        status: StreakStatus.active,
      );

      await _saveStreak(newStreak, userId);
      return newStreak;
    }

    return await _updateExistingStreak(existingStreak, today, userId);
  }

  // Mevcut streak'i güncelle
  Future<StreakModel> _updateExistingStreak(
      StreakModel streak, DateTime completionDate, String userId) async {
    final lastCompletion = streak.lastCompletionDate;

    if (lastCompletion == null) {
      // İlk tamamlama
      final updatedStreak = streak.copyWith(
        currentStreak: 1,
        longestStreak: math.max(1, streak.longestStreak),
        lastCompletionDate: completionDate,
        lastUpdated: DateTime.now(),
        status: StreakStatus.active,
      );

      await _saveStreak(updatedStreak, userId);
      return updatedStreak;
    }

    final daysSinceLastCompletion =
        completionDate.difference(lastCompletion).inDays;

    StreakModel updatedStreak;

    if (daysSinceLastCompletion == 0) {
      // Aynı gün, değişiklik yok
      return streak;
    } else if (daysSinceLastCompletion == 1) {
      // Ardışık gün, streak artır
      final newCurrentStreak = streak.currentStreak + 1;
      updatedStreak = streak.copyWith(
        currentStreak: newCurrentStreak,
        longestStreak: math.max(newCurrentStreak, streak.longestStreak),
        lastCompletionDate: completionDate,
        lastUpdated: DateTime.now(),
        status: StreakStatus.active,
      );
    } else {
      // Streak kırıldı, yeniden başla
      updatedStreak = streak.copyWith(
        currentStreak: 1,
        lastCompletionDate: completionDate,
        lastUpdated: DateTime.now(),
        status: StreakStatus.active,
      );

      // Streak kırılma bildirimi
      await _notifyStreakBroken(streak);
    }

    await _saveStreak(updatedStreak, userId);
    return updatedStreak;
  }

  // Milestone achievements kontrolü
  Future<void> _checkMilestoneAchievements(StreakModel streak) async {
    final currentMilestone = streak.currentMilestone;
    final previousStreak = streak.currentStreak - 1;
    final previousMilestone =
        StreakMilestone.getCurrentMilestone(previousStreak);

    // Yeni milestone'a ulaşıldı mı?
    if (currentMilestone != null && currentMilestone != previousMilestone) {
      await _celebrateMilestone(streak, currentMilestone);
    }
  }

  // Milestone kutlaması
  Future<void> _celebrateMilestone(
      StreakModel streak, StreakMilestone milestone) async {
    // Bildirim gönder
    debugPrint('🔥 Milestone: ${milestone.emoji} ${milestone.title}');
    debugPrint(
        '${streak.currentStreak} günlük serin var! ${milestone.description}');
  }

  // Streak kırılma bildirimi
  Future<void> _notifyStreakBroken(StreakModel streak) async {
    if (streak.currentStreak >= 3) {
      debugPrint(
          '😢 Serin Kırıldı: ${streak.currentStreak} günlük serin sona erdi.');
    }
  }

  // Günlük streak kontrolü (background task için)
  Future<void> checkDailyStreaks(String userId) async {
    final allStreaks = await getAllActiveStreaks(userId);
    final now = DateTime.now();

    for (final streak in allStreaks) {
      if (streak.lastCompletionDate == null) continue;

      final daysSinceLastCompletion =
          now.difference(streak.lastCompletionDate!).inDays;

      // Streak otomatik kırma (2 gün geçmişse)
      if (daysSinceLastCompletion >= 2) {
        final brokenStreak = streak.copyWith(
          status: StreakStatus.broken,
          lastUpdated: now,
        );

        await _saveStreak(brokenStreak, userId);
        await _notifyStreakBroken(streak);
      }
    }
  }

  // Streak istatistiklerini hesapla
  Future<StreakStatistics> calculateStreakStatistics(String userId) async {
    final allStreaks = await getAllStreaks(userId);
    final now = DateTime.now();

    final activeStreaks = allStreaks.where((s) => s.isActive).length;
    final brokenStreaks = allStreaks.where((s) => s.isBroken).length;

    final longestOverallStreak = allStreaks
        .map((s) => s.longestStreak)
        .fold<int>(0, (prev, current) => math.max(prev, current));

    final currentOverallStreak = allStreaks
        .where((s) => s.type == StreakType.overall)
        .map((s) => s.currentStreak)
        .fold<int>(0, (prev, current) => math.max(prev, current));

    final streaksByType = <StreakType, int>{};
    for (final type in StreakType.values) {
      streaksByType[type] = allStreaks.where((s) => s.type == type).length;
    }

    final milestonesAchieved = <StreakMilestone, int>{};
    for (final milestone in StreakMilestone.values) {
      milestonesAchieved[milestone] =
          allStreaks.where((s) => s.currentStreak >= milestone.days).length;
    }

    final totalDaysWithStreaks = allStreaks
        .map((s) => s.currentStreak)
        .fold<int>(0, (prev, current) => prev + current);

    final averageStreakLength =
        allStreaks.isNotEmpty ? totalDaysWithStreaks / allStreaks.length : 0.0;

    return StreakStatistics(
      totalStreaks: allStreaks.length,
      activeStreaks: activeStreaks,
      brokenStreaks: brokenStreaks,
      longestOverallStreak: longestOverallStreak,
      currentOverallStreak: currentOverallStreak,
      streaksByType: streaksByType,
      milestonesAchieved: milestonesAchieved,
      lastStreakDate: allStreaks.isNotEmpty
          ? allStreaks
              .map((s) => s.lastCompletionDate)
              .where((d) => d != null)
              .cast<DateTime>()
              .fold<DateTime?>(
                  null,
                  (prev, current) =>
                      prev == null || current.isAfter(prev) ? current : prev)
          : null,
      averageStreakLength: averageStreakLength,
      totalDaysWithStreaks: totalDaysWithStreaks,
      calculatedAt: now,
    );
  }

  // Helper methods
  Future<StreakModel?> getStreakById(String id, String userId) async {
    if (_streakCache.containsKey(id)) {
      return _streakCache[id];
    }

    try {
      if (!_firestoreService.isFirebaseAvailable) return null;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('streaks')
          .doc(id)
          .get();

      if (doc.exists) {
        final streak = StreakModel.fromJson(doc.data()!);
        _streakCache[id] = streak;
        return streak;
      }
    } catch (e) {
      debugPrint('Error getting streak: $e');
    }

    return null;
  }

  Future<List<StreakModel>> getAllStreaks(String userId) async {
    try {
      if (!_firestoreService.isFirebaseAvailable) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('streaks')
          .get();

      return querySnapshot.docs
          .map((doc) => StreakModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting all streaks: $e');
      return [];
    }
  }

  Future<List<StreakModel>> getAllActiveStreaks(String userId) async {
    final allStreaks = await getAllStreaks(userId);
    return allStreaks.where((s) => s.isActive).toList();
  }

  Future<List<StreakModel>> getStreaksByType(
      StreakType type, String userId) async {
    final allStreaks = await getAllStreaks(userId);
    return allStreaks.where((s) => s.type == type).toList();
  }

  Future<List<StreakModel>> getStreaksByRoutine(
      String routineId, String userId) async {
    final allStreaks = await getAllStreaks(userId);
    return allStreaks.where((s) => s.routineId == routineId).toList();
  }

  Future<void> _saveStreak(StreakModel streak, String userId) async {
    try {
      if (!_firestoreService.isFirebaseAvailable) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('streaks')
          .doc(streak.id)
          .set(streak.toJson());

      _streakCache[streak.id] = streak;
      _streakUpdateController.add(streak);
    } catch (e) {
      debugPrint('Error saving streak: $e');
      rethrow;
    }
  }

  // Streak reset (kullanıcı isteği üzerine)
  Future<void> resetStreak(String streakId, String userId) async {
    final streak = await getStreakById(streakId, userId);
    if (streak == null) return;

    final resetStreak = streak.copyWith(
      currentStreak: 0,
      lastCompletionDate: null,
      lastUpdated: DateTime.now(),
      status: StreakStatus.broken,
    );

    await _saveStreak(resetStreak, userId);
  }

  Stream<List<StreakModel>> getUserStreaksStream(String userId) {
    if (!_firestoreService.isFirebaseAvailable) {
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('streaks')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => StreakModel.fromJson(doc.data()))
              .toList());
    } catch (e) {
      debugPrint('Error getting user streaks stream: $e');
      return Stream.value([]);
    }
  }

  void dispose() {
    _streakUpdateController.close();
  }
}
