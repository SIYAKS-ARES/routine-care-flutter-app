import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
class RoutineTile extends StatelessWidget {
  final String RoutineName;
  final bool RoutineCompleted;
  final Function(bool?)? onChanged;
  final Function(BuildContext)? settingsTapped;
  final Function(BuildContext)? deleteTapped;
  const RoutineTile({
    super.key,
    required this.RoutineName,
    required this.RoutineCompleted,
    required this.onChanged,
    required this.settingsTapped,
    required this.deleteTapped,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: settingsTapped,
              backgroundColor: Colors.grey.shade800,
              icon: Icons.settings,
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: deleteTapped,
              backgroundColor: Colors.red.shade400,
              icon: Icons.delete,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Checkbox(
                value: RoutineCompleted,
                onChanged: onChanged,
              ),
              Text(RoutineName),
            ],
          ),
        ),
      ),
    );
  }
}
