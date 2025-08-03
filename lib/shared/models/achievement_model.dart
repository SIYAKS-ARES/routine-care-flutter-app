import 'package:flutter/material.dart';

enum AchievementType {
  routine, // Rutin tabanlı başarılar
  goal, // Hedef tabanlı başarılar
  streak, // Seri tabanlı başarılar
  category, // Kategori tabanlı başarılar
  time, // Zaman tabanlı başarılar
  milestone, // Milestone tabanlı başarılar
  special, // Özel başarılar
}

enum AchievementRarity {
  common, // Ortak (bronz)
  uncommon, // Nadir (gümüş)
  rare, // Nadir (altın)
  epic, // Epik (elmas)
  legendary, // Efsanevi (platinyum)
}

enum UnlockConditionType {
  routineCompletion, // X rutin tamamlama
  goalCompletion, // X hedef tamamlama
  streakAchievement, // X gün seri
  categoryMastery, // Kategori ustalığı
  timeSpent, // Zaman geçirme
  milestoneReached, // Milestone ulaşma
  consecutiveDays, // Ardışık günler
  perfectWeek, // Mükemmel hafta
  custom, // Özel koşul
}

class UnlockCondition {
  final UnlockConditionType type;
  final int targetValue;
  final String? categoryId;
  final String? routineId;
  final Map<String, dynamic>? customData;

  const UnlockCondition({
    required this.type,
    required this.targetValue,
    this.categoryId,
    this.routineId,
    this.customData,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'targetValue': targetValue,
        'categoryId': categoryId,
        'routineId': routineId,
        'customData': customData,
      };

  factory UnlockCondition.fromJson(Map<String, dynamic> json) =>
      UnlockCondition(
        type: UnlockConditionType.values
            .firstWhere((e) => e.name == json['type']),
        targetValue: json['targetValue'],
        categoryId: json['categoryId'],
        routineId: json['routineId'],
        customData: json['customData'] != null
            ? Map<String, dynamic>.from(json['customData'])
            : null,
      );
}

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final AchievementRarity rarity;

  // Visual Properties
  final IconData icon;
  final Color color;
  final String? badgeImagePath;

  // Unlock Properties
  final List<UnlockCondition> unlockConditions;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int currentProgress;
  final bool isHidden; // Gizli başarı (unlock edilene kadar görünmez)

  // Reward Properties
  final int experiencePoints;
  final String? rewardDescription;
  final Map<String, dynamic>? rewardData;

  // Metadata
  final DateTime createdAt;
  final String? category;
  final List<String> tags;
  final int sortOrder;
  final bool isActive;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.rarity,
    required this.icon,
    required this.color,
    this.badgeImagePath,
    required this.unlockConditions,
    this.isUnlocked = false,
    this.unlockedAt,
    this.currentProgress = 0,
    this.isHidden = false,
    this.experiencePoints = 0,
    this.rewardDescription,
    this.rewardData,
    required this.createdAt,
    this.category,
    this.tags = const [],
    this.sortOrder = 0,
    this.isActive = true,
  });

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    AchievementType? type,
    AchievementRarity? rarity,
    IconData? icon,
    Color? color,
    String? badgeImagePath,
    List<UnlockCondition>? unlockConditions,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? currentProgress,
    bool? isHidden,
    int? experiencePoints,
    String? rewardDescription,
    Map<String, dynamic>? rewardData,
    DateTime? createdAt,
    String? category,
    List<String>? tags,
    int? sortOrder,
    bool? isActive,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      badgeImagePath: badgeImagePath ?? this.badgeImagePath,
      unlockConditions: unlockConditions ?? this.unlockConditions,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      currentProgress: currentProgress ?? this.currentProgress,
      isHidden: isHidden ?? this.isHidden,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      rewardData: rewardData ?? this.rewardData,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'rarity': rarity.name,
        'iconCodePoint': icon.codePoint,
        'iconFontFamily': icon.fontFamily,
        'colorValue': color.value,
        'badgeImagePath': badgeImagePath,
        'unlockConditions': unlockConditions.map((c) => c.toJson()).toList(),
        'isUnlocked': isUnlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
        'currentProgress': currentProgress,
        'isHidden': isHidden,
        'experiencePoints': experiencePoints,
        'rewardDescription': rewardDescription,
        'rewardData': rewardData,
        'createdAt': createdAt.toIso8601String(),
        'category': category,
        'tags': tags,
        'sortOrder': sortOrder,
        'isActive': isActive,
      };

  factory AchievementModel.fromJson(Map<String, dynamic> json) =>
      AchievementModel(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        type: AchievementType.values.firstWhere((e) => e.name == json['type']),
        rarity: AchievementRarity.values
            .firstWhere((e) => e.name == json['rarity']),
        icon: IconData(
          json['iconCodePoint'],
          fontFamily: json['iconFontFamily'],
        ),
        color: Color(json['colorValue']),
        badgeImagePath: json['badgeImagePath'],
        unlockConditions: (json['unlockConditions'] as List<dynamic>)
            .map((c) => UnlockCondition.fromJson(Map<String, dynamic>.from(c)))
            .toList(),
        isUnlocked: json['isUnlocked'] ?? false,
        unlockedAt: json['unlockedAt'] != null
            ? DateTime.parse(json['unlockedAt'])
            : null,
        currentProgress: json['currentProgress'] ?? 0,
        isHidden: json['isHidden'] ?? false,
        experiencePoints: json['experiencePoints'] ?? 0,
        rewardDescription: json['rewardDescription'],
        rewardData: json['rewardData'] != null
            ? Map<String, dynamic>.from(json['rewardData'])
            : null,
        createdAt: DateTime.parse(json['createdAt']),
        category: json['category'],
        tags: List<String>.from(json['tags'] ?? []),
        sortOrder: json['sortOrder'] ?? 0,
        isActive: json['isActive'] ?? true,
      );

  // Helper Methods
  bool get canBeDisplayed => !isHidden || isUnlocked;

  double get progressPercentage {
    if (unlockConditions.isEmpty) return 0.0;
    // Simplest condition for progress calculation
    final primaryCondition = unlockConditions.first;
    return primaryCondition.targetValue > 0
        ? (currentProgress / primaryCondition.targetValue) * 100
        : 0.0;
  }

  bool get isNearCompletion => progressPercentage >= 80;
  bool get isHalfway => progressPercentage >= 50;

  String get rarityName {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Ortak';
      case AchievementRarity.uncommon:
        return 'Nadir';
      case AchievementRarity.rare:
        return 'Nadir';
      case AchievementRarity.epic:
        return 'Epik';
      case AchievementRarity.legendary:
        return 'Efsanevi';
    }
  }

  Color get rarityColor {
    switch (rarity) {
      case AchievementRarity.common:
        return const Color(0xFFCD7F32); // Bronze
      case AchievementRarity.uncommon:
        return const Color(0xFFC0C0C0); // Silver
      case AchievementRarity.rare:
        return const Color(0xFFFFD700); // Gold
      case AchievementRarity.epic:
        return const Color(0xFF9932CC); // Purple
      case AchievementRarity.legendary:
        return const Color(0xFFE5E4E2); // Platinum
    }
  }

  String get typeName {
    switch (type) {
      case AchievementType.routine:
        return 'Rutin';
      case AchievementType.goal:
        return 'Hedef';
      case AchievementType.streak:
        return 'Seri';
      case AchievementType.category:
        return 'Kategori';
      case AchievementType.time:
        return 'Zaman';
      case AchievementType.milestone:
        return 'Milestone';
      case AchievementType.special:
        return 'Özel';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AchievementModel(id: $id, title: $title, unlocked: $isUnlocked)';
}

// Predefined Achievement Templates
class AchievementTemplates {
  static const List<AchievementTemplate> templates = [
    // Routine-based achievements
    AchievementTemplate(
      title: 'İlk Adım',
      description: 'İlk rutinini tamamla',
      type: AchievementType.routine,
      rarity: AchievementRarity.common,
      icon: Icons.play_arrow,
      color: Colors.green,
      unlockCondition: UnlockCondition(
        type: UnlockConditionType.routineCompletion,
        targetValue: 1,
      ),
      experiencePoints: 10,
    ),

    AchievementTemplate(
      title: 'Rutin Ustası',
      description: '100 rutin tamamla',
      type: AchievementType.routine,
      rarity: AchievementRarity.rare,
      icon: Icons.emoji_events,
      color: Colors.orange,
      unlockCondition: UnlockCondition(
        type: UnlockConditionType.routineCompletion,
        targetValue: 100,
      ),
      experiencePoints: 100,
    ),

    // Streak-based achievements
    AchievementTemplate(
      title: '7 Günlük Seri',
      description: '7 gün üst üste rutin tamamla',
      type: AchievementType.streak,
      rarity: AchievementRarity.uncommon,
      icon: Icons.local_fire_department,
      color: Colors.red,
      unlockCondition: UnlockCondition(
        type: UnlockConditionType.streakAchievement,
        targetValue: 7,
      ),
      experiencePoints: 50,
    ),

    AchievementTemplate(
      title: '30 Günlük Disiplin',
      description: '30 gün üst üste rutin tamamla',
      type: AchievementType.streak,
      rarity: AchievementRarity.epic,
      icon: Icons.military_tech,
      color: Colors.purple,
      unlockCondition: UnlockCondition(
        type: UnlockConditionType.streakAchievement,
        targetValue: 30,
      ),
      experiencePoints: 200,
    ),

    // Goal-based achievements
    AchievementTemplate(
      title: 'Hedef Avcısı',
      description: 'İlk hedefini tamamla',
      type: AchievementType.goal,
      rarity: AchievementRarity.common,
      icon: Icons.flag,
      color: Colors.blue,
      unlockCondition: UnlockCondition(
        type: UnlockConditionType.goalCompletion,
        targetValue: 1,
      ),
      experiencePoints: 25,
    ),

    AchievementTemplate(
      title: 'Hedef Ustası',
      description: '10 hedef tamamla',
      type: AchievementType.goal,
      rarity: AchievementRarity.rare,
      icon: Icons.workspace_premium,
      color: Colors.deepOrange,
      unlockCondition: UnlockCondition(
        type: UnlockConditionType.goalCompletion,
        targetValue: 10,
      ),
      experiencePoints: 150,
    ),

    // Special achievements
    AchievementTemplate(
      title: 'Mükemmel Hafta',
      description: 'Bir hafta boyunca tüm rutinleri tamamla',
      type: AchievementType.special,
      rarity: AchievementRarity.epic,
      icon: Icons.star,
      color: Colors.amber,
      unlockCondition: UnlockCondition(
        type: UnlockConditionType.perfectWeek,
        targetValue: 1,
      ),
      experiencePoints: 300,
      isHidden: true,
    ),

    AchievementTemplate(
      title: 'Efsane',
      description: '365 gün üst üste rutin tamamla',
      type: AchievementType.streak,
      rarity: AchievementRarity.legendary,
      icon: Icons.diamond,
      color: Colors.cyan,
      unlockCondition: UnlockCondition(
        type: UnlockConditionType.streakAchievement,
        targetValue: 365,
      ),
      experiencePoints: 1000,
      isHidden: true,
    ),
  ];

  static AchievementModel createFromTemplate(AchievementTemplate template) {
    final now = DateTime.now();
    return AchievementModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: template.title,
      description: template.description,
      type: template.type,
      rarity: template.rarity,
      icon: template.icon,
      color: template.color,
      unlockConditions: [template.unlockCondition],
      experiencePoints: template.experiencePoints,
      isHidden: template.isHidden,
      createdAt: now,
      category: template.type.name,
      tags: [template.type.name, template.rarity.name],
    );
  }

  static List<AchievementModel> createAllTemplates() {
    return templates.map((template) => createFromTemplate(template)).toList();
  }
}

class AchievementTemplate {
  final String title;
  final String description;
  final AchievementType type;
  final AchievementRarity rarity;
  final IconData icon;
  final Color color;
  final UnlockCondition unlockCondition;
  final int experiencePoints;
  final bool isHidden;

  const AchievementTemplate({
    required this.title,
    required this.description,
    required this.type,
    required this.rarity,
    required this.icon,
    required this.color,
    required this.unlockCondition,
    this.experiencePoints = 0,
    this.isHidden = false,
  });
}
