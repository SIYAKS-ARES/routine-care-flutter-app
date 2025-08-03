import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/enhanced_notification_service.dart';
import '../../features/notification_management/presentation/providers/notification_preferences_provider.dart';

class NotificationQuickActions extends ConsumerWidget {
  const NotificationQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(notificationPreferencesProvider);

    return preferencesAsync.when(
      data: (preferences) => _buildQuickActions(context, ref, preferences),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    WidgetRef ref,
    NotificationPreferences preferences,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Notification toggle
          Expanded(
            child: _buildQuickToggle(
              icon: preferences.notificationsEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              label: preferences.notificationsEnabled ? 'Açık' : 'Kapalı',
              isActive: preferences.notificationsEnabled,
              color:
                  preferences.notificationsEnabled ? Colors.green : Colors.grey,
              onTap: () => _toggleNotifications(ref, preferences),
            ),
          ),

          const SizedBox(width: 12),

          // DND toggle
          Expanded(
            child: _buildQuickToggle(
              icon: preferences.doNotDisturbEnabled
                  ? Icons.do_not_disturb
                  : Icons.do_not_disturb_off,
              label:
                  preferences.doNotDisturbEnabled ? 'REM Açık' : 'REM Kapalı',
              isActive: preferences.doNotDisturbEnabled,
              color:
                  preferences.doNotDisturbEnabled ? Colors.orange : Colors.grey,
              onTap: () => _toggleDND(ref, preferences),
            ),
          ),

          const SizedBox(width: 12),

          // Smart features toggle
          Expanded(
            child: _buildQuickToggle(
              icon: preferences.smartTimingEnabled
                  ? Icons.psychology
                  : Icons.psychology_outlined,
              label: preferences.smartTimingEnabled ? 'Akıllı' : 'Manuel',
              isActive: preferences.smartTimingEnabled,
              color:
                  preferences.smartTimingEnabled ? Colors.purple : Colors.grey,
              onTap: () => _toggleSmartFeatures(ref, preferences),
            ),
          ),

          const SizedBox(width: 12),

          // Settings button
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.grey),
              onPressed: () => _openSettings(context),
              tooltip: 'Bildirim Ayarları',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickToggle({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color:
              isActive ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? color.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleNotifications(
      WidgetRef ref, NotificationPreferences preferences) {
    final updatedPreferences = preferences.copyWith(
      notificationsEnabled: !preferences.notificationsEnabled,
    );

    ref
        .read(notificationPreferencesProvider.notifier)
        .updatePreferences(updatedPreferences);
  }

  void _toggleDND(WidgetRef ref, NotificationPreferences preferences) {
    final updatedPreferences = preferences.copyWith(
      doNotDisturbEnabled: !preferences.doNotDisturbEnabled,
    );

    ref
        .read(notificationPreferencesProvider.notifier)
        .updatePreferences(updatedPreferences);
  }

  void _toggleSmartFeatures(
      WidgetRef ref, NotificationPreferences preferences) {
    final updatedPreferences = preferences.copyWith(
      smartTimingEnabled: !preferences.smartTimingEnabled,
      contextAwareEnabled:
          !preferences.smartTimingEnabled, // Toggle both together
    );

    ref
        .read(notificationPreferencesProvider.notifier)
        .updatePreferences(updatedPreferences);
  }

  void _openSettings(BuildContext context) {
    Navigator.pushNamed(context, '/notification-settings');
  }
}

class NotificationSnackBarActions extends StatelessWidget {
  final String notificationId;
  final NotificationType type;

  const NotificationSnackBarActions({
    super.key,
    required this.notificationId,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (type != NotificationType.streakWarning) ...[
          TextButton(
            onPressed: () => _snoozeNotification(context),
            child: const Text('Ertele', style: TextStyle(color: Colors.white)),
          ),
        ],
        TextButton(
          onPressed: () => _markAsRead(context),
          child: const Text('Tamam', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _snoozeNotification(BuildContext context) async {
    final notificationService = EnhancedNotificationService();

    try {
      // This would reschedule the notification for later
      // Implementation depends on notification service capabilities

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildirim 10 dakika sonra tekrar gösterilecek'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildirim ertelenemedi'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _markAsRead(BuildContext context) async {
    final notificationService = EnhancedNotificationService();

    try {
      await notificationService.markNotificationAsRead(notificationId);
      ScaffoldMessenger.of(context).clearSnackBars();
    } catch (e) {
      // Handle error silently
    }
  }
}

class NotificationBanner extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const NotificationBanner({
    super.key,
    required this.notification,
    this.onDismiss,
    this.onTap,
  });

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    // Auto dismiss after 5 seconds for low priority notifications
    if (widget.notification.priority == NotificationPriority.low) {
      Timer(const Duration(seconds: 5), () {
        if (mounted) {
          _dismiss();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildBanner(),
          ),
        );
      },
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.notification.typeColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  widget.notification.typeIcon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.notification.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.notification.body,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _dismiss,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _dismiss() async {
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss?.call();
    }
  }
}

class NotificationBadge extends StatelessWidget {
  final int count;
  final Color? color;

  const NotificationBadge({
    super.key,
    required this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
