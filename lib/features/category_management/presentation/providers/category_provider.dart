import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../../shared/models/category_model.dart';
import '../../data/repositories/category_repository.dart';
import '../../../../core/di/injection.dart';

class CategoryState {
  final List<CategoryModel> categories;
  final bool isLoading;
  final String? error;
  final CategoryModel? selectedCategory;

  const CategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory,
  });

  CategoryState copyWith({
    List<CategoryModel>? categories,
    bool? isLoading,
    String? error,
    CategoryModel? selectedCategory,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  CategoryNotifier() : super(const CategoryState()) {
    _repository = getIt<CategoryRepository>();
    _logger = Logger();
  }

  late final CategoryRepository _repository;
  late final Logger _logger;

  /// Initialize categories with user context
  void initialize({String? userId}) {
    _repository.initialize(userId: userId);
    _logger.i('CategoryNotifier initialized for user: $userId');
    loadCategories();
  }

  /// Load all categories
  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final categories = await _repository.getCategories();
      state = state.copyWith(
        categories: categories,
        isLoading: false,
      );

      _logger.i('Loaded ${categories.length} categories');
    } catch (e) {
      _logger.e('Error loading categories: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Kategoriler yüklenirken hata oluştu: $e',
      );
    }
  }

  /// Add new category
  Future<bool> addCategory(CategoryModel category) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Check if name already exists
      final nameExists = await _repository.categoryNameExists(category.name);
      if (nameExists) {
        state = state.copyWith(
          isLoading: false,
          error: 'Bu isimde bir kategori zaten mevcut',
        );
        return false;
      }

      await _repository.addCategory(category);
      await loadCategories(); // Refresh list

      _logger.i('Category added successfully: ${category.name}');
      return true;
    } catch (e) {
      _logger.e('Error adding category: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Kategori eklenirken hata oluştu: $e',
      );
      return false;
    }
  }

  /// Update existing category
  Future<bool> updateCategory(CategoryModel category) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Check if name already exists (excluding current category)
      final nameExists = await _repository.categoryNameExists(
        category.name,
        excludeId: category.id,
      );
      if (nameExists) {
        state = state.copyWith(
          isLoading: false,
          error: 'Bu isimde bir kategori zaten mevcut',
        );
        return false;
      }

      await _repository.updateCategory(category);
      await loadCategories(); // Refresh list

      _logger.i('Category updated successfully: ${category.name}');
      return true;
    } catch (e) {
      _logger.e('Error updating category: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Kategori güncellenirken hata oluştu: $e',
      );
      return false;
    }
  }

  /// Delete category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.deleteCategory(categoryId);
      await loadCategories(); // Refresh list

      _logger.i('Category deleted successfully: $categoryId');
      return true;
    } catch (e) {
      _logger.e('Error deleting category: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Kategori silinirken hata oluştu: $e',
      );
      return false;
    }
  }

  /// Create category from template
  Future<bool> createCategoryFromTemplate(CategoryTemplate template) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Check if name already exists
      final nameExists = await _repository.categoryNameExists(template.name);
      if (nameExists) {
        state = state.copyWith(
          isLoading: false,
          error: 'Bu isimde bir kategori zaten mevcut',
        );
        return false;
      }

      await _repository.createCategoryFromTemplate(template);
      await loadCategories(); // Refresh list

      _logger.i('Category created from template: ${template.name}');
      return true;
    } catch (e) {
      _logger.e('Error creating category from template: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Kategori oluşturulurken hata oluştu: $e',
      );
      return false;
    }
  }

  /// Get category by ID
  CategoryModel? getCategoryById(String categoryId) {
    try {
      return state.categories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return DefaultCategory.uncategorized;
    }
  }

  /// Update category routine count
  Future<void> updateCategoryRoutineCount(
      String categoryId, int newCount) async {
    try {
      await _repository.updateCategoryRoutineCount(categoryId, newCount);
      await loadCategories(); // Refresh to show updated counts
    } catch (e) {
      _logger.e('Error updating category routine count: $e');
    }
  }

  /// Refresh categories with routine counts
  Future<void> refreshCategoriesWithCounts(
      List<String> routineCategoryIds) async {
    try {
      final categoriesWithCounts =
          await _repository.getCategoriesWithCounts(routineCategoryIds);
      state = state.copyWith(categories: categoriesWithCounts);
    } catch (e) {
      _logger.e('Error refreshing categories with counts: $e');
    }
  }

  /// Get category statistics
  Future<Map<String, dynamic>> getCategoryStatistics() async {
    try {
      return await _repository.getCategoryStatistics();
    } catch (e) {
      _logger.e('Error getting category statistics: $e');
      return {};
    }
  }

  /// Set selected category
  void setSelectedCategory(CategoryModel? category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Get category templates
  List<CategoryTemplate> getCategoryTemplates() {
    return _repository.getCategoryTemplates();
  }
}

// Providers
final categoryProvider =
    StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier();
});

// Derived providers for easier access
final categoriesListProvider = Provider<List<CategoryModel>>((ref) {
  return ref.watch(categoryProvider).categories;
});

final categoryLoadingProvider = Provider<bool>((ref) {
  return ref.watch(categoryProvider).isLoading;
});

final categoryErrorProvider = Provider<String?>((ref) {
  return ref.watch(categoryProvider).error;
});

final selectedCategoryProvider = Provider<CategoryModel?>((ref) {
  return ref.watch(categoryProvider).selectedCategory;
});

// Category dropdown provider (includes uncategorized option)
final categoryDropdownProvider = Provider<List<CategoryModel>>((ref) {
  final categories = ref.watch(categoriesListProvider);
  return [DefaultCategory.uncategorized, ...categories];
});

// Category templates provider
final categoryTemplatesProvider = Provider<List<CategoryTemplate>>((ref) {
  return CategoryTemplates.templates;
});

// Category statistics provider
final categoryStatisticsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final notifier = ref.watch(categoryProvider.notifier);
  return await notifier.getCategoryStatistics();
});
