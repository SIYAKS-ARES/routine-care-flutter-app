import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/statistics_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/streak_card.dart';
import '../widgets/completion_chart.dart';
import '../widgets/weekly_progress_chart.dart';
import '../widgets/achievement_card.dart';
import '../../../../core/constants/app_constants.dart';

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPeriod = 30; // Default 30 days

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completionStats = ref.watch(completionStatsProvider(_selectedPeriod));
    final weeklyProgress = ref.watch(weeklyProgressProvider);
    final achievements = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics & Analytics'),
        centerTitle: true,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select Period',
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
              const PopupMenuItem(value: 90, child: Text('Last 3 months')),
              const PopupMenuItem(value: 365, child: Text('Last year')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Overview'),
            Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Achievements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Overview Tab
          _buildOverviewTab(theme, completionStats),

          // Trends Tab
          _buildTrendsTab(theme, weeklyProgress),

          // Achievements Tab
          _buildAchievementsTab(theme, achievements),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
      ThemeData theme, AsyncValue<StatisticsData> completionStats) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(completionStatsProvider(_selectedPeriod));
        ref.invalidate(weeklyProgressProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: completionStats.when(
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period indicator
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Showing data for last $_selectedPeriod days',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Key Statistics Grid
              _buildStatisticsGrid(theme, stats),
              const SizedBox(height: 24),

              // Streak Information
              _buildStreakSection(theme, stats),
              const SizedBox(height: 24),

              // Completion Rate Chart
              _buildCompletionChart(theme, stats),
              const SizedBox(height: 24),

              // Daily Average Section
              _buildDailyAverageSection(theme, stats),
            ],
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load statistics',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendsTab(
      ThemeData theme, AsyncValue<List<WeeklyProgress>> weeklyProgress) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Progress Trends',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          weeklyProgress.when(
            data: (data) => WeeklyProgressChart(data: data),
            loading: () => const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SizedBox(
              height: 200,
              child: Center(
                child: Text('Failed to load trends: $error'),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Monthly comparison
          _buildMonthlyComparison(theme),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(
      ThemeData theme, AsyncValue<List<Achievement>> achievements) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Achievements',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock badges by completing routines and building habits!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          achievements.when(
            data: (achievementList) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: achievementList.length,
              itemBuilder: (context, index) {
                return AchievementCard(achievement: achievementList[index]);
              },
            ),
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Center(
              child: Text('Failed to load achievements: $error'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid(ThemeData theme, StatisticsData stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        StatCard(
          title: 'Completion Rate',
          value: '${(stats.completionRate * 100).toStringAsFixed(1)}%',
          icon: Icons.check_circle,
          color: theme.colorScheme.primary,
          subtitle: '${stats.activeDays}/${stats.totalDays} days',
        ),
        StatCard(
          title: 'Current Streak',
          value: '${stats.currentStreak}',
          icon: Icons.local_fire_department,
          color: Colors.orange,
          subtitle: stats.currentStreak == 1 ? 'day' : 'days',
        ),
        StatCard(
          title: 'Best Streak',
          value: '${stats.longestStreak}',
          icon: Icons.star,
          color: Colors.amber,
          subtitle: stats.longestStreak == 1 ? 'day' : 'days',
        ),
        StatCard(
          title: 'Avg. Intensity',
          value: '${stats.averageIntensity.toStringAsFixed(1)}/10',
          icon: Icons.speed,
          color: theme.colorScheme.secondary,
          subtitle: 'Daily average',
        ),
      ],
    );
  }

  Widget _buildStreakSection(ThemeData theme, StatisticsData stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Streak Performance',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        StreakCard(
          currentStreak: stats.currentStreak,
          longestStreak: stats.longestStreak,
          streakGoal: 30, // 30-day goal
        ),
      ],
    );
  }

  Widget _buildCompletionChart(ThemeData theme, StatisticsData stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completion Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: CompletionChart(
                completedDays: stats.activeDays,
                totalDays: stats.totalDays,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyAverageSection(ThemeData theme, StatisticsData stats) {
    final dailyAverage =
        stats.totalDays > 0 ? stats.activeDays / stats.totalDays : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.today,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily Performance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: dailyAverage,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Average completion rate',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '${(dailyAverage * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyComparison(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Comparison',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Placeholder for monthly comparison chart
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Monthly comparison chart\ncoming soon!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
