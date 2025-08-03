import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../features/notifications/presentation/widgets/time_picker_widget.dart';
import '../../features/notifications/presentation/providers/notification_settings_provider.dart';
import '../models/routine_model.dart';

class EnhancedRoutineDialog extends ConsumerStatefulWidget {
  final RoutineModel? existingRoutine;
  final Function(String name, TimeOfDay? reminderTime) onSave;
  final VoidCallback onCancel;

  const EnhancedRoutineDialog({
    super.key,
    this.existingRoutine,
    required this.onSave,
    required this.onCancel,
  });

  @override
  ConsumerState<EnhancedRoutineDialog> createState() =>
      _EnhancedRoutineDialogState();
}

class _EnhancedRoutineDialogState extends ConsumerState<EnhancedRoutineDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  TimeOfDay? _selectedReminderTime;
  bool _hasCustomTime = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingRoutine?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.existingRoutine?.description ?? '');

    // Initialize reminder time
    if (widget.existingRoutine?.reminderTime != null) {
      _selectedReminderTime = TimeOfDay(
        hour: widget.existingRoutine!.reminderTime!.hour,
        minute: widget.existingRoutine!.reminderTime!.minute,
      );
      _hasCustomTime = true;
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
    final theme = Theme.of(context);
    final globalSettings = ref.watch(notificationSettingsProvider);
    final isEditing = widget.existingRoutine != null;

    return AlertDialog(
      title: Text(isEditing ? 'Rutini Düzenle' : 'Yeni Rutin Ekle'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Rutin Adı *',
                  hintText: 'Örn: Günlük egzersiz, Su içme...',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLength: AppConstants.maxRoutineNameLength,
                autofocus: !isEditing,
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (İsteğe bağlı)',
                  hintText: 'Bu rutinle ilgili notlarınız...',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                maxLength: 100,
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // Reminder time section
              _buildReminderSection(theme, globalSettings),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : widget.onCancel,
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleSave,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Güncelle' : 'Kaydet'),
        ),
      ],
    );
  }

  Widget _buildReminderSection(
      ThemeData theme, NotificationSettingsState globalSettings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hatırlatma Ayarları',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),

        // Global settings info
        if (globalSettings.isGlobalEnabled &&
            globalSettings.globalReminderTime != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius:
                  BorderRadius.circular(AppConstants.cardBorderRadius),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Varsayılan bildirim zamanı: ${_formatTime(globalSettings.globalReminderTime!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
        ],

        // Custom time toggle
        Row(
          children: [
            Checkbox(
              value: _hasCustomTime,
              onChanged: (value) {
                setState(() {
                  _hasCustomTime = value ?? false;
                  if (!_hasCustomTime) {
                    _selectedReminderTime = null;
                  }
                });
              },
            ),
            Expanded(
              child: Text(
                'Bu rutin için özel hatırlatma zamanı ayarla',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),

        // Custom time picker
        if (_hasCustomTime) ...[
          const SizedBox(height: AppConstants.smallPadding),
          TimePickerWidget(
            selectedTime: _selectedReminderTime,
            onTimeChanged: (time) {
              setState(() {
                _selectedReminderTime = time;
              });
            },
            label: 'Hatırlatma Zamanı',
            isEnabled: _hasCustomTime,
          ),
        ],

        // Effective time display
        const SizedBox(height: AppConstants.smallPadding),
        _buildEffectiveTimeDisplay(theme, globalSettings),
      ],
    );
  }

  Widget _buildEffectiveTimeDisplay(
      ThemeData theme, NotificationSettingsState globalSettings) {
    final effectiveTime = _getEffectiveReminderTime(globalSettings);

    if (effectiveTime == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bu rutin için bildirim gönderilmeyecek',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bildirim zamanı: ${_formatTime(effectiveTime)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TimeOfDay? _getEffectiveReminderTime(
      NotificationSettingsState globalSettings) {
    if (_hasCustomTime && _selectedReminderTime != null) {
      return _selectedReminderTime;
    }

    if (globalSettings.isGlobalEnabled &&
        globalSettings.globalReminderTime != null) {
      return globalSettings.globalReminderTime;
    }

    return null;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _handleSave() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rutin adı gerekli'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (name.length < AppConstants.minRoutineNameLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Rutin adı en az ${AppConstants.minRoutineNameLength} karakter olmalı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get effective reminder time for this routine
      final reminderTime = _hasCustomTime ? _selectedReminderTime : null;

      widget.onSave(name, reminderTime);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
