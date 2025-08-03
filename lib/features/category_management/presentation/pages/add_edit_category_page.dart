import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/category_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/category_provider.dart';

class AddEditCategoryPage extends ConsumerStatefulWidget {
  final CategoryModel? category; // null for add, non-null for edit

  const AddEditCategoryPage({
    super.key,
    this.category,
  });

  @override
  ConsumerState<AddEditCategoryPage> createState() =>
      _AddEditCategoryPageState();
}

class _AddEditCategoryPageState extends ConsumerState<AddEditCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  IconData _selectedIcon = Icons.category;
  Color _selectedColor = Colors.blue;
  bool _isSubmitting = false;

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description;
      _selectedIcon = widget.category!.icon;
      _selectedColor = widget.category!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Kategoriyi Düzenle' : 'Yeni Kategori'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _saveCategory,
            child: Text(
              isEditing ? 'GÜNCELLE' : 'KAYDET',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isSubmitting ? Colors.grey : _selectedColor,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview Card
              _buildPreviewCard(),

              const SizedBox(height: AppConstants.defaultPadding * 2),

              // Name Field
              _buildNameField(),

              const SizedBox(height: AppConstants.defaultPadding),

              // Description Field
              _buildDescriptionField(),

              const SizedBox(height: AppConstants.defaultPadding * 2),

              // Icon Selection
              _buildIconSelection(),

              const SizedBox(height: AppConstants.defaultPadding * 2),

              // Color Selection
              _buildColorSelection(),

              const SizedBox(height: AppConstants.defaultPadding * 3),

              // Save Button
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _selectedColor.withOpacity(0.1),
              _selectedColor.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Text(
              'Önizleme',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedIcon,
                    color: _selectedColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.isEmpty
                            ? 'Kategori Adı'
                            : _nameController.text,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedColor,
                                ),
                      ),
                      if (_descriptionController.text.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _descriptionController.text,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.8),
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori Adı *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Örn: Sağlık, Egzersiz, Eğitim...',
            prefixIcon: Icon(_selectedIcon, color: _selectedColor),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.cardBorderRadius),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.cardBorderRadius),
              borderSide: BorderSide(color: _selectedColor.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.cardBorderRadius),
              borderSide: BorderSide(color: _selectedColor, width: 2),
            ),
          ),
          textCapitalization: TextCapitalization.words,
          maxLength: AppConstants.maxRoutineNameLength,
          onChanged: (value) => setState(() {}), // Trigger preview update
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Kategori adı gerekli';
            }
            if (value.trim().length < AppConstants.minRoutineNameLength) {
              return 'Kategori adı en az ${AppConstants.minRoutineNameLength} karakter olmalı';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Açıklama',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'Bu kategorideki rutinleri açıklayın...',
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.cardBorderRadius),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.cardBorderRadius),
              borderSide: BorderSide(color: _selectedColor.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.cardBorderRadius),
              borderSide: BorderSide(color: _selectedColor, width: 2),
            ),
          ),
          maxLines: 3,
          maxLength: 150,
          onChanged: (value) => setState(() {}), // Trigger preview update
        ),
      ],
    );
  }

  Widget _buildIconSelection() {
    final categoryIcons = [
      Icons.category,
      Icons.health_and_safety,
      Icons.fitness_center,
      Icons.school,
      Icons.work,
      Icons.self_improvement,
      Icons.palette,
      Icons.people,
      Icons.home,
      Icons.attach_money,
      Icons.devices,
      Icons.restaurant,
      Icons.music_note,
      Icons.sports_soccer,
      Icons.book,
      Icons.local_hospital,
      Icons.directions_car,
      Icons.pets,
      Icons.shopping_cart,
      Icons.phone,
      Icons.email,
      Icons.camera_alt,
      Icons.games,
      Icons.travel_explore,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İkon Seçin',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _selectedColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: categoryIcons.length,
            itemBuilder: (context, index) {
              final icon = categoryIcons[index];
              final isSelected = icon == _selectedIcon;

              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _selectedColor.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: _selectedColor, width: 2)
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? _selectedColor : Colors.grey,
                    size: 24,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelection() {
    final categoryColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.brown,
      Colors.grey,
      Colors.deepOrange,
      Colors.lightGreen,
      Colors.deepPurple,
      Colors.lime,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Renk Seçin',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _selectedColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: categoryColors.length,
            itemBuilder: (context, index) {
              final color = categoryColors[index];
              final isSelected = color == _selectedColor;

              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : Border.all(color: Colors.grey.withOpacity(0.3)),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _saveCategory,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isEditing ? Icons.update : Icons.add,
                      color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Kategoriyi Güncelle' : 'Kategori Oluştur',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final category = CategoryModel(
        id: isEditing
            ? widget.category!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        createdAt: isEditing ? widget.category!.createdAt : DateTime.now(),
        updatedAt: isEditing ? DateTime.now() : null,
        isActive: true,
        routineCount: isEditing ? widget.category!.routineCount : 0,
      );

      final success = isEditing
          ? await ref.read(categoryProvider.notifier).updateCategory(category)
          : await ref.read(categoryProvider.notifier).addCategory(category);

      if (success) {
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditing
                  ? 'Kategori başarıyla güncellendi'
                  : 'Kategori başarıyla oluşturuldu'),
              backgroundColor: _selectedColor,
            ),
          );
        }
      } else {
        // Error message is handled by the provider
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
