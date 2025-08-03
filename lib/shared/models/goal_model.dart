import 'package:flutter/material.dart';

enum GoalType {
  dailyStreak, // X gün üst üste
  weeklyCount, // Haftada X kez
  monthlyCount, // Ayda X kez
  customPeriod, // Belirli tarih aralığında X kez
  totalCount, // Toplam X kez (süresiz)
}

enum GoalStatus {
  active, // Aktif hedef
  completed, // Tamamlanmış hedef
  paused, // Duraklatılmış hedef
  failed, // Başarısız hedef
  expired, // Süresi dolmuş hedef
}

enum GoalDifficulty {
  easy, // Kolay
  medium, // Orta
  hard, // Zor
  extreme, // Aşırı zor
}

class GoalModel {
  final String id;
  final String name;
  final String description;
  final GoalType type;
  final GoalStatus status;
  final GoalDifficulty difficulty;

  // Target and Progress
  final int targetValue; // Hedef değer (örn: 30 gün, 5 kez/hafta)
  final int currentProgress; // Mevcut ilerleme
  final double progressPercentage; // İlerleme yüzdesi

  // Routine & Category Association
  final String? routineId; // Belirli bir rutin için hedef
  final String? categoryId; // Belirli bir kategori için hedef
  final List<String> routineIds; // Birden fazla rutin için hedef

  // Time Configuration
  final DateTime startDate; // Hedef başlangıç tarihi
  final DateTime? endDate; // Hedef bitiş tarihi (null = süresiz)
  final DateTime? completedDate; // Tamamlanma tarihi

  // Reward & Motivation
  final String? rewardDescription; // Ödül açıklaması
  final IconData? rewardIcon; // Ödül ikonu
  final bool isRewarded; // Ödül verildi mi?

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? userId;
  final List<String> tags; // Etiketler (#fitness, #health vs.)

  // Milestones
  final List<Milestone> milestones; // Ara hedefler

  const GoalModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.difficulty,
    required this.targetValue,
    required this.currentProgress,
    required this.progressPercentage,
    this.routineId,
    this.categoryId,
    this.routineIds = const [],
    required this.startDate,
    this.endDate,
    this.completedDate,
    this.rewardDescription,
    this.rewardIcon,
    this.isRewarded = false,
    required this.createdAt,
    this.updatedAt,
    this.userId,
    this.tags = const [],
    this.milestones = const [],
  });

  GoalModel copyWith({
    String? id,
    String? name,
    String? description,
    GoalType? type,
    GoalStatus? status,
    GoalDifficulty? difficulty,
    int? targetValue,
    int? currentProgress,
    double? progressPercentage,
    String? routineId,
    String? categoryId,
    List<String>? routineIds,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? completedDate,
    String? rewardDescription,
    IconData? rewardIcon,
    bool? isRewarded,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    List<String>? tags,
    List<Milestone>? milestones,
  }) {
    return GoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      targetValue: targetValue ?? this.targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      routineId: routineId ?? this.routineId,
      categoryId: categoryId ?? this.categoryId,
      routineIds: routineIds ?? this.routineIds,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      completedDate: completedDate ?? this.completedDate,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      rewardIcon: rewardIcon ?? this.rewardIcon,
      isRewarded: isRewarded ?? this.isRewarded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      tags: tags ?? this.tags,
      milestones: milestones ?? this.milestones,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'status': status.name,
        'difficulty': difficulty.name,
        'targetValue': targetValue,
        'currentProgress': currentProgress,
        'progressPercentage': progressPercentage,
        'routineId': routineId,
        'categoryId': categoryId,
        'routineIds': routineIds,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'completedDate': completedDate?.toIso8601String(),
        'rewardDescription': rewardDescription,
        'rewardIconCodePoint': rewardIcon?.codePoint,
        'rewardIconFontFamily': rewardIcon?.fontFamily,
        'isRewarded': isRewarded,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'userId': userId,
        'tags': tags,
        'milestones': milestones.map((m) => m.toJson()).toList(),
      };

  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        type: GoalType.values.firstWhere((e) => e.name == json['type']),
        status: GoalStatus.values.firstWhere((e) => e.name == json['status']),
        difficulty: GoalDifficulty.values
            .firstWhere((e) => e.name == json['difficulty']),
        targetValue: json['targetValue'],
        currentProgress: json['currentProgress'],
        progressPercentage: json['progressPercentage']?.toDouble() ?? 0.0,
        routineId: json['routineId'],
        categoryId: json['categoryId'],
        routineIds: List<String>.from(json['routineIds'] ?? []),
        startDate: DateTime.parse(json['startDate']),
        endDate:
            json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        completedDate: json['completedDate'] != null
            ? DateTime.parse(json['completedDate'])
            : null,
        rewardDescription: json['rewardDescription'],
        rewardIcon: json['rewardIconCodePoint'] != null
            ? IconData(
                json['rewardIconCodePoint'],
                fontFamily: json['rewardIconFontFamily'],
              )
            : null,
        isRewarded: json['isRewarded'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
        userId: json['userId'],
        tags: List<String>.from(json['tags'] ?? []),
        milestones: (json['milestones'] as List<dynamic>?)
                ?.map((m) => Milestone.fromJson(Map<String, dynamic>.from(m)))
                .toList() ??
            [],
      );

  // Helper Methods
  bool get isCompleted => status == GoalStatus.completed;
  bool get isActive => status == GoalStatus.active;
  bool get isFailed => status == GoalStatus.failed;
  bool get isExpired => status == GoalStatus.expired;

  bool get hasDeadline => endDate != null;
  bool get isOverdue =>
      hasDeadline && endDate!.isBefore(DateTime.now()) && !isCompleted;

  Duration? get timeRemaining =>
      hasDeadline ? endDate!.difference(DateTime.now()) : null;
  int? get daysRemaining => timeRemaining?.inDays;

  // Progress calculations
  bool get isNearCompletion => progressPercentage >= 80;
  bool get isHalfway => progressPercentage >= 50;

  // Milestone helpers
  List<Milestone> get completedMilestones =>
      milestones.where((m) => m.isCompleted).toList();
  List<Milestone> get pendingMilestones =>
      milestones.where((m) => !m.isCompleted).toList();
  Milestone? get nextMilestone =>
      pendingMilestones.isNotEmpty ? pendingMilestones.first : null;

  // Difficulty helpers
  Color get difficultyColor {
    switch (difficulty) {
      case GoalDifficulty.easy:
        return Colors.green;
      case GoalDifficulty.medium:
        return Colors.orange;
      case GoalDifficulty.hard:
        return Colors.red;
      case GoalDifficulty.extreme:
        return Colors.purple;
    }
  }

  String get difficultyName {
    switch (difficulty) {
      case GoalDifficulty.easy:
        return 'Kolay';
      case GoalDifficulty.medium:
        return 'Orta';
      case GoalDifficulty.hard:
        return 'Zor';
      case GoalDifficulty.extreme:
        return 'Aşırı Zor';
    }
  }

  // Type helpers
  String get typeName {
    switch (type) {
      case GoalType.dailyStreak:
        return 'Günlük Seri';
      case GoalType.weeklyCount:
        return 'Haftalık Sayım';
      case GoalType.monthlyCount:
        return 'Aylık Sayım';
      case GoalType.customPeriod:
        return 'Özel Dönem';
      case GoalType.totalCount:
        return 'Toplam Sayım';
    }
  }

  String get typeDescription {
    switch (type) {
      case GoalType.dailyStreak:
        return '$targetValue gün üst üste';
      case GoalType.weeklyCount:
        return 'Haftada $targetValue kez';
      case GoalType.monthlyCount:
        return 'Ayda $targetValue kez';
      case GoalType.customPeriod:
        return '$targetValue kez (${_formatDateRange()})';
      case GoalType.totalCount:
        return 'Toplam $targetValue kez';
    }
  }

  String _formatDateRange() {
    if (!hasDeadline) return 'Süresiz';
    final start = '${startDate.day}/${startDate.month}';
    final end = '${endDate!.day}/${endDate!.month}';
    return '$start - $end';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'GoalModel(id: $id, name: $name, progress: $currentProgress/$targetValue)';
}

// Milestone Model for tracking intermediate goals
class Milestone {
  final String id;
  final String name;
  final String description;
  final int targetValue; // Bu milestone için hedef değer
  final int currentProgress; // Bu milestone için mevcut ilerleme
  final bool isCompleted;
  final DateTime? completedDate;
  final DateTime createdAt;
  final IconData? icon;
  final String? rewardDescription;

  const Milestone({
    required this.id,
    required this.name,
    required this.description,
    required this.targetValue,
    required this.currentProgress,
    required this.isCompleted,
    this.completedDate,
    required this.createdAt,
    this.icon,
    this.rewardDescription,
  });

  Milestone copyWith({
    String? id,
    String? name,
    String? description,
    int? targetValue,
    int? currentProgress,
    bool? isCompleted,
    DateTime? completedDate,
    DateTime? createdAt,
    IconData? icon,
    String? rewardDescription,
  }) {
    return Milestone(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      createdAt: createdAt ?? this.createdAt,
      icon: icon ?? this.icon,
      rewardDescription: rewardDescription ?? this.rewardDescription,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'targetValue': targetValue,
        'currentProgress': currentProgress,
        'isCompleted': isCompleted,
        'completedDate': completedDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'iconCodePoint': icon?.codePoint,
        'iconFontFamily': icon?.fontFamily,
        'rewardDescription': rewardDescription,
      };

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        targetValue: json['targetValue'],
        currentProgress: json['currentProgress'],
        isCompleted: json['isCompleted'],
        completedDate: json['completedDate'] != null
            ? DateTime.parse(json['completedDate'])
            : null,
        createdAt: DateTime.parse(json['createdAt']),
        icon: json['iconCodePoint'] != null
            ? IconData(
                json['iconCodePoint'],
                fontFamily: json['iconFontFamily'],
              )
            : null,
        rewardDescription: json['rewardDescription'],
      );

  double get progressPercentage =>
      targetValue > 0 ? (currentProgress / targetValue) * 100 : 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Milestone && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Predefined Goal Templates
class GoalTemplates {
  static const List<GoalTemplate> templates = [
    // Daily Streak Goals
    GoalTemplate(
      name: '7 Günlük Seri',
      description: '7 gün üst üste rutin tamamla',
      type: GoalType.dailyStreak,
      targetValue: 7,
      difficulty: GoalDifficulty.easy,
      icon: Icons.local_fire_department,
      rewardDescription: 'İlk seri ödülün!',
    ),
    GoalTemplate(
      name: '30 Günlük Challenge',
      description: '30 gün üst üste rutin tamamla',
      type: GoalType.dailyStreak,
      targetValue: 30,
      difficulty: GoalDifficulty.medium,
      icon: Icons.emoji_events,
      rewardDescription: 'Aylık seri ustası!',
    ),
    GoalTemplate(
      name: '100 Gün Disiplin',
      description: '100 gün üst üste rutin tamamla',
      type: GoalType.dailyStreak,
      targetValue: 100,
      difficulty: GoalDifficulty.hard,
      icon: Icons.military_tech,
      rewardDescription: 'Disiplin ustası unvanı!',
    ),

    // Weekly Goals
    GoalTemplate(
      name: 'Haftalık 5 Kez',
      description: 'Haftada 5 kez rutini tamamla',
      type: GoalType.weeklyCount,
      targetValue: 5,
      difficulty: GoalDifficulty.medium,
      icon: Icons.calendar_view_week,
      rewardDescription: 'Haftalık hedef tamamlandı!',
    ),

    // Monthly Goals
    GoalTemplate(
      name: 'Aylık 20 Kez',
      description: 'Ayda 20 kez rutini tamamla',
      type: GoalType.monthlyCount,
      targetValue: 20,
      difficulty: GoalDifficulty.medium,
      icon: Icons.calendar_month,
      rewardDescription: 'Aylık hedef şampiyonu!',
    ),

    // Total Count Goals
    GoalTemplate(
      name: 'İlk 10 Kez',
      description: 'Toplamda 10 kez rutin tamamla',
      type: GoalType.totalCount,
      targetValue: 10,
      difficulty: GoalDifficulty.easy,
      icon: Icons.star,
      rewardDescription: 'İlk adımlar tamamlandı!',
    ),
    GoalTemplate(
      name: '100 Kez Milestone',
      description: 'Toplamda 100 kez rutin tamamla',
      type: GoalType.totalCount,
      targetValue: 100,
      difficulty: GoalDifficulty.hard,
      icon: Icons.workspace_premium,
      rewardDescription: 'Yüzlü kulüp üyesi!',
    ),
  ];

  static GoalModel createFromTemplate(
    GoalTemplate template, {
    String? routineId,
    String? categoryId,
    List<String>? routineIds,
    String? userId,
    DateTime? customEndDate,
  }) {
    final now = DateTime.now();
    DateTime? endDate;

    // Calculate end date based on goal type
    switch (template.type) {
      case GoalType.dailyStreak:
        endDate = now.add(
            Duration(days: template.targetValue + 7)); // Extra 7 days buffer
        break;
      case GoalType.weeklyCount:
        endDate = now.add(const Duration(days: 7));
        break;
      case GoalType.monthlyCount:
        endDate = now.add(const Duration(days: 30));
        break;
      case GoalType.customPeriod:
        endDate = customEndDate;
        break;
      case GoalType.totalCount:
        endDate = null; // No deadline
        break;
    }

    return GoalModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: template.name,
      description: template.description,
      type: template.type,
      status: GoalStatus.active,
      difficulty: template.difficulty,
      targetValue: template.targetValue,
      currentProgress: 0,
      progressPercentage: 0,
      routineId: routineId,
      categoryId: categoryId,
      routineIds: routineIds ?? [],
      startDate: now,
      endDate: endDate,
      rewardDescription: template.rewardDescription,
      rewardIcon: template.icon,
      createdAt: now,
      userId: userId,
      milestones: _generateMilestones(template),
    );
  }

  static List<Milestone> _generateMilestones(GoalTemplate template) {
    final milestones = <Milestone>[];
    final now = DateTime.now();

    // Generate milestones based on target value
    if (template.targetValue >= 10) {
      // 25%, 50%, 75% milestones for larger goals
      final quarter = (template.targetValue * 0.25).round();
      final half = (template.targetValue * 0.5).round();
      final threeQuarter = (template.targetValue * 0.75).round();

      if (quarter > 0) {
        milestones.add(Milestone(
          id: '${now.millisecondsSinceEpoch}_25',
          name: 'İlk Adım',
          description: '$quarter/${template.targetValue} tamamlandı',
          targetValue: quarter,
          currentProgress: 0,
          isCompleted: false,
          createdAt: now,
          icon: Icons.play_arrow,
          rewardDescription: 'Güzel başlangıç!',
        ));
      }

      milestones.add(Milestone(
        id: '${now.millisecondsSinceEpoch}_50',
        name: 'Yarı Yol',
        description: '$half/${template.targetValue} tamamlandı',
        targetValue: half,
        currentProgress: 0,
        isCompleted: false,
        createdAt: now,
        icon: Icons.timeline,
        rewardDescription: 'Yarı yolda!',
      ));

      milestones.add(Milestone(
        id: '${now.millisecondsSinceEpoch}_75',
        name: 'Son Dönemece',
        description: '$threeQuarter/${template.targetValue} tamamlandı',
        targetValue: threeQuarter,
        currentProgress: 0,
        isCompleted: false,
        createdAt: now,
        icon: Icons.trending_up,
        rewardDescription: 'Neredeyse bitti!',
      ));
    }

    return milestones;
  }
}

class GoalTemplate {
  final String name;
  final String description;
  final GoalType type;
  final int targetValue;
  final GoalDifficulty difficulty;
  final IconData icon;
  final String rewardDescription;

  const GoalTemplate({
    required this.name,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.difficulty,
    required this.icon,
    required this.rewardDescription,
  });
}
