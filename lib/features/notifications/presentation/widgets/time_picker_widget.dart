import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class TimePickerWidget extends StatelessWidget {
  final TimeOfDay? selectedTime;
  final ValueChanged<TimeOfDay?> onTimeChanged;
  final String label;
  final bool isEnabled;

  const TimePickerWidget({
    super.key,
    required this.selectedTime,
    required this.onTimeChanged,
    required this.label,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isEnabled ? null : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        InkWell(
          onTap: isEnabled ? () => _showTimePicker(context) : null,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: isEnabled
                    ? theme.colorScheme.outline
                    : theme.colorScheme.outline.withOpacity(0.3),
              ),
              borderRadius:
                  BorderRadius.circular(AppConstants.cardBorderRadius),
              color: isEnabled
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: isEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedTime != null
                        ? _formatTime(selectedTime!)
                        : 'Zaman seçin',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: selectedTime != null
                          ? (isEnabled
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (selectedTime != null && isEnabled) ...[
                  IconButton(
                    onPressed: () => onTimeChanged(null),
                    icon: Icon(
                      Icons.clear,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    tooltip: 'Zamanı temizle',
                  ),
                ] else ...[
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: isEnabled
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final TimeOfDay initialTime = selectedTime ?? TimeOfDay.now();

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      onTimeChanged(pickedTime);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
