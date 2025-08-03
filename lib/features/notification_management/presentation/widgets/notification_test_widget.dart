import 'package:flutter/material.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../../shared/services/enhanced_notification_service.dart';

class NotificationTestWidget extends StatefulWidget {
  final NotificationPreferences preferences;

  const NotificationTestWidget({
    super.key,
    required this.preferences,
  });

  @override
  State<NotificationTestWidget> createState() => _NotificationTestWidgetState();
}

class _NotificationTestWidgetState extends State<NotificationTestWidget> {
  final EnhancedNotificationService _notificationService =
      EnhancedNotificationService();
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Test Bildirimleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ayarlarınızı test etmek için örnek bildirimler gönderin.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTestButton(
                      'Rutin Hatırlatıcısı',
                      Icons.schedule,
                      Colors.blue,
                      () => _sendTestNotification(
                          NotificationType.routineReminder),
                    ),
                    _buildTestButton(
                      'Seri Uyarısı',
                      Icons.warning,
                      Colors.orange,
                      () =>
                          _sendTestNotification(NotificationType.streakWarning),
                    ),
                    _buildTestButton(
                      'Başarı',
                      Icons.emoji_events,
                      Colors.green,
                      () => _sendTestNotification(NotificationType.achievement),
                    ),
                    _buildTestButton(
                      'Motivasyon',
                      Icons.favorite,
                      Colors.pink,
                      () =>
                          _sendTestNotification(NotificationType.motivational),
                    ),
                  ],
                ),
                if (_isTesting) ...[
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Test bildirimi gönderiliyor...'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: _isTesting ? null : onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
      ),
    );
  }

  Future<void> _sendTestNotification(NotificationType type) async {
    if (!widget.preferences.notificationsEnabled) {
      _showMessage('Bildirimler kapalı. Önce bildirimleri etkinleştirin.');
      return;
    }

    if (!widget.preferences.isNotificationTypeEnabled(type)) {
      _showMessage('Bu bildirim türü kapalı.');
      return;
    }

    setState(() {
      _isTesting = true;
    });

    try {
      await _notificationService.initialize();

      final notification = _createTestNotification(type);
      await _notificationService.scheduleNotification(notification);

      _showMessage('Test bildirimi gönderildi! 📱');
    } catch (e) {
      _showMessage('Hata: Bildirim gönderilemedi.');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  NotificationModel _createTestNotification(NotificationType type) {
    final now = DateTime.now();

    switch (type) {
      case NotificationType.routineReminder:
        return NotificationModel(
          id: 'test_routine_${now.millisecondsSinceEpoch}',
          type: NotificationType.routineReminder,
          title: 'Test: Rutin Zamanı! ⏰',
          body: 'Bu bir test bildirimidir. Sabah rutininizi yapmayı unutmayın!',
          scheduledTime: now.add(const Duration(seconds: 5)),
          priority: NotificationPriority.normal,
          createdAt: now,
          userId: widget.preferences.userId,
          data: {
            'isTest': true,
            'routineName': 'Test Rutini',
          },
        );

      case NotificationType.streakWarning:
        return NotificationModel(
          id: 'test_streak_${now.millisecondsSinceEpoch}',
          type: NotificationType.streakWarning,
          title: 'Test: 🔥 Serin Risk Altında!',
          body: 'Bu bir test bildirimidir. 7 günlük harika serin kırılmasın!',
          scheduledTime: now.add(const Duration(seconds: 5)),
          priority: NotificationPriority.high,
          createdAt: now,
          userId: widget.preferences.userId,
          data: {
            'isTest': true,
            'streakDays': 7,
            'riskLevel': 'high',
          },
        );

      case NotificationType.achievement:
        return NotificationModel(
          id: 'test_achievement_${now.millisecondsSinceEpoch}',
          type: NotificationType.achievement,
          title: 'Test: 🎉 Harika Başarı!',
          body: 'Bu bir test bildirimidir. 7 günlük seri tamamladınız!',
          scheduledTime: now.add(const Duration(seconds: 5)),
          priority: NotificationPriority.high,
          createdAt: now,
          userId: widget.preferences.userId,
          data: {
            'isTest': true,
            'achievementType': 'weekly_streak',
          },
        );

      case NotificationType.motivational:
        return NotificationModel(
          id: 'test_motivational_${now.millisecondsSinceEpoch}',
          type: NotificationType.motivational,
          title: 'Test: Sen Harikasın! ✨',
          body:
              'Bu bir test bildirimidir. Bugün kendine iyi bakma konusunda ne kadar başarılısın?',
          scheduledTime: now.add(const Duration(seconds: 5)),
          priority: NotificationPriority.low,
          createdAt: now,
          userId: widget.preferences.userId,
          data: {
            'isTest': true,
            'motivationType': 'self_care',
          },
        );

      default:
        return NotificationModel(
          id: 'test_custom_${now.millisecondsSinceEpoch}',
          type: type,
          title: 'Test Bildirimi',
          body: 'Bu bir test bildirimidir.',
          scheduledTime: now.add(const Duration(seconds: 5)),
          priority: NotificationPriority.normal,
          createdAt: now,
          userId: widget.preferences.userId,
          data: {'isTest': true},
        );
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
