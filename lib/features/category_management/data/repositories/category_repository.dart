import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../../../../shared/models/category_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';

class CategoryRepository {
  static final CategoryRepository _instance = CategoryRepository._internal();
  factory CategoryRepository() => _instance;
  CategoryRepository._internal();

  final Box _hiveBox = Hive.box(AppConstants.hiveBoxName);
  final Logger _logger = Logger();

  String? _currentUserId;
  static const String _categoriesKey = 'categories';
  static const String _defaultCategoriesKey = 'default_categories_created';

  /// Initialize repository with user context
  void initialize({String? userId}) {
    _currentUserId = userId;
    _logger.i('CategoryRepository initialized for user: $userId');

    // Create default categories if not exists
    _createDefaultCategoriesIfNeeded();
  }

  /// Create default categories for new users
  Future<void> _createDefaultCategoriesIfNeeded() async {
    try {
      final hasDefaultCategories =
          _hiveBox.get('${_defaultCategoriesKey}_$_currentUserId') ?? false;

      if (!hasDefaultCategories) {
        // Create some essential default categories
        final defaultTemplates = CategoryTemplates.templates
            .take(5)
            .toList(); // Take first 5 templates

        for (final template in defaultTemplates) {
          final category = CategoryTemplates.createFromTemplate(
              template, _currentUserId ?? '');
          await _saveCategoryLocally(category);
        }

        // Mark default categories as created
        await _hiveBox.put('${_defaultCategoriesKey}_$_currentUserId', true);
        _logger.i('Default categories created for user: $_currentUserId');
      }
    } catch (e) {
      _logger.e('Error creating default categories: $e');
    }
  }

  /// Get all categories for current user
  Future<List<CategoryModel>> getCategories() async {
    try {
      final categoriesData =
          _hiveBox.get('${_categoriesKey}_$_currentUserId') as List<dynamic>? ??
              [];

      final categories = categoriesData
          .cast<Map<String, dynamic>>()
          .map(
              (json) => CategoryModel.fromJson(Map<String, dynamic>.from(json)))
          .where((category) => category.isActive)
          .toList();

      // Sort by name
      categories.sort((a, b) => a.name.compareTo(b.name));

      _logger.d(
          'Retrieved ${categories.length} categories for user: $_currentUserId');
      return categories;
    } catch (e) {
      _logger.e('Error getting categories: $e');
      throw CacheException('Failed to get categories: $e');
    }
  }

  /// Get category by ID
  Future<CategoryModel?> getCategoryById(String categoryId) async {
    try {
      final categories = await getCategories();
      return categories.firstWhere(
        (category) => category.id == categoryId,
        orElse: () => DefaultCategory.uncategorized,
      );
    } catch (e) {
      _logger.e('Error getting category by ID: $e');
      return null;
    }
  }

  /// Add new category
  Future<void> addCategory(CategoryModel category) async {
    try {
      final updatedCategory = category.copyWith(
        userId: _currentUserId,
        createdAt: DateTime.now(),
      );

      await _saveCategoryLocally(updatedCategory);
      _logger.i('Category added: ${updatedCategory.name}');
    } catch (e) {
      _logger.e('Error adding category: $e');
      throw CacheException('Failed to add category: $e');
    }
  }

  /// Update category
  Future<void> updateCategory(CategoryModel category) async {
    try {
      final updatedCategory = category.copyWith(
        updatedAt: DateTime.now(),
      );

      await _updateCategoryLocally(updatedCategory);
      _logger.i('Category updated: ${updatedCategory.name}');
    } catch (e) {
      _logger.e('Error updating category: $e');
      throw CacheException('Failed to update category: $e');
    }
  }

  /// Delete category (mark as inactive)
  Future<void> deleteCategory(String categoryId) async {
    try {
      final categories = await getCategories();
      final categoryIndex = categories.indexWhere((c) => c.id == categoryId);

      if (categoryIndex == -1) {
        throw const CacheException('Category not found');
      }

      final updatedCategory = categories[categoryIndex].copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      await _updateCategoryLocally(updatedCategory);
      _logger.i('Category deleted: $categoryId');
    } catch (e) {
      _logger.e('Error deleting category: $e');
      throw CacheException('Failed to delete category: $e');
    }
  }

  /// Update category routine count
  Future<void> updateCategoryRoutineCount(
      String categoryId, int newCount) async {
    try {
      final categories = await getCategories();
      final categoryIndex = categories.indexWhere((c) => c.id == categoryId);

      if (categoryIndex >= 0) {
        final updatedCategory = categories[categoryIndex].copyWith(
          routineCount: newCount,
          updatedAt: DateTime.now(),
        );

        await _updateCategoryLocally(updatedCategory);
        _logger.d('Updated routine count for category $categoryId: $newCount');
      }
    } catch (e) {
      _logger.e('Error updating category routine count: $e');
    }
  }

  /// Get categories with routine counts
  Future<List<CategoryModel>> getCategoriesWithCounts(
      List<String> routineCategoryIds) async {
    try {
      final categories = await getCategories();

      // Count routines for each category
      final categoryCounts = <String, int>{};
      for (final categoryId in routineCategoryIds) {
        categoryCounts[categoryId] = (categoryCounts[categoryId] ?? 0) + 1;
      }

      // Update categories with counts
      final updatedCategories = categories.map((category) {
        final count = categoryCounts[category.id] ?? 0;
        return category.copyWith(routineCount: count);
      }).toList();

      return updatedCategories;
    } catch (e) {
      _logger.e('Error getting categories with counts: $e');
      return [];
    }
  }

  /// Get category templates for creation
  List<CategoryTemplate> getCategoryTemplates() {
    return CategoryTemplates.templates;
  }

  /// Create category from template
  Future<void> createCategoryFromTemplate(CategoryTemplate template) async {
    final category =
        CategoryTemplates.createFromTemplate(template, _currentUserId ?? '');
    await addCategory(category);
  }

  /// Check if category name exists
  Future<bool> categoryNameExists(String name, {String? excludeId}) async {
    try {
      final categories = await getCategories();
      return categories.any((category) =>
          category.name.toLowerCase() == name.toLowerCase() &&
          category.id != excludeId);
    } catch (e) {
      _logger.e('Error checking category name existence: $e');
      return false;
    }
  }

  /// Get category statistics
  Future<Map<String, dynamic>> getCategoryStatistics() async {
    try {
      final categories = await getCategories();

      return {
        'totalCategories': categories.length,
        'activeCategories': categories.where((c) => c.isActive).length,
        'totalRoutines':
            categories.fold<int>(0, (sum, c) => sum + c.routineCount),
        'mostUsedCategory': categories.isNotEmpty
            ? categories
                .reduce((a, b) => a.routineCount > b.routineCount ? a : b)
            : null,
        'leastUsedCategory': categories.isNotEmpty
            ? categories
                .reduce((a, b) => a.routineCount < b.routineCount ? a : b)
            : null,
      };
    } catch (e) {
      _logger.e('Error getting category statistics: $e');
      return {};
    }
  }

  /// Private Methods
  Future<void> _saveCategoryLocally(CategoryModel category) async {
    final categories = await getCategories();
    categories.add(category);
    await _saveCategoriesLocally(categories);
  }

  Future<void> _updateCategoryLocally(CategoryModel updatedCategory) async {
    final categories = await getCategories();
    final index = categories.indexWhere((c) => c.id == updatedCategory.id);

    if (index >= 0) {
      categories[index] = updatedCategory;
      await _saveCategoriesLocally(categories);
    }
  }

  Future<void> _saveCategoriesLocally(List<CategoryModel> categories) async {
    final categoriesJson = categories.map((c) => c.toJson()).toList();
    await _hiveBox.put('${_categoriesKey}_$_currentUserId', categoriesJson);
  }

  /// Cleanup inactive categories (optional maintenance)
  Future<void> cleanupInactiveCategories() async {
    try {
      final allCategories =
          _hiveBox.get('${_categoriesKey}_$_currentUserId') as List<dynamic>? ??
              [];

      final activeCategories = allCategories
          .cast<Map<String, dynamic>>()
          .map(
              (json) => CategoryModel.fromJson(Map<String, dynamic>.from(json)))
          .where((category) => category.isActive)
          .toList();

      await _saveCategoriesLocally(activeCategories);
      _logger.i('Cleaned up inactive categories');
    } catch (e) {
      _logger.e('Error cleaning up inactive categories: $e');
    }
  }
}
