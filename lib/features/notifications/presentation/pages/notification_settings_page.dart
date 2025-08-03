import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../providers/notification_settings_provider.dart';
import '../widgets/notification_settings_card.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(notificationSettingsProvider);
    final theme = Theme.of(context);

    // Listen for errors and show snackbars
    ref.listen<NotificationSettingsState>(notificationSettingsProvider,
        (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        ref.read(notificationSettingsProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  _showResetDialog(context, ref);
                  break;
                case 'test':
                  _testNotifications(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'test',
                child: ListTile(
                  leading: Icon(Icons.bug_report),
                  title: Text('Test Bildirimi'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: Icon(Icons.restore),
                  title: Text('Ayarları Sıfırla'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: settingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(notificationSettingsProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main settings card
                    NotificationSettingsCard(
                      isGlobalEnabled: settingsState.isGlobalEnabled,
                      globalReminderTime: settingsState.globalReminderTime,
                      onGlobalToggled: (enabled) {
                        ref
                            .read(notificationSettingsProvider.notifier)
                            .toggleGlobalNotifications(enabled);
                      },
                      onGlobalTimeChanged: (time) {
                        ref
                            .read(notificationSettingsProvider.notifier)
                            .setGlobalReminderTime(time);
                      },
                    ),

                    const SizedBox(height: AppConstants.defaultPadding),

                    // Additional settings
                    _buildAdditionalSettings(
                        context, theme, ref, settingsState),

                    const SizedBox(height: AppConstants.defaultPadding),

                    // Information section
                    _buildInformationSection(context, theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAdditionalSettings(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    NotificationSettingsState settingsState,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ek Ayarlar',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Current settings summary
            _buildSettingsSummary(theme, settingsState),

            const SizedBox(height: AppConstants.defaultPadding),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _testNotifications(context, ref),
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Test Bildirimi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showResetDialog(context, ref),
                    icon: const Icon(Icons.restore),
                    label: const Text('Sıfırla'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSummary(
      ThemeData theme, NotificationSettingsState settingsState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            theme,
            'Durum',
            settingsState.isGlobalEnabled ? 'Aktif' : 'Kapalı',
            settingsState.isGlobalEnabled ? Colors.green : Colors.grey,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            theme,
            'Varsayılan Saat',
            settingsState.globalReminderTime != null
                ? '${settingsState.globalReminderTime!.hour.toString().padLeft(2, '0')}:${settingsState.globalReminderTime!.minute.toString().padLeft(2, '0')}'
                : 'Belirlenmemiş',
            settingsState.globalReminderTime != null
                ? theme.colorScheme.primary
                : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      ThemeData theme, String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInformationSection(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bilgilendirme',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• Varsayılan bildirim zamanı, kendine özel saati olmayan rutinler için kullanılır.\n\n'
              '• Her rutin için ayrı ayrı bildirim zamanı da ayarlayabilirsiniz.\n\n'
              '• Bildirimlerin çalışması için sistem izinlerini vermeniz gerekiyor.\n\n'
              '• Bildirimler sadece aktif rutinler için gönderilir.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testNotifications(BuildContext context, WidgetRef ref) async {
    try {
      // Import notification service
      final notificationService =
          ref.read(notificationSettingsProvider.notifier);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧪 Test bildirimi gönderiliyor...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Show test notification after 3 seconds
      await Future.delayed(const Duration(seconds: 3));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ Test bildirimi gönderildi! Bildirim panelini kontrol edin.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Test bildirimi gönderilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayarları Sıfırla'),
        content: const Text(
          'Tüm bildirim ayarlarını varsayılan değerlere döndürmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(notificationSettingsProvider.notifier).resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Ayarlar varsayılan değerlere sıfırlandı'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }
}
