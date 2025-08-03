import 'dart:convert';
import 'package:logger/logger.dart';

import '../models/routine_model.dart';
import '../models/goal_model.dart';
import '../models/category_model.dart';
import '../models/achievement_model.dart';
import '../../features/routine_management/data/repositories/routine_repository.dart';
import '../../features/goal_management/data/repositories/goal_repository.dart';
import '../../features/category_management/data/repositories/category_repository.dart';
import '../../features/achievement_system/data/repositories/achievement_repository.dart';
import '../../features/achievement_system/domain/entities/user_progress.dart';

enum SimpleExportFormat { json }

enum SimpleExportDataType { all, routines, goals, categories, achievements }

class SimpleExportData {
  final List<RoutineModel> routines;
  final List<GoalModel> goals;
  final List<CategoryModel> categories;
  final List<AchievementModel> achievements;
  final UserProgress? userProgress;
  final Map<String, dynamic> metadata;

  const SimpleExportData({
    required this.routines,
    required this.goals,
    required this.categories,
    required this.achievements,
    this.userProgress,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'metadata': metadata,
        'routines': routines.map((r) => r.toJson()).toList(),
        'goals': goals.map((g) => g.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'achievements': achievements.map((a) => a.toJson()).toList(),
        'userProgress': userProgress?.toJson(),
      };

  factory SimpleExportData.fromJson(Map<String, dynamic> json) {
    return SimpleExportData(
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      routines: (json['routines'] as List<dynamic>? ?? [])
          .map((r) => RoutineModel.fromJson(Map<String, dynamic>.from(r)))
          .toList(),
      goals: (json['goals'] as List<dynamic>? ?? [])
          .map((g) => GoalModel.fromJson(Map<String, dynamic>.from(g)))
          .toList(),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((c) => CategoryModel.fromJson(Map<String, dynamic>.from(c)))
          .toList(),
      achievements: (json['achievements'] as List<dynamic>? ?? [])
          .map((a) => AchievementModel.fromJson(Map<String, dynamic>.from(a)))
          .toList(),
      userProgress: json['userProgress'] != null
          ? UserProgress.fromJson(
              Map<String, dynamic>.from(json['userProgress']))
          : null,
    );
  }
}

class SimpleImportResult {
  final bool success;
  final String message;
  final int importedRoutines;
  final int importedGoals;
  final int importedCategories;
  final int importedAchievements;
  final List<String> errors;

  const SimpleImportResult({
    required this.success,
    required this.message,
    this.importedRoutines = 0,
    this.importedGoals = 0,
    this.importedCategories = 0,
    this.importedAchievements = 0,
    this.errors = const [],
  });
}

class SimpleDataExportService {
  final Logger _logger = Logger();
  final RoutineRepository _routineRepository;
  final GoalRepository _goalRepository;
  final CategoryRepository _categoryRepository;
  final AchievementRepository _achievementRepository;

  SimpleDataExportService({
    required RoutineRepository routineRepository,
    required GoalRepository goalRepository,
    required CategoryRepository categoryRepository,
    required AchievementRepository achievementRepository,
  })  : _routineRepository = routineRepository,
        _goalRepository = goalRepository,
        _categoryRepository = categoryRepository,
        _achievementRepository = achievementRepository;

  // ==================== Export Methods ====================

  /// Export data to JSON format
  Future<String> exportToJson({
    SimpleExportDataType dataType = SimpleExportDataType.all,
    bool includeUserProgress = true,
  }) async {
    try {
      final exportData =
          await _collectExportData(dataType, includeUserProgress);
      final jsonString =
          const JsonEncoder.withIndent('  ').convert(exportData.toJson());

      _logger.i('Data exported to JSON successfully');
      return jsonString;
    } catch (e) {
      _logger.e('Error exporting to JSON: $e');
      rethrow;
    }
  }

  /// Export and get content for sharing
  Future<String> exportForSharing({
    SimpleExportDataType dataType = SimpleExportDataType.all,
    bool includeUserProgress = true,
  }) async {
    return await exportToJson(
      dataType: dataType,
      includeUserProgress: includeUserProgress,
    );
  }

  // ==================== Import Methods ====================

  /// Import data from JSON string
  Future<SimpleImportResult> importFromJson(String jsonString) async {
    try {
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final exportData = SimpleExportData.fromJson(jsonData);

      return await _importExportData(exportData);
    } catch (e) {
      _logger.e('Error importing from JSON: $e');
      return SimpleImportResult(
        success: false,
        message: 'JSON parse hatası: $e',
        errors: [e.toString()],
      );
    }
  }

  // ==================== Private Methods ====================

  Future<SimpleExportData> _collectExportData(
    SimpleExportDataType dataType,
    bool includeUserProgress,
  ) async {
    List<RoutineModel> routines = [];
    List<GoalModel> goals = [];
    List<CategoryModel> categories = [];
    List<AchievementModel> achievements = [];
    UserProgress? userProgress;

    // Initialize repositories
    _routineRepository.initialize();
    await _goalRepository.initialize();
    _categoryRepository.initialize();
    await _achievementRepository.initialize();

    switch (dataType) {
      case SimpleExportDataType.all:
        routines = await _routineRepository.getAllRoutines();
        goals = await _goalRepository.getAllGoals();
        categories = await _categoryRepository.getAllCategories();
        achievements = await _achievementRepository.getAllAchievements();
        if (includeUserProgress) {
          userProgress = await _achievementRepository.getUserProgress();
        }
        break;
      case SimpleExportDataType.routines:
        routines = await _routineRepository.getAllRoutines();
        break;
      case SimpleExportDataType.goals:
        goals = await _goalRepository.getAllGoals();
        break;
      case SimpleExportDataType.categories:
        categories = await _categoryRepository.getAllCategories();
        break;
      case SimpleExportDataType.achievements:
        achievements = await _achievementRepository.getAllAchievements();
        if (includeUserProgress) {
          userProgress = await _achievementRepository.getUserProgress();
        }
        break;
    }

    final metadata = {
      'exportDate': DateTime.now().toIso8601String(),
      'exportType': dataType.name,
      'appVersion': '1.0.0',
      'totalItems': {
        'routines': routines.length,
        'goals': goals.length,
        'categories': categories.length,
        'achievements': achievements.length,
      },
    };

    return SimpleExportData(
      routines: routines,
      goals: goals,
      categories: categories,
      achievements: achievements,
      userProgress: userProgress,
      metadata: metadata,
    );
  }

  Future<SimpleImportResult> _importExportData(
      SimpleExportData exportData) async {
    final errors = <String>[];
    int importedRoutines = 0;
    int importedGoals = 0;
    int importedCategories = 0;
    int importedAchievements = 0;

    try {
      // Initialize repositories
      _routineRepository.initialize();
      await _goalRepository.initialize();
      _categoryRepository.initialize();
      await _achievementRepository.initialize();

      // Import categories first (they're dependencies)
      for (final category in exportData.categories) {
        try {
          // Check if category already exists
          final existingCategories =
              await _categoryRepository.getAllCategories();
          final exists = existingCategories.any((c) => c.id == category.id);

          if (!exists) {
            await _categoryRepository.createCategory(category);
            importedCategories++;
          }
        } catch (e) {
          errors.add('Kategori import hatası (${category.name}): $e');
        }
      }

      // Import routines
      for (final routine in exportData.routines) {
        try {
          // Check if routine already exists
          final existingRoutines = await _routineRepository.getAllRoutines();
          final exists = existingRoutines.any((r) => r.id == routine.id);

          if (!exists) {
            await _routineRepository.createRoutine(routine);
            importedRoutines++;
          }
        } catch (e) {
          errors.add('Rutin import hatası (${routine.name}): $e');
        }
      }

      // Import goals
      for (final goal in exportData.goals) {
        try {
          // Check if goal already exists
          final existingGoals = await _goalRepository.getAllGoals();
          final exists = existingGoals.any((g) => g.id == goal.id);

          if (!exists) {
            await _goalRepository.createGoal(goal);
            importedGoals++;
          }
        } catch (e) {
          errors.add('Hedef import hatası (${goal.title}): $e');
        }
      }

      // Import achievements
      for (final achievement in exportData.achievements) {
        try {
          // Check if achievement already exists
          final existingAchievements =
              await _achievementRepository.getAllAchievements();
          final exists =
              existingAchievements.any((a) => a.id == achievement.id);

          if (!exists) {
            await _achievementRepository.createAchievement(achievement);
            importedAchievements++;
          }
        } catch (e) {
          errors.add('Başarım import hatası (${achievement.title}): $e');
        }
      }

      final totalImported = importedRoutines +
          importedGoals +
          importedCategories +
          importedAchievements;

      return SimpleImportResult(
        success: totalImported > 0,
        message: totalImported > 0
            ? 'Başarıyla import edildi: $totalImported öğe'
            : 'Hiçbir yeni öğe import edilmedi',
        importedRoutines: importedRoutines,
        importedGoals: importedGoals,
        importedCategories: importedCategories,
        importedAchievements: importedAchievements,
        errors: errors,
      );
    } catch (e) {
      _logger.e('Import error: $e');
      return SimpleImportResult(
        success: false,
        message: 'Import sırasında hata oluştu: $e',
        errors: [...errors, e.toString()],
      );
    }
  }

  // ==================== Utility Methods ====================

  /// Get estimated export file size
  Future<int> getEstimatedExportSize({
    SimpleExportDataType dataType = SimpleExportDataType.all,
  }) async {
    try {
      final content = await exportToJson(dataType: dataType);
      return content.length;
    } catch (e) {
      _logger.e('Error estimating export size: $e');
      return 0;
    }
  }

  /// Validate export data before import
  bool validateExportData(Map<String, dynamic> jsonData) {
    try {
      // Check required fields
      if (!jsonData.containsKey('metadata')) return false;

      final metadata = jsonData['metadata'] as Map<String, dynamic>;
      if (!metadata.containsKey('exportDate')) return false;
      if (!metadata.containsKey('exportType')) return false;

      // Validate data structure
      SimpleExportData.fromJson(jsonData);
      return true;
    } catch (e) {
      _logger.e('Export data validation failed: $e');
      return false;
    }
  }

  /// Get export summary statistics
  Future<Map<String, int>> getExportSummary({
    SimpleExportDataType dataType = SimpleExportDataType.all,
  }) async {
    try {
      final exportData = await _collectExportData(dataType, false);
      return {
        'routines': exportData.routines.length,
        'goals': exportData.goals.length,
        'categories': exportData.categories.length,
        'achievements': exportData.achievements.length,
      };
    } catch (e) {
      _logger.e('Error getting export summary: $e');
      return {
        'routines': 0,
        'goals': 0,
        'categories': 0,
        'achievements': 0,
      };
    }
  }
}
