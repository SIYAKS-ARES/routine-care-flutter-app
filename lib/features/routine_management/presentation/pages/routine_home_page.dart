import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/routine_tile.dart';
import '../../../../shared/widgets/month_summary.dart';
import '../../../../shared/widgets/add_routine_fab.dart';
import '../../../../shared/widgets/enhanced_routine_dialog.dart';
import '../../../../shared/widgets/notification_quick_settings.dart';
import '../../../../shared/widgets/completion_celebration.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../../../shared/widgets/custom_page_transitions.dart';
import '../../../../shared/widgets/enhanced_refresh_indicator.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import '../../../notifications/presentation/pages/notification_settings_page.dart';
import '../providers/routine_provider.dart';
// import '../../../authentication/presentation/providers/auth_provider.dart'; // Geçici olarak kapalı
// import '../../../authentication/presentation/pages/user_profile_page.dart'; // Geçici olarak kapalı

class RoutineHomePage extends ConsumerStatefulWidget {
  const RoutineHomePage({super.key});

  @override
  ConsumerState<RoutineHomePage> createState() => _RoutineHomePageState();
}

class _RoutineHomePageState extends ConsumerState<RoutineHomePage> {
  final _routineNameController = TextEditingController();
  final Map<String, bool> _celebrationStates = {};

  @override
  void dispose() {
    _routineNameController.dispose();
    super.dispose();
  }

  void _showAddRoutineDialog() {
    showDialog(
      context: context,
      builder: (context) => EnhancedRoutineDialog(
        onSave: _addNewRoutineWithTime,
        onCancel: _cancelDialog,
      ),
    );
  }

  void _addNewRoutine() {
    final routineName = _routineNameController.text.trim();
    if (routineName.isNotEmpty) {
      ref.read(routineNotifierProvider.notifier).addRoutine(routineName);
      _routineNameController.clear();
      Navigator.of(context).pop();
    }
  }

  void _addNewRoutineWithTime(String name, TimeOfDay? reminderTime) {
    ref
        .read(routineNotifierProvider.notifier)
        .addRoutineWithTime(name, reminderTime);
    Navigator.of(context).pop();
  }

  void _cancelDialog() {
    _routineNameController.clear();
    Navigator.of(context).pop();
  }

  void _showEditRoutineDialog(String routineId, String currentName) {
    final routinesAsync = ref.read(routineNotifierProvider);
    final routine = routinesAsync
        .whenData((routines) => routines.firstWhere((r) => r.id == routineId));

    routine.whenData((routineModel) {
      showDialog(
        context: context,
        builder: (context) => EnhancedRoutineDialog(
          existingRoutine: routineModel,
          onSave: (name, reminderTime) =>
              _editRoutineWithTime(routineId, name, reminderTime),
          onCancel: _cancelDialog,
        ),
      );
    });
  }

  void _editRoutine(String routineId) {
    final newName = _routineNameController.text.trim();
    if (newName.isNotEmpty) {
      ref
          .read(routineNotifierProvider.notifier)
          .updateRoutineName(routineId, newName);
      _routineNameController.clear();
      Navigator.of(context).pop();
    }
  }

  void _editRoutineWithTime(
      String routineId, String name, TimeOfDay? reminderTime) {
    ref
        .read(routineNotifierProvider.notifier)
        .updateRoutineWithTime(routineId, name, reminderTime);
    Navigator.of(context).pop();
  }

  void _navigateToSettings() {
    AppNavigator.push(
      context,
      const NotificationSettingsPage(),
      transition: TransitionType.slideFromBottom,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _navigateToStatistics() {
    AppNavigator.push(
      context,
      const StatisticsPage(),
      transition: TransitionType.slideFromRight,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final routinesAsync = ref.watch(routineNotifierProvider);
    final heatMapData = ref.watch(heatMapDataProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Routine Care'),
        actions: [
          // Statistics button
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _navigateToStatistics,
            tooltip: 'Statistics & Analytics',
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      floatingActionButton: AddRoutineFab(onPressed: _showAddRoutineDialog),
      body: SmartRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(routineNotifierProvider);
          ref.invalidate(heatMapDataProvider);
        },
        successMessage: 'Routines updated! 🎉',
        errorMessage: 'Failed to update. Please try again.',
        color: theme.colorScheme.primary,
        child: routinesAsync.when(
          data: (routines) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Welcome message (geçici local user)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.waving_hand,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back!',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Ready to continue your routine journey?',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Quick stats preview
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${routines.where((r) => r.isCompleted).length}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                'completed',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              heatMapData.when(
                data: (data) => MonthSummary(
                  datasets: data.heatMapDataSet,
                  startDate: data.startDate,
                ),
                loading: () => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Welcome card skeleton
                      SkeletonLoading(
                        width: double.infinity,
                        height: 100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 16),

                      // Month summary skeleton
                      SkeletonLoading(
                        width: double.infinity,
                        height: 200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 16),

                      // Action buttons skeleton
                      Row(
                        children: [
                          Expanded(
                            child: SkeletonLoading(
                              height: 48,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SkeletonLoading(
                              height: 48,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Routine tiles skeleton
                      const SkeletonLoadingList(itemCount: 4),
                    ],
                  ),
                ),
                error: (error, stack) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // Quick actions row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _navigateToStatistics,
                      icon: const Icon(Icons.analytics),
                      label: const Text('View Analytics'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showAddRoutineDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Routine'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notification quick settings
              const NotificationQuickSettings(),
              const SizedBox(height: 16),

              if (routines.isEmpty)
                EnhancedEmptyState(
                  title: 'No routines yet',
                  subtitle:
                      'Create your first routine and start building better habits! Set daily goals and track your progress.',
                  icon: Icons.self_improvement_rounded,
                  actionText: 'Add Your First Routine',
                  onAction: _showAddRoutineDialog,
                  color: theme.colorScheme.primary,
                )
              else ...[
                // Routines section header
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        'Today\'s Routines',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${routines.where((r) => r.isCompleted).length}/${routines.length}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Reorderable routines list
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: routines.length,
                  onReorder: (oldIndex, newIndex) {
                    ref
                        .read(routineNotifierProvider.notifier)
                        .reorderRoutines(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final routine = routines[index];
                    return Container(
                      key: ValueKey(routine.id),
                      child: CompletionCelebration(
                        showCelebration:
                            _celebrationStates[routine.id] ?? false,
                        onCelebrationComplete: () {
                          setState(() {
                            _celebrationStates[routine.id] = false;
                          });
                        },
                        child: Stack(
                          children: [
                            RoutineTile(
                              routine: routine,
                              category:
                                  null, // TODO: Implement category provider
                              onChanged: (value) {
                                final wasCompleted = routine.isCompleted;
                                ref
                                    .read(routineNotifierProvider.notifier)
                                    .toggleRoutineCompletion(routine.id);

                                // Show celebration for completion (not unchecking)
                                if (!wasCompleted && value == true) {
                                  setState(() {
                                    _celebrationStates[routine.id] = true;
                                  });

                                  // Show achievement toast after a delay
                                  Future.delayed(
                                      const Duration(milliseconds: 800), () {
                                    if (mounted) {
                                      showAchievementToast(
                                        context,
                                        title: 'Great job! 🎉',
                                        description:
                                            'You completed "${routine.name}"',
                                        icon: Icons.task_alt_rounded,
                                        color: Colors.green,
                                      );
                                    }
                                  });
                                }
                              },
                              onEdit: () => _showEditRoutineDialog(
                                  routine.id, routine.name),
                              onDelete: () {
                                ref
                                    .read(routineNotifierProvider.notifier)
                                    .deleteRoutine(routine.id);
                              },
                            ),

                            // Drag handle
                            Positioned(
                              right: 8,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 32,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.6),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          loading: () => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Welcome card skeleton
                SkeletonLoading(
                  width: double.infinity,
                  height: 100,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 16),

                // Month summary skeleton
                SkeletonLoading(
                  width: double.infinity,
                  height: 200,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 16),

                // Action buttons skeleton
                Row(
                  children: [
                    Expanded(
                      child: SkeletonLoading(
                        height: 48,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SkeletonLoading(
                        height: 48,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Routine tiles skeleton
                const SkeletonLoadingList(itemCount: 4),
              ],
            ),
          ),
          error: (error, stack) => EnhancedEmptyState(
            title: 'Something went wrong',
            subtitle:
                'We encountered an error while loading your routines. Please try again.',
            icon: Icons.error_outline_rounded,
            actionText: 'Try Again',
            onAction: () {
              ref.invalidate(routineNotifierProvider);
            },
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}
