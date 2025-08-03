import 'package:flutter/material.dart';
import '../../../../shared/models/notification_model.dart';

class NotificationToneSelector extends StatelessWidget {
  final NotificationTone currentTone;
  final ValueChanged<NotificationTone> onToneSelected;

  const NotificationToneSelector({
    super.key,
    required this.currentTone,
    required this.onToneSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bildirim Tonu Seçin',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bildirimlerin hangi tonda size gönderilmesini istiyorsunuz?',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          for (final tone in NotificationTone.values)
            _buildToneOption(context, tone),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildToneOption(BuildContext context, NotificationTone tone) {
    final isSelected = tone == currentTone;
    final toneInfo = _getToneInfo(tone);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? tone.color.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () => onToneSelected(tone),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tone.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  toneInfo.icon,
                  color: tone.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      toneInfo.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? tone.color : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      toneInfo.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${toneInfo.example}"',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: tone.color,
                  size: 24,
                )
              else
                Icon(
                  Icons.radio_button_unchecked,
                  color: Colors.grey[400],
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  ToneInfo _getToneInfo(NotificationTone tone) {
    switch (tone) {
      case NotificationTone.gentle:
        return const ToneInfo(
          title: 'Nazik',
          description: 'Yumuşak ve kibar ifadeler kullanır',
          example:
              'Rutin zamanınız geldi. Hazır olduğunuzda başlayabilirsiniz.',
          icon: Icons.favorite,
        );

      case NotificationTone.motivational:
        return const ToneInfo(
          title: 'Motivasyonel',
          description: 'Enerjik ve ilham verici mesajlar',
          example: 'Harika! Hedefinize bir adım daha yaklaşma zamanı! 💪',
          icon: Icons.emoji_events,
        );

      case NotificationTone.urgent:
        return const ToneInfo(
          title: 'Acil',
          description: 'Dikkat çekici ve önemli konular için',
          example: 'Dikkat! Seriniz risk altında. Hemen harekete geçin! ⚠️',
          icon: Icons.warning,
        );

      case NotificationTone.celebratory:
        return const ToneInfo(
          title: 'Kutlama',
          description: 'Başarıları kutlayan neşeli mesajlar',
          example: 'Tebrikler! 7 günlük seriyi tamamladınız! 🎉',
          icon: Icons.celebration,
        );

      case NotificationTone.friendly:
        return const ToneInfo(
          title: 'Arkadaşça',
          description: 'Samimi ve dostane yaklaşım',
          example: 'Merhaba! Bugün kendinize nasıl bakacaksınız? 😊',
          icon: Icons.sentiment_satisfied,
        );
    }
  }
}

class ToneInfo {
  final String title;
  final String description;
  final String example;
  final IconData icon;

  const ToneInfo({
    required this.title,
    required this.description,
    required this.example,
    required this.icon,
  });
}

extension NotificationToneExtension on NotificationTone {
  Color get color {
    switch (this) {
      case NotificationTone.gentle:
        return Colors.blue;
      case NotificationTone.motivational:
        return Colors.orange;
      case NotificationTone.urgent:
        return Colors.red;
      case NotificationTone.celebratory:
        return Colors.purple;
      case NotificationTone.friendly:
        return Colors.green;
    }
  }
}
