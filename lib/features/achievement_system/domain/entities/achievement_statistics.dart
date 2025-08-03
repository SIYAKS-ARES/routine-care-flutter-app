import '../../../../shared/models/achievement_model.dart';

class AchievementStatistics {
  final int totalAchievements;
  final int unlockedAchievements;
  final double completionRate;
  final int totalExperiencePoints;
  final int currentStreak;
  final int longestStreak;
  final Map<AchievementRarity, int> rarityBreakdown;
  final Map<AchievementType, int> typeBreakdown;
  final DateTime lastUpdated;

  const AchievementStatistics({
    required this.totalAchievements,
    required this.unlockedAchievements,
    required this.completionRate,
    required this.totalExperiencePoints,
    required this.currentStreak,
    required this.longestStreak,
    required this.rarityBreakdown,
    required this.typeBreakdown,
    required this.lastUpdated,
  });

  AchievementStatistics copyWith({
    int? totalAchievements,
    int? unlockedAchievements,
    double? completionRate,
    int? totalExperiencePoints,
    int? currentStreak,
    int? longestStreak,
    Map<AchievementRarity, int>? rarityBreakdown,
    Map<AchievementType, int>? typeBreakdown,
    DateTime? lastUpdated,
  }) {
    return AchievementStatistics(
      totalAchievements: totalAchievements ?? this.totalAchievements,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      completionRate: completionRate ?? this.completionRate,
      totalExperiencePoints:
          totalExperiencePoints ?? this.totalExperiencePoints,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      rarityBreakdown: rarityBreakdown ?? this.rarityBreakdown,
      typeBreakdown: typeBreakdown ?? this.typeBreakdown,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalAchievements': totalAchievements,
        'unlockedAchievements': unlockedAchievements,
        'completionRate': completionRate,
        'totalExperiencePoints': totalExperiencePoints,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'rarityBreakdown':
            rarityBreakdown.map((key, value) => MapEntry(key.name, value)),
        'typeBreakdown':
            typeBreakdown.map((key, value) => MapEntry(key.name, value)),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory AchievementStatistics.fromJson(Map<String, dynamic> json) {
    final rarityMap = <AchievementRarity, int>{};
    final rarityData = json['rarityBreakdown'] as Map<String, dynamic>? ?? {};
    for (final entry in rarityData.entries) {
      final rarity =
          AchievementRarity.values.firstWhere((r) => r.name == entry.key);
      rarityMap[rarity] = entry.value as int;
    }

    final typeMap = <AchievementType, int>{};
    final typeData = json['typeBreakdown'] as Map<String, dynamic>? ?? {};
    for (final entry in typeData.entries) {
      final type =
          AchievementType.values.firstWhere((t) => t.name == entry.key);
      typeMap[type] = entry.value as int;
    }

    return AchievementStatistics(
      totalAchievements: json['totalAchievements'] ?? 0,
      unlockedAchievements: json['unlockedAchievements'] ?? 0,
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
      totalExperiencePoints: json['totalExperiencePoints'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      rarityBreakdown: rarityMap,
      typeBreakdown: typeMap,
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  factory AchievementStatistics.empty() => AchievementStatistics(
        totalAchievements: 0,
        unlockedAchievements: 0,
        completionRate: 0.0,
        totalExperiencePoints: 0,
        currentStreak: 0,
        longestStreak: 0,
        rarityBreakdown: {},
        typeBreakdown: {},
        lastUpdated: DateTime.now(),
      );

  // Helper getters
  int get lockedAchievements => totalAchievements - unlockedAchievements;
  bool get hasAchievements => totalAchievements > 0;
  bool get hasUnlockedAchievements => unlockedAchievements > 0;
  bool get isComplete => completionRate >= 100.0;

  int getRarityCount(AchievementRarity rarity) => rarityBreakdown[rarity] ?? 0;
  int getTypeCount(AchievementType type) => typeBreakdown[type] ?? 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementStatistics &&
          runtimeType == other.runtimeType &&
          totalAchievements == other.totalAchievements &&
          unlockedAchievements == other.unlockedAchievements &&
          completionRate == other.completionRate &&
          totalExperiencePoints == other.totalExperiencePoints &&
          currentStreak == other.currentStreak &&
          longestStreak == other.longestStreak;

  @override
  int get hashCode =>
      totalAchievements.hashCode ^
      unlockedAchievements.hashCode ^
      completionRate.hashCode ^
      totalExperiencePoints.hashCode ^
      currentStreak.hashCode ^
      longestStreak.hashCode;

  @override
  String toString() =>
      'AchievementStatistics(total: $totalAchievements, unlocked: $unlockedAchievements, rate: ${completionRate.toStringAsFixed(1)}%)';
}
