import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../shared/services/notification_service.dart';
import '../../features/notifications/presentation/providers/notification_settings_provider.dart';
import '../../features/notifications/presentation/pages/notification_settings_page.dart';

class NotificationQuickSettings extends ConsumerWidget {
  const NotificationQuickSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(notificationSettingsProvider);
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  settingsState.isGlobalEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color: settingsState.isGlobalEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bildirim Ayarları',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationSettingsPage(),
                      ),
                    );
                  },
                  child: const Text('Ayarlar'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick toggle and info
            Row(
              children: [
                // Status indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: settingsState.isGlobalEnabled
                        ? Colors.green
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settingsState.isGlobalEnabled
                            ? 'Bildirimler Aktif'
                            : 'Bildirimler Kapalı',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (settingsState.isGlobalEnabled &&
                          settingsState.globalReminderTime != null) ...[
                        Text(
                          'Varsayılan: ${_formatTime(settingsState.globalReminderTime!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ] else if (settingsState.isGlobalEnabled) ...[
                        Text(
                          'Zaman ayarlanmamış',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Quick toggle switch
                Switch(
                  value: settingsState.isGlobalEnabled,
                  onChanged: (value) {
                    if (value && settingsState.globalReminderTime == null) {
                      // If enabling but no time set, go to settings
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationSettingsPage(),
                        ),
                      );
                    } else {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleGlobalNotifications(value);
                    }
                  },
                ),
              ],
            ),

            // Quick actions row (only show if enabled)
            if (settingsState.isGlobalEnabled) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _testNotification(context, ref),
                      icon: Icon(
                        Icons.bug_report,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      label: const Text('Test'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const NotificationSettingsPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings, size: 16),
                      label: const Text('Düzenle'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _testNotification(BuildContext context, WidgetRef ref) async {
    try {
      // Get notification service
      final notificationService = getIt<NotificationService>();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧪 Test bildirimi gönderiliyor...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Show immediate test notification
      await notificationService.showNotification(
        id: 999998,
        title: '🧪 Quick Test',
        body: 'Notification sisteminiz çalışıyor!',
        payload: 'quick_test',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Test bildirimi gönderildi!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
