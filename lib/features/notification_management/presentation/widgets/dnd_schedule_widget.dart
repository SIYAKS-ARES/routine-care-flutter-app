import 'package:flutter/material.dart';
import '../../../../shared/models/notification_model.dart';

class DNDScheduleWidget extends StatelessWidget {
  final NotificationPreferences preferences;
  final ValueChanged<NotificationPreferences> onPreferencesChanged;

  const DNDScheduleWidget({
    super.key,
    required this.preferences,
    required this.onPreferencesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Rahatsız Etme Saatleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),

          ListTile(
            title: const Text('Başlangıç Saati'),
            subtitle: Text(
              preferences.doNotDisturbStart != null
                  ? _formatTime(preferences.doNotDisturbStart!)
                  : 'Belirlenmemiş',
            ),
            leading: const Icon(Icons.bedtime),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectStartTime(context),
          ),

          ListTile(
            title: const Text('Bitiş Saati'),
            subtitle: Text(
              preferences.doNotDisturbEnd != null
                  ? _formatTime(preferences.doNotDisturbEnd!)
                  : 'Belirlenmemiş',
            ),
            leading: const Icon(Icons.wb_sunny),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectEndTime(context),
          ),

          if (preferences.doNotDisturbStart != null &&
              preferences.doNotDisturbEnd != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getDNDPeriodInfo(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Quick presets
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Hızlı Ayarlar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip(
                  context,
                  'Gece (22:00 - 07:00)',
                  const TimeOfDay(hour: 22, minute: 0),
                  const TimeOfDay(hour: 7, minute: 0),
                ),
                _buildPresetChip(
                  context,
                  'Uyku (23:00 - 08:00)',
                  const TimeOfDay(hour: 23, minute: 0),
                  const TimeOfDay(hour: 8, minute: 0),
                ),
                _buildPresetChip(
                  context,
                  'Çalışma (09:00 - 17:00)',
                  const TimeOfDay(hour: 9, minute: 0),
                  const TimeOfDay(hour: 17, minute: 0),
                ),
                _buildPresetChip(
                  context,
                  'Öğle Molası (12:00 - 13:00)',
                  const TimeOfDay(hour: 12, minute: 0),
                  const TimeOfDay(hour: 13, minute: 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(
    BuildContext context,
    String label,
    TimeOfDay start,
    TimeOfDay end,
  ) {
    final isSelected = preferences.doNotDisturbStart == start &&
        preferences.doNotDisturbEnd == end;

    return ActionChip(
      label: Text(label),
      onPressed: () => _setDNDPeriod(start, end),
      backgroundColor: isSelected ? Colors.orange.withOpacity(0.2) : null,
      side: isSelected ? const BorderSide(color: Colors.orange) : null,
    );
  }

  void _selectStartTime(BuildContext context) async {
    final initialTime =
        preferences.doNotDisturbStart ?? const TimeOfDay(hour: 22, minute: 0);

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Rahatsız Etme Başlangıç Saati',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time != null) {
      onPreferencesChanged(
        preferences.copyWith(doNotDisturbStart: time),
      );
    }
  }

  void _selectEndTime(BuildContext context) async {
    final initialTime =
        preferences.doNotDisturbEnd ?? const TimeOfDay(hour: 7, minute: 0);

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Rahatsız Etme Bitiş Saati',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time != null) {
      onPreferencesChanged(
        preferences.copyWith(doNotDisturbEnd: time),
      );
    }
  }

  void _setDNDPeriod(TimeOfDay start, TimeOfDay end) {
    onPreferencesChanged(
      preferences.copyWith(
        doNotDisturbStart: start,
        doNotDisturbEnd: end,
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getDNDPeriodInfo() {
    if (preferences.doNotDisturbStart == null ||
        preferences.doNotDisturbEnd == null) {
      return 'Saatleri ayarlayın';
    }

    final start = preferences.doNotDisturbStart!;
    final end = preferences.doNotDisturbEnd!;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes > endMinutes) {
      // Overnight period
      return '${_formatTime(start)} - ${_formatTime(end)} (Gece boyunca)';
    } else {
      // Same day period
      final duration = endMinutes - startMinutes;
      final hours = duration ~/ 60;
      final minutes = duration % 60;

      String durationText = '';
      if (hours > 0) {
        durationText += '$hours saat';
        if (minutes > 0) {
          durationText += ' $minutes dakika';
        }
      } else {
        durationText = '$minutes dakika';
      }

      return '${_formatTime(start)} - ${_formatTime(end)} ($durationText)';
    }
  }
}
