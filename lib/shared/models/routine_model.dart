// Simple model class for now, will be converted to freezed later
class RoutineModel {
  final String id;
  final String name;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? lastCompletedAt;
  final List<DateTime> completionHistory;
  final String? description;
  final CustomTimeOfDay? reminderTime;
  final bool isActive;
  final String? userId;
  final String? categoryId; // Reference to CategoryModel

  const RoutineModel({
    required this.id,
    required this.name,
    required this.isCompleted,
    required this.createdAt,
    this.lastCompletedAt,
    this.completionHistory = const [],
    this.description,
    this.reminderTime,
    this.isActive = true,
    this.userId,
    this.categoryId,
  });

  RoutineModel copyWith({
    String? id,
    String? name,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? lastCompletedAt,
    List<DateTime>? completionHistory,
    String? description,
    CustomTimeOfDay? reminderTime,
    bool? isActive,
    String? userId,
    String? categoryId,
  }) {
    return RoutineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      completionHistory: completionHistory ?? this.completionHistory,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'lastCompletedAt': lastCompletedAt?.toIso8601String(),
        'completionHistory':
            completionHistory.map((e) => e.toIso8601String()).toList(),
        'description': description,
        'reminderTime': reminderTime?.toJson(),
        'isActive': isActive,
        'userId': userId,
        'categoryId': categoryId,
      };

  factory RoutineModel.fromJson(Map<String, dynamic> json) => RoutineModel(
        id: json['id'],
        name: json['name'],
        isCompleted: json['isCompleted'],
        createdAt: DateTime.parse(json['createdAt']),
        lastCompletedAt: json['lastCompletedAt'] != null
            ? DateTime.parse(json['lastCompletedAt'])
            : null,
        completionHistory: (json['completionHistory'] as List<dynamic>?)
                ?.map((e) => DateTime.parse(e))
                .toList() ??
            [],
        description: json['description'],
        reminderTime: json['reminderTime'] != null
            ? CustomTimeOfDay.fromJson(json['reminderTime'])
            : null,
        isActive: json['isActive'] ?? true,
        userId: json['userId'],
        categoryId: json['categoryId'],
      );
}

class CustomTimeOfDay {
  final int hour;
  final int minute;

  const CustomTimeOfDay({required this.hour, required this.minute});

  Map<String, dynamic> toJson() => {'hour': hour, 'minute': minute};

  factory CustomTimeOfDay.fromJson(Map<String, dynamic> json) =>
      CustomTimeOfDay(hour: json['hour'], minute: json['minute']);
}
