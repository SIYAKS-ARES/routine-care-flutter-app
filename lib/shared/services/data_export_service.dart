import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
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
import '../../features/achievement_system/domain/entities/achievement_statistics.dart';

enum ExportFormat { json, csv }

enum ExportDataType {
  all,
  routines,
  goals,
  categories,
  achievements,
  userProgress
}

class ExportData {
  final List<RoutineModel> routines;
  final List<GoalModel> goals;
  final List<CategoryModel> categories;
  final List<AchievementModel> achievements;
  final UserProgress? userProgress;
  final Map<String, dynamic> metadata;

  const ExportData({
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

  factory ExportData.fromJson(Map<String, dynamic> json) {
    return ExportData(
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

class ImportResult {
  final bool success;
  final String message;
  final int importedRoutines;
  final int importedGoals;
  final int importedCategories;
  final int importedAchievements;
  final List<String> errors;

  const ImportResult({
    required this.success,
    required this.message,
    this.importedRoutines = 0,
    this.importedGoals = 0,
    this.importedCategories = 0,
    this.importedAchievements = 0,
    this.errors = const [],
  });
}

class DataExportService {
  final Logger _logger = Logger();
  final RoutineRepository _routineRepository;
  final GoalRepository _goalRepository;
  final CategoryRepository _categoryRepository;
  final AchievementRepository _achievementRepository;

  DataExportService({
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
    ExportDataType dataType = ExportDataType.all,
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

  /// Export data to CSV format
  Future<String> exportToCsv({
    ExportDataType dataType = ExportDataType.routines,
  }) async {
    try {
      String csvContent;

      switch (dataType) {
        case ExportDataType.routines:
          csvContent = await _exportRoutinesToCsv();
          break;
        case ExportDataType.goals:
          csvContent = await _exportGoalsToCsv();
          break;
        case ExportDataType.categories:
          csvContent = await _exportCategoriesToCsv();
          break;
        case ExportDataType.achievements:
          csvContent = await _exportAchievementsToCsv();
          break;
        default:
          throw Exception('CSV export sadece tek veri türü için desteklenir');
      }

      _logger.i('Data exported to CSV successfully');
      return csvContent;
    } catch (e) {
      _logger.e('Error exporting to CSV: $e');
      rethrow;
    }
  }

  /// Export and save to file
  Future<File> exportToFile({
    required ExportFormat format,
    ExportDataType dataType = ExportDataType.all,
    bool includeUserProgress = true,
    String? customFilename,
  }) async {
    try {
      // Request permissions
      await _requestStoragePermission();

      // Generate content
      String content;
      String extension;

      switch (format) {
        case ExportFormat.json:
          content = await exportToJson(
            dataType: dataType,
            includeUserProgress: includeUserProgress,
          );
          extension = 'json';
          break;
        case ExportFormat.csv:
          content = await exportToCsv(dataType: dataType);
          extension = 'csv';
          break;
      }

      // Generate filename
      final timestamp =
          DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-');
      final filename =
          customFilename ?? 'routine_care_export_$timestamp.$extension';

      // Get downloads directory
      final directory = await getExternalStorageDirectory();
      final downloadsDirectory =
          Directory('${directory!.parent.parent.parent.parent.path}/Download');

      if (!await downloadsDirectory.exists()) {
        await downloadsDirectory.create(recursive: true);
      }

      // Write file
      final file = File('${downloadsDirectory.path}/$filename');
      await file.writeAsString(content);

      _logger.i('Data exported to file: ${file.path}');
      return file;
    } catch (e) {
      _logger.e('Error exporting to file: $e');
      rethrow;
    }
  }

  /// Export and share
  Future<void> exportAndShare({
    required ExportFormat format,
    ExportDataType dataType = ExportDataType.all,
    bool includeUserProgress = true,
  }) async {
    try {
      final file = await exportToFile(
        format: format,
        dataType: dataType,
        includeUserProgress: includeUserProgress,
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Routine Care veri dışa aktarımı',
        subject: 'Verilerim - ${DateTime.now().toString().split(' ')[0]}',
      );

      _logger.i('Data shared successfully');
    } catch (e) {
      _logger.e('Error sharing data: $e');
      rethrow;
    }
  }

  // ==================== Import Methods ====================

  /// Import data from JSON string
  Future<ImportResult> importFromJson(String jsonString) async {
    try {
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final exportData = ExportData.fromJson(jsonData);

      return await _importExportData(exportData);
    } catch (e) {
      _logger.e('Error importing from JSON: $e');
      return ImportResult(
        success: false,
        message: 'JSON parse hatası: $e',
        errors: [e.toString()],
      );
    }
  }

  /// Import data from file
  Future<ImportResult> importFromFile(File file) async {
    try {
      final content = await file.readAsString();
      final extension = file.path.split('.').last.toLowerCase();

      switch (extension) {
        case 'json':
          return await importFromJson(content);
        case 'csv':
          return await _importFromCsv(content, file.path);
        default:
          throw Exception('Desteklenmeyen dosya formatı: $extension');
      }
    } catch (e) {
      _logger.e('Error importing from file: $e');
      return ImportResult(
        success: false,
        message: 'Dosya okuma hatası: $e',
        errors: [e.toString()],
      );
    }
  }

  // ==================== Private Methods ====================

  Future<ExportData> _collectExportData(
    ExportDataType dataType,
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
      case ExportDataType.all:
        routines = await _routineRepository.getAllRoutines();
        goals = await _goalRepository.getAllGoals();
        categories = await _categoryRepository.getAllCategories();
        achievements = await _achievementRepository.getAllAchievements();
        if (includeUserProgress) {
          userProgress = await _achievementRepository.getUserProgress();
        }
        break;
      case ExportDataType.routines:
        routines = await _routineRepository.getAllRoutines();
        break;
      case ExportDataType.goals:
        goals = await _goalRepository.getAllGoals();
        break;
      case ExportDataType.categories:
        categories = await _categoryRepository.getAllCategories();
        break;
      case ExportDataType.achievements:
        achievements = await _achievementRepository.getAllAchievements();
        if (includeUserProgress) {
          userProgress = await _achievementRepository.getUserProgress();
        }
        break;
      case ExportDataType.userProgress:
        if (includeUserProgress) {
          userProgress = await _achievementRepository.getUserProgress();
        }
        break;
    }

    final metadata = {
      'exportDate': DateTime.now().toIso8601String(),
      'exportType': dataType.name,
      'appVersion': '1.0.0', // TODO: Get from package info
      'totalItems': {
        'routines': routines.length,
        'goals': goals.length,
        'categories': categories.length,
        'achievements': achievements.length,
      },
    };

    return ExportData(
      routines: routines,
      goals: goals,
      categories: categories,
      achievements: achievements,
      userProgress: userProgress,
      metadata: metadata,
    );
  }

  Future<String> _exportRoutinesToCsv() async {
    _routineRepository.initialize();
    final routines = await _routineRepository.getAllRoutines();

    final headers = [
      'ID',
      'İsim',
      'Açıklama',
      'Kategori ID',
      'Hedef Gün Sayısı',
      'Oluşturulma Tarihi',
      'Aktif',
      'Renk',
      'İkon',
      'Hatırlatıcı Zamanı',
      'Tamamlanma Sayısı',
      'En Uzun Seri',
    ];

    final rows = routines
        .map((routine) => [
              routine.id,
              routine.name,
              routine.description,
              routine.categoryId,
              routine.goalDays.toString(),
              routine.createdAt.toIso8601String(),
              routine.isActive.toString(),
              routine.color.value.toString(),
              routine.icon.codePoint.toString(),
              routine.reminderTime?.toIso8601String() ?? '',
              routine.completedDays.length.toString(),
              routine.longestStreak.toString(),
            ])
        .toList();

    return const ListToCsvConverter().convert([headers, ...rows]);
  }

  Future<String> _exportGoalsToCsv() async {
    await _goalRepository.initialize();
    final goals = await _goalRepository.getAllGoals();

    final headers = [
      'ID',
      'Başlık',
      'Açıklama',
      'Hedef Tür',
      'Zorluk',
      'Kategori ID',
      'Rutin ID',
      'Başlangıç Tarihi',
      'Bitiş Tarihi',
      'Hedef Değer',
      'Mevcut İlerleme',
      'Durum',
      'Oluşturulma Tarihi',
    ];

    final rows = goals
        .map((goal) => [
              goal.id,
              goal.title,
              goal.description,
              goal.type.name,
              goal.difficulty.name,
              goal.categoryId ?? '',
              goal.routineId ?? '',
              goal.startDate.toIso8601String(),
              goal.endDate.toIso8601String(),
              goal.targetValue.toString(),
              goal.currentProgress.toString(),
              goal.status.name,
              goal.createdAt.toIso8601String(),
            ])
        .toList();

    return const ListToCsvConverter().convert([headers, ...rows]);
  }

  Future<String> _exportCategoriesToCsv() async {
    _categoryRepository.initialize();
    final categories = await _categoryRepository.getAllCategories();

    final headers = [
      'ID',
      'İsim',
      'Açıklama',
      'Renk',
      'İkon',
      'Oluşturulma Tarihi',
      'Rutin Sayısı',
    ];

    final rows = categories
        .map((category) => [
              category.id,
              category.name,
              category.description ?? '',
              category.color.value.toString(),
              category.icon.codePoint.toString(),
              category.createdAt.toIso8601String(),
              category.routineCount.toString(),
            ])
        .toList();

    return const ListToCsvConverter().convert([headers, ...rows]);
  }

  Future<String> _exportAchievementsToCsv() async {
    await _achievementRepository.initialize();
    final achievements = await _achievementRepository.getAllAchievements();

    final headers = [
      'ID',
      'Başlık',
      'Açıklama',
      'Tür',
      'Nadirlk',
      'Açıldı',
      'Açılma Tarihi',
      'Mevcut İlerleme',
      'Deneyim Puanı',
      'Gizli',
      'Oluşturulma Tarihi',
    ];

    final rows = achievements
        .map((achievement) => [
              achievement.id,
              achievement.title,
              achievement.description,
              achievement.type.name,
              achievement.rarity.name,
              achievement.isUnlocked.toString(),
              achievement.unlockedAt?.toIso8601String() ?? '',
              achievement.currentProgress.toString(),
              achievement.experiencePoints.toString(),
              achievement.isHidden.toString(),
              achievement.createdAt.toIso8601String(),
            ])
        .toList();

    return const ListToCsvConverter().convert([headers, ...rows]);
  }

  Future<ImportResult> _importExportData(ExportData exportData) async {
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

      return ImportResult(
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
      return ImportResult(
        success: false,
        message: 'Import sırasında hata oluştu: $e',
        errors: [...errors, e.toString()],
      );
    }
  }

  Future<ImportResult> _importFromCsv(
      String csvContent, String filePath) async {
    try {
      final filename = filePath.split('/').last.toLowerCase();

      if (filename.contains('routine')) {
        return await _importRoutinesFromCsv(csvContent);
      } else if (filename.contains('goal')) {
        return await _importGoalsFromCsv(csvContent);
      } else if (filename.contains('categor')) {
        return await _importCategoriesFromCsv(csvContent);
      } else if (filename.contains('achievement')) {
        return await _importAchievementsFromCsv(csvContent);
      } else {
        return const ImportResult(
          success: false,
          message:
              'CSV dosya türü tespit edilemedi. Dosya adında "routine", "goal", "category" veya "achievement" kelimesi olmalı.',
        );
      }
    } catch (e) {
      _logger.e('CSV import error: $e');
      return ImportResult(
        success: false,
        message: 'CSV import hatası: $e',
        errors: [e.toString()],
      );
    }
  }

  Future<ImportResult> _importRoutinesFromCsv(String csvContent) async {
    // TODO: Implement CSV import for routines
    return const ImportResult(
      success: false,
      message: 'CSV import henüz desteklenmiyor',
    );
  }

  Future<ImportResult> _importGoalsFromCsv(String csvContent) async {
    // TODO: Implement CSV import for goals
    return const ImportResult(
      success: false,
      message: 'CSV import henüz desteklenmiyor',
    );
  }

  Future<ImportResult> _importCategoriesFromCsv(String csvContent) async {
    // TODO: Implement CSV import for categories
    return const ImportResult(
      success: false,
      message: 'CSV import henüz desteklenmiyor',
    );
  }

  Future<ImportResult> _importAchievementsFromCsv(String csvContent) async {
    // TODO: Implement CSV import for achievements
    return const ImportResult(
      success: false,
      message: 'CSV import henüz desteklenmiyor',
    );
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Depolama izni gerekli');
      }
    }
  }

  // ==================== Utility Methods ====================

  /// Get estimated export file size
  Future<int> getEstimatedExportSize({
    ExportDataType dataType = ExportDataType.all,
    ExportFormat format = ExportFormat.json,
  }) async {
    try {
      String content;

      if (format == ExportFormat.json) {
        content = await exportToJson(dataType: dataType);
      } else {
        content = await exportToCsv(dataType: dataType);
      }

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
      ExportData.fromJson(jsonData);
      return true;
    } catch (e) {
      _logger.e('Export data validation failed: $e');
      return false;
    }
  }
}
