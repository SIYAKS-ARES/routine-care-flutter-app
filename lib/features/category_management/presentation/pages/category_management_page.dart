import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/category_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/category_provider.dart';
import '../widgets/category_card.dart';
import 'add_edit_category_page.dart';

class CategoryManagementPage extends ConsumerStatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  ConsumerState<CategoryManagementPage> createState() =>
      _CategoryManagementPageState();
}

class _CategoryManagementPageState
    extends ConsumerState<CategoryManagementPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize categories when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);
    final categories = ref.watch(categoriesListProvider);
    final isLoading = ref.watch(categoryLoadingProvider);
    final error = ref.watch(categoryErrorProvider);

    // Filter categories based on search query
    final filteredCategories = categories.where((category) {
      return category.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          category.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori Yönetimi'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _navigateToAddCategory(),
            tooltip: 'Yeni Kategori',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'templates':
                  _showCategoryTemplates();
                  break;
                case 'statistics':
                  _showCategoryStatistics();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'templates',
                child: Row(
                  children: [
                    Icon(Icons.dashboard_customize, size: 20),
                    SizedBox(width: 8),
                    Text('Şablonlar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'statistics',
                child: Row(
                  children: [
                    Icon(Icons.analytics, size: 20),
                    SizedBox(width: 8),
                    Text('İstatistikler'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Kategorilerde ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.cardBorderRadius),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),

          // Error message
          if (error != null) ...[
            Container(
              margin: const EdgeInsets.all(AppConstants.defaultPadding),
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(AppConstants.cardBorderRadius),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(error,
                          style: const TextStyle(color: Colors.red))),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        ref.read(categoryProvider.notifier).clearError(),
                  ),
                ],
              ),
            ),
          ],

          // Category count and info
          if (!isLoading && filteredCategories.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding),
              child: Row(
                children: [
                  Text(
                    '${filteredCategories.length} kategori',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.7),
                        ),
                  ),
                  const Spacer(),
                  if (_searchQuery.isNotEmpty)
                    Text(
                      '"$_searchQuery" için sonuçlar',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
          ],

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(categoryProvider.notifier).loadCategories();
              },
              child: _buildContent(isLoading, filteredCategories),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddCategory,
        icon: const Icon(Icons.add),
        label: const Text('Kategori Ekle'),
      ),
    );
  }

  Widget _buildContent(bool isLoading, List<CategoryModel> categories) {
    if (isLoading && categories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (categories.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryCard(
          category: category,
          onTap: () => _navigateToEditCategory(category),
          onEdit: () => _navigateToEditCategory(category),
          onDelete: () => _confirmDeleteCategory(category),
          showRoutineCount: true,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final hasSearchQuery = _searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearchQuery ? Icons.search_off : Icons.category_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              hasSearchQuery ? 'Arama sonucu bulunamadı' : 'Henüz kategori yok',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              hasSearchQuery
                  ? 'Farklı anahtar kelimeler deneyin'
                  : 'Rutinlerinizi organize etmek için kategori oluşturun',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.defaultPadding * 2),
            if (!hasSearchQuery) ...[
              ElevatedButton.icon(
                onPressed: _navigateToAddCategory,
                icon: const Icon(Icons.add),
                label: const Text('İlk Kategorini Oluştur'),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              OutlinedButton.icon(
                onPressed: _showCategoryTemplates,
                icon: const Icon(Icons.dashboard_customize),
                label: const Text('Şablonlardan Seç'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToAddCategory() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddEditCategoryPage(),
      ),
    );

    if (result == true) {
      // Category was added successfully, refresh the list
      ref.read(categoryProvider.notifier).loadCategories();
    }
  }

  void _navigateToEditCategory(CategoryModel category) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEditCategoryPage(category: category),
      ),
    );

    if (result == true) {
      // Category was updated successfully, refresh the list
      ref.read(categoryProvider.notifier).loadCategories();
    }
  }

  void _confirmDeleteCategory(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${category.name} kategorisini silmek istediğinizden emin misiniz?'),
            const SizedBox(height: 8),
            if (category.routineCount > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bu kategoride ${category.routineCount} rutin var. Bu rutinler "Kategorisiz" olarak işaretlenecek.',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await ref
                  .read(categoryProvider.notifier)
                  .deleteCategory(category.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${category.name} kategorisi silindi'),
                    action: SnackBarAction(
                      label: 'Geri Al',
                      onPressed: () {
                        // TODO: Implement undo functionality
                      },
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showCategoryTemplates() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => CategoryTemplatesSheet(
          scrollController: scrollController,
          onTemplateSelected: (template) async {
            Navigator.of(context).pop();
            final success = await ref
                .read(categoryProvider.notifier)
                .createCategoryFromTemplate(template);
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${template.name} kategorisi oluşturuldu')),
              );
            }
          },
        ),
      ),
    );
  }

  void _showCategoryStatistics() async {
    final stats =
        await ref.read(categoryProvider.notifier).getCategoryStatistics();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategori İstatistikleri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow(
                'Toplam Kategori', '${stats['totalCategories'] ?? 0}'),
            _buildStatRow(
                'Aktif Kategori', '${stats['activeCategories'] ?? 0}'),
            _buildStatRow('Toplam Rutin', '${stats['totalRoutines'] ?? 0}'),
            if (stats['mostUsedCategory'] != null) ...[
              const Divider(),
              _buildStatRow(
                  'En Çok Kullanılan', '${stats['mostUsedCategory'].name}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Category Templates Bottom Sheet
class CategoryTemplatesSheet extends ConsumerWidget {
  final ScrollController scrollController;
  final Function(CategoryTemplate) onTemplateSelected;

  const CategoryTemplatesSheet({
    super.key,
    required this.scrollController,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(categoryTemplatesProvider);

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            'Kategori Şablonları',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Hazır şablonlardan birini seçerek hızlıca kategori oluşturun',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),

          // Templates grid
          Expanded(
            child: GridView.builder(
              controller: scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppConstants.smallPadding,
                mainAxisSpacing: AppConstants.smallPadding,
                childAspectRatio: 1.2,
              ),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return GestureDetector(
                  onTap: () => onTemplateSelected(template),
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          template.color.withOpacity(0.1),
                          template.color.withOpacity(0.05),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(AppConstants.cardBorderRadius),
                      border: Border.all(
                        color: template.color.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          template.icon,
                          color: template.color,
                          size: 32,
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Text(
                          template.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: template.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template.description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withOpacity(0.7),
                                  ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
