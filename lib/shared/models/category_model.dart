import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String? userId;
  final int routineCount; // Cached count of routines in this category

  const CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.userId,
    this.routineCount = 0,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? userId,
    int? routineCount,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
      routineCount: routineCount ?? this.routineCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'iconCodePoint': icon.codePoint,
        'iconFontFamily': icon.fontFamily,
        'colorValue': color.value,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'isActive': isActive,
        'userId': userId,
        'routineCount': routineCount,
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'],
        name: json['name'],
        description: json['description'] ?? '',
        icon: IconData(
          json['iconCodePoint'] ?? Icons.category.codePoint,
          fontFamily: json['iconFontFamily'] ?? Icons.category.fontFamily,
        ),
        color: Color(json['colorValue'] ?? Colors.blue.value),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
        isActive: json['isActive'] ?? true,
        userId: json['userId'],
        routineCount: json['routineCount'] ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CategoryModel(id: $id, name: $name, routineCount: $routineCount)';
}

// Predefined category templates
class CategoryTemplates {
  static const List<CategoryTemplate> templates = [
    CategoryTemplate(
      name: 'Sağlık',
      description: 'Fiziksel ve mental sağlık rutinleri',
      icon: Icons.health_and_safety,
      color: Colors.green,
    ),
    CategoryTemplate(
      name: 'Egzersiz',
      description: 'Spor ve fitness aktiviteleri',
      icon: Icons.fitness_center,
      color: Colors.orange,
    ),
    CategoryTemplate(
      name: 'Eğitim',
      description: 'Öğrenme ve gelişim rutinleri',
      icon: Icons.school,
      color: Colors.blue,
    ),
    CategoryTemplate(
      name: 'İş/Kariyer',
      description: 'Profesyonel gelişim rutinleri',
      icon: Icons.work,
      color: Colors.indigo,
    ),
    CategoryTemplate(
      name: 'Kişisel Bakım',
      description: 'Günlük bakım ve hijyen rutinleri',
      icon: Icons.self_improvement,
      color: Colors.pink,
    ),
    CategoryTemplate(
      name: 'Hobi',
      description: 'Eğlence ve yaratıcı aktiviteler',
      icon: Icons.palette,
      color: Colors.purple,
    ),
    CategoryTemplate(
      name: 'Sosyal',
      description: 'İlişkiler ve sosyal aktiviteler',
      icon: Icons.people,
      color: Colors.teal,
    ),
    CategoryTemplate(
      name: 'Ev İşleri',
      description: 'Temizlik ve düzen rutinleri',
      icon: Icons.home,
      color: Colors.brown,
    ),
    CategoryTemplate(
      name: 'Finans',
      description: 'Para yönetimi ve tasarruf',
      icon: Icons.attach_money,
      color: Colors.amber,
    ),
    CategoryTemplate(
      name: 'Teknoloji',
      description: 'Dijital detoks ve teknoloji kullanımı',
      icon: Icons.devices,
      color: Colors.cyan,
    ),
  ];

  static CategoryModel createFromTemplate(
      CategoryTemplate template, String userId) {
    return CategoryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: template.name,
      description: template.description,
      icon: template.icon,
      color: template.color,
      createdAt: DateTime.now(),
      userId: userId,
    );
  }
}

class CategoryTemplate {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const CategoryTemplate({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// Default category for uncategorized routines
class DefaultCategory {
  static CategoryModel get uncategorized => CategoryModel(
        id: 'default_uncategorized',
        name: 'Kategorisiz',
        description: 'Henüz kategorize edilmemiş rutinler',
        icon: Icons.category,
        color: Colors.grey,
        createdAt: DateTime.now(),
      );
}
