import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../shared/services/routine_reminder_service.dart';
import '../../../../core/di/injection.dart';
import 'time_picker_widget.dart';

class NotificationSettingsCard extends ConsumerStatefulWidget {
  final bool isGlobalEnabled;
  final TimeOfDay? globalReminderTime;
  final ValueChanged<bool> onGlobalToggled;
  final ValueChanged<TimeOfDay?> onGlobalTimeChanged;

  const NotificationSettingsCard({
    super.key,
    required this.isGlobalEnabled,
    required this.globalReminderTime,
    required this.onGlobalToggled,
    required this.onGlobalTimeChanged,
  });

  @override
  ConsumerState<NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState
    extends ConsumerState<NotificationSettingsCard> {
  bool _isCheckingPermissions = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bildirim Ayarları',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rutin hatırlatmalarını ayarlayın',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Global notification toggle
            _buildGlobalToggle(theme),
            const SizedBox(height: AppConstants.defaultPadding),

            // Global time picker
            if (widget.isGlobalEnabled) ...[
              TimePickerWidget(
                selectedTime: widget.globalReminderTime,
                onTimeChanged: widget.onGlobalTimeChanged,
                label: 'Varsayılan Hatırlatma Zamanı',
                isEnabled: widget.isGlobalEnabled,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
            ],

            // Permission status and actions
            _buildPermissionSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalToggle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: widget.isGlobalEnabled
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.isGlobalEnabled
                ? Icons.notifications_active
                : Icons.notifications_off,
            color: widget.isGlobalEnabled
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bildirimleri Etkinleştir',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.isGlobalEnabled
                      ? 'Rutin hatırlatmaları aktif'
                      : 'Rutin hatırlatmaları kapalı',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: widget.isGlobalEnabled,
            onChanged: (value) async {
              if (value) {
                // Check permissions when enabling
                final hasPermission = await _checkAndRequestPermissions();
                if (hasPermission) {
                  widget.onGlobalToggled(value);
                }
              } else {
                widget.onGlobalToggled(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Bildirim İzinleri',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bildirimlerin çalışması için uygulamaya izin vermeniz gerekiyor.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isCheckingPermissions ? null : _checkPermissions,
                  icon: _isCheckingPermissions
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_isCheckingPermissions
                      ? 'Kontrol ediliyor...'
                      : 'İzinleri Kontrol Et'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      _isCheckingPermissions ? null : _requestPermissions,
                  icon: const Icon(Icons.notification_add),
                  label: const Text('İzin İste'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _checkAndRequestPermissions() async {
    setState(() => _isCheckingPermissions = true);

    try {
      final notificationService = getIt<NotificationService>();
      final reminderService = getIt<RoutineReminderService>();

      // First ensure services are initialized
      if (!notificationService.isInitialized) {
        await notificationService.initialize();
      }

      // Check if permissions are already granted
      final hasPermissions = await reminderService.ensurePermissions();

      if (hasPermissions) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Bildirim izinleri aktif'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Bildirim izinleri gerekli'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _isCheckingPermissions = false);
      }
    }
  }

  Future<void> _checkPermissions() async {
    await _checkAndRequestPermissions();
  }

  Future<void> _requestPermissions() async {
    setState(() => _isCheckingPermissions = true);

    try {
      final notificationService = getIt<NotificationService>();

      // Request permissions
      final granted = await notificationService.requestPermissions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(granted
                ? '✅ Bildirim izinleri verildi'
                : '❌ Bildirim izinleri reddedildi'),
            backgroundColor: granted ? Colors.green : Colors.red,
          ),
        );
      }
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
        setState(() => _isCheckingPermissions = false);
      }
    }
  }
}
