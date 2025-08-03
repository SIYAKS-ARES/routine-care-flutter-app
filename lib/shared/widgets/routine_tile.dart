import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/routine_model.dart';
import '../models/category_model.dart';

class RoutineTile extends StatefulWidget {
  final RoutineModel routine;
  final CategoryModel? category;
  final Function(bool?)? onChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showStreak;
  final bool showReminder;

  const RoutineTile({
    super.key,
    required this.routine,
    this.category,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
    this.showStreak = true,
    this.showReminder = true,
  });

  @override
  State<RoutineTile> createState() => _RoutineTileState();
}

class _RoutineTileState extends State<RoutineTile>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    ));

    if (widget.routine.isCompleted) {
      _checkController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RoutineTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.routine.isCompleted != oldWidget.routine.isCompleted) {
      if (widget.routine.isCompleted) {
        _checkController.forward();
      } else {
        _checkController.reverse();
      }
    }
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });

    widget.onChanged?.call(!widget.routine.isCompleted);

    if (!widget.routine.isCompleted) {
      HapticFeedback.selectionClick();
    }
  }

  Color get _categoryColor {
    return widget.category?.color ?? Theme.of(context).colorScheme.primary;
  }

  int get _currentStreak {
    if (widget.routine.completionHistory.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();
    final sortedHistory = widget.routine.completionHistory.toList()
      ..sort((a, b) => b.compareTo(a));

    for (final date in sortedHistory) {
      final dayDiff = today.difference(date).inDays;
      if (dayDiff == streak) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  String get _reminderTimeText {
    if (widget.routine.reminderTime == null) return '';
    final time = widget.routine.reminderTime!;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Slidable(
            endActionPane: ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) {
                    HapticFeedback.mediumImpact();
                    widget.onEdit?.call();
                  },
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  borderRadius: BorderRadius.circular(16),
                ),
                SlidableAction(
                  onPressed: (_) {
                    HapticFeedback.heavyImpact();
                    widget.onDelete?.call();
                  },
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  icon: Icons.delete_rounded,
                  label: 'Delete',
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: widget.routine.isCompleted ? 1 : 3,
                shadowColor: _categoryColor.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: widget.routine.isCompleted
                        ? _categoryColor.withOpacity(0.3)
                        : _categoryColor.withOpacity(0.1),
                    width: widget.routine.isCompleted ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: _handleTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: widget.routine.isCompleted
                          ? LinearGradient(
                              colors: [
                                _categoryColor.withOpacity(0.1),
                                _categoryColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Custom Checkbox with Animation
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.routine.isCompleted
                                  ? _categoryColor
                                  : colorScheme.outline,
                              width: 2,
                            ),
                            color: widget.routine.isCompleted
                                ? _categoryColor
                                : Colors.transparent,
                          ),
                          child: AnimatedBuilder(
                            animation: _checkAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _checkAnimation.value,
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: widget.routine.isCompleted
                                      ? colorScheme.onPrimary
                                      : Colors.transparent,
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Main Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Routine Name
                              Text(
                                widget.routine.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: widget.routine.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: widget.routine.isCompleted
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                ),
                              ),

                              // Description
                              if (widget.routine.description != null &&
                                  widget.routine.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.routine.description!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],

                              // Stats Row
                              if (widget.showStreak ||
                                  (widget.showReminder &&
                                      _reminderTimeText.isNotEmpty)) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    // Streak indicator
                                    if (widget.showStreak &&
                                        _currentStreak > 0) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons
                                                  .local_fire_department_rounded,
                                              size: 14,
                                              color: Colors.orange[700],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$_currentStreak',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                color: Colors.orange[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],

                                    // Reminder time
                                    if (widget.showReminder &&
                                        _reminderTimeText.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              _categoryColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.schedule_rounded,
                                              size: 14,
                                              color: _categoryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _reminderTimeText,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                color: _categoryColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Category indicator
                        if (widget.category != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _categoryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
