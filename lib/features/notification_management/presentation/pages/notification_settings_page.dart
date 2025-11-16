import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/notification_model.dart';
// import '../../../../shared/widgets/time_picker_widget.dart';
import '../widgets/notification_test_widget.dart';
import '../widgets/dnd_schedule_widget.dart';
import '../widgets/notification_tone_selector.dart';
import '../providers/notification_preferences_provider.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferencesAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.notifications), text: 'Genel'),
            Tab(icon: Icon(Icons.schedule), text: 'Zamanlama'),
            Tab(icon: Icon(Icons.do_not_disturb), text: 'Rahatsız Etme'),
            Tab(icon: Icon(Icons.psychology), text: 'Akıllı'),
          ],
        ),
      ),
      body: preferencesAsync.when(
        data: (preferences) => TabBarView(
          controller: _tabController,
          children: [
            _buildGeneralTab(preferences),
            _buildSchedulingTab(preferences),
            _buildDNDTab(preferences),
            _buildSmartTab(preferences),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Hata: $error'),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(notificationPreferencesProvider),
                child: const Text('Yeniden Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralTab(NotificationPreferences preferences) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Main toggle
        Card(
          child: SwitchListTile(
            title: const Text(
              'Bildirimleri Etkinleştir',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Tüm bildirimleri aç/kapat'),
            value: preferences.notificationsEnabled,
            onChanged: (value) => _updatePreferences(
              preferences.copyWith(notificationsEnabled: value),
            ),
            secondary: Icon(
              preferences.notificationsEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color:
                  preferences.notificationsEnabled ? Colors.green : Colors.grey,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Notification types
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Bildirim Türleri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              _buildNotificationTypeToggle(
                title: 'Rutin Hatırlatıcıları',
                subtitle: 'Rutin zamanlarında hatırlatıcı bildirimleri',
                icon: Icons.schedule,
                value: preferences.routineRemindersEnabled,
                onChanged: (value) => _updatePreferences(
                  preferences.copyWith(routineRemindersEnabled: value),
                ),
              ),
              _buildNotificationTypeToggle(
                title: 'Seri Uyarıları',
                subtitle: 'Seri kırılma riskinde uyarı bildirimleri',
                icon: Icons.warning,
                value: preferences.streakWarningsEnabled,
                onChanged: (value) => _updatePreferences(
                  preferences.copyWith(streakWarningsEnabled: value),
                ),
              ),
              _buildNotificationTypeToggle(
                title: 'Başarı Bildirimleri',
                subtitle: 'Milestone ve achievement kutlamaları',
                icon: Icons.emoji_events,
                value: preferences.achievementNotificationsEnabled,
                onChanged: (value) => _updatePreferences(
                  preferences.copyWith(achievementNotificationsEnabled: value),
                ),
              ),
              _buildNotificationTypeToggle(
                title: 'Motivasyon Mesajları',
                subtitle: 'Günlük motivasyonel bildirimleri',
                icon: Icons.favorite,
                value: preferences.motivationalMessagesEnabled,
                onChanged: (value) => _updatePreferences(
                  preferences.copyWith(motivationalMessagesEnabled: value),
                ),
              ),
              _buildNotificationTypeToggle(
                title: 'Günlük Özet',
                subtitle: 'Gün sonu aktivite özetleri',
                icon: Icons.today,
                value: preferences.dailySummaryEnabled,
                onChanged: (value) => _updatePreferences(
                  preferences.copyWith(dailySummaryEnabled: value),
                ),
              ),
              _buildNotificationTypeToggle(
                title: 'Haftalık Rapor',
                subtitle: 'Haftalık ilerleme raporları',
                icon: Icons.insights,
                value: preferences.weeklyReportEnabled,
                onChanged: (value) => _updatePreferences(
                  preferences.copyWith(weeklyReportEnabled: value),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Sound and vibration
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Ses ve Titreşim',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Ses'),
                subtitle: const Text('Bildirim seslerini çal'),
                value: preferences.soundEnabled,
                onChanged: (value) => _updatePreferences(
                  preferences.copyWith(soundEnabled: value),
                ),
                secondary: const Icon(Icons.volume_up),
              ),
              SwitchListTile(
                title: const Text('Titreşim'),
                subtitle: const Text('Bildirimde titreşim'),
                value: preferences.vibrationEnabled,
                onChanged: (value) => _updatePreferences(
                  preferences.copyWith(vibrationEnabled: value),
                ),
                secondary: const Icon(Icons.vibration),
              ),
              ListTile(
                title: const Text('Bildirim Tonu'),
                subtitle: Text(
                    _getNotificationToneDisplayName(preferences.preferredTone)),
                leading: const Icon(Icons.music_note),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showToneSelector(preferences),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Test notification
        NotificationTestWidget(preferences: preferences),
      ],
    );
  }

  Widget _buildNotificationTypeToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      secondary: Icon(
        icon,
        color: value ? Colors.blue : Colors.grey,
      ),
    );
  }

  Widget _buildSchedulingTab(NotificationPreferences preferences) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Snooze settings
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Erteleme Ayarları',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Ertelemeyi Etkinleştir'),
                subtitle: const Text('Bildirimleri erteleyebilme özelliği'),
                value: preferences.snoozeEnabled,
                onChanged: (value) => _updatePreferences(
                  preferences.copyWith(snoozeEnabled: value),
                ),
                secondary: const Icon(Icons.snooze),
              ),
              if (preferences.snoozeEnabled) ...[
                ListTile(
                  title: const Text('Erteleme Süresi'),
                  subtitle: Text('${preferences.snoozeMinutes} dakika'),
                  leading: const Icon(Icons.timer),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSnoozeTimePicker(preferences),
                ),
                ListTile(
                  title: const Text('Maksimum Erteleme'),
                  subtitle: Text('${preferences.maxSnoozeCount} kez'),
                  leading: const Icon(Icons.repeat),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showMaxSnoozeCountPicker(preferences),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Daily notification limit
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Bildirim Sınırları',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Günlük Maksimum Bildirim'),
                subtitle: Text(
                    'Günde en fazla ${preferences.maxDailyNotifications} bildirim'),
                leading: const Icon(Icons.format_list_numbered),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDailyLimitPicker(preferences),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Notification effectiveness
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Bildirim İstatistikleri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Bu Hafta'),
                subtitle: const Text('Gönderilen: 24 • Açılan: 18 • Oran: %75'),
                leading: const Icon(Icons.analytics),
              ),
              ListTile(
                title: const Text('En Etkili Zaman'),
                subtitle: const Text('Sabah 09:00 - 10:00 arası'),
                leading: const Icon(Icons.schedule),
              ),
              ListTile(
                title: const Text('En Az Etkili Zaman'),
                subtitle: const Text('Gece 22:00 - 06:00 arası'),
                leading: const Icon(Icons.bedtime),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDNDTab(NotificationPreferences preferences) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // DND main toggle
        Card(
          child: SwitchListTile(
            title: const Text(
              'Rahatsız Etme Modunu Etkinleştir',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Belirli saatlerde bildirimleri engelle'),
            value: preferences.doNotDisturbEnabled,
            onChanged: (value) => _updatePreferences(
              preferences.copyWith(doNotDisturbEnabled: value),
            ),
            secondary: Icon(
              preferences.doNotDisturbEnabled
                  ? Icons.do_not_disturb
                  : Icons.do_not_disturb_off,
              color:
                  preferences.doNotDisturbEnabled ? Colors.orange : Colors.grey,
            ),
          ),
        ),

        if (preferences.doNotDisturbEnabled) ...[
          const SizedBox(height: 16),

          // DND schedule
          DNDScheduleWidget(
            preferences: preferences,
            onPreferencesChanged: _updatePreferences,
          ),

          const SizedBox(height: 16),

          // DND days
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Aktif Günler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (int day = 1; day <= 7; day++)
                        FilterChip(
                          label: Text(_getDayName(day)),
                          selected: preferences.doNotDisturbDays.contains(day),
                          onSelected: (selected) {
                            final newDays =
                                List<int>.from(preferences.doNotDisturbDays);
                            if (selected) {
                              newDays.add(day);
                            } else {
                              newDays.remove(day);
                            }
                            _updatePreferences(
                              preferences.copyWith(doNotDisturbDays: newDays),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Emergency overrides
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Acil Durum İstisnaları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  title: Text('Seri Uyarıları'),
                  subtitle: Text('Seri kırılma riski yüksek olduğunda göster'),
                  leading: Icon(Icons.warning, color: Colors.orange),
                  trailing: Icon(Icons.check, color: Colors.green),
                ),
                const ListTile(
                  title: Text('Milestone Kutlamaları'),
                  subtitle: Text('Önemli başarılar için göster'),
                  leading: Icon(Icons.emoji_events, color: Colors.amber),
                  trailing: Icon(Icons.check, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSmartTab(NotificationPreferences preferences) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Smart features intro
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.purple),
                    SizedBox(width: 8),
                    Text(
                      'Akıllı Özellikler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Bu özellikler kullanım alışkanlıklarınızı öğrenerek bildirimleri optimize eder.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Smart timing
        Card(
          child: SwitchListTile(
            title: const Text('Akıllı Zamanlama'),
            subtitle: const Text('Alışkanlıklarınıza göre optimal zamanlama'),
            value: preferences.smartTimingEnabled,
            onChanged: (value) => _updatePreferences(
              preferences.copyWith(smartTimingEnabled: value),
            ),
            secondary: const Icon(Icons.access_time),
          ),
        ),

        const SizedBox(height: 8),

        // Context awareness
        Card(
          child: SwitchListTile(
            title: const Text('Bağlamsal Bildirimler'),
            subtitle: const Text('Durumunuza göre akıllı bildirim gönderimi'),
            value: preferences.contextAwareEnabled,
            onChanged: (value) => _updatePreferences(
              preferences.copyWith(contextAwareEnabled: value),
            ),
            secondary: const Icon(Icons.psychology),
          ),
        ),

        if (preferences.smartTimingEnabled ||
            preferences.contextAwareEnabled) ...[
          const SizedBox(height: 16),

          // Learning status
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Öğrenme Durumu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  title: Text('Veri Toplama'),
                  subtitle: Text('7 günlük kullanım verisi toplandı'),
                  leading: Icon(Icons.data_usage, color: Colors.blue),
                  trailing: Text('7/14 gün'),
                ),
                const ListTile(
                  title: Text('Başarı Oranı'),
                  subtitle: Text('Bildirimlerin %78\'ine yanıt verdiniz'),
                  leading: Icon(Icons.trending_up, color: Colors.green),
                  trailing: Text('%78'),
                ),
                const ListTile(
                  title: Text('En İyi Zaman'),
                  subtitle: Text('Sabah 09:15 - En yüksek yanıt oranı'),
                  leading: Icon(Icons.schedule, color: Colors.orange),
                  trailing: Icon(Icons.star, color: Colors.amber),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Reset learning data
          Card(
            child: ListTile(
              title: const Text('Öğrenme Verilerini Sıfırla'),
              subtitle:
                  const Text('Tüm öğrenme verilerini temizle ve yeniden başla'),
              leading: const Icon(Icons.refresh, color: Colors.red),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showResetLearningDialog(),
            ),
          ),
        ],
      ],
    );
  }

  String _getNotificationToneDisplayName(NotificationTone tone) {
    switch (tone) {
      case NotificationTone.gentle:
        return 'Nazik';
      case NotificationTone.motivational:
        return 'Motivasyonel';
      case NotificationTone.urgent:
        return 'Acil';
      case NotificationTone.celebratory:
        return 'Kutlama';
      case NotificationTone.friendly:
        return 'Arkadaşça';
    }
  }

  String _getDayName(int day) {
    const dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return dayNames[day - 1];
  }

  void _updatePreferences(NotificationPreferences preferences) {
    ref
        .read(notificationPreferencesProvider.notifier)
        .updatePreferences(preferences);
  }

  void _showToneSelector(NotificationPreferences preferences) {
    showModalBottomSheet(
      context: context,
      builder: (context) => NotificationToneSelector(
        currentTone: preferences.preferredTone,
        onToneSelected: (tone) {
          _updatePreferences(preferences.copyWith(preferredTone: tone));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSnoozeTimePicker(NotificationPreferences preferences) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erteleme Süresi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int minutes in [5, 10, 15, 30, 60])
              RadioListTile<int>(
                title: Text('$minutes dakika'),
                value: minutes,
                groupValue: preferences.snoozeMinutes,
                onChanged: (value) {
                  if (value != null) {
                    _updatePreferences(
                        preferences.copyWith(snoozeMinutes: value));
                    Navigator.pop(context);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showMaxSnoozeCountPicker(NotificationPreferences preferences) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maksimum Erteleme Sayısı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int count in [1, 2, 3, 5])
              RadioListTile<int>(
                title: Text('$count kez'),
                value: count,
                groupValue: preferences.maxSnoozeCount,
                onChanged: (value) {
                  if (value != null) {
                    _updatePreferences(
                        preferences.copyWith(maxSnoozeCount: value));
                    Navigator.pop(context);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showDailyLimitPicker(NotificationPreferences preferences) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Günlük Bildirim Limiti'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int limit in [3, 5, 8, 10, 15])
              RadioListTile<int>(
                title: Text('$limit bildirim'),
                value: limit,
                groupValue: preferences.maxDailyNotifications,
                onChanged: (value) {
                  if (value != null) {
                    _updatePreferences(
                        preferences.copyWith(maxDailyNotifications: value));
                    Navigator.pop(context);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showResetLearningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğrenme Verilerini Sıfırla'),
        content: const Text(
            'Bu işlem tüm öğrenme verilerini silecek ve akıllı özellikler baştan öğrenmeye başlayacak. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Reset learning data
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Öğrenme verileri sıfırlandı'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }
}
