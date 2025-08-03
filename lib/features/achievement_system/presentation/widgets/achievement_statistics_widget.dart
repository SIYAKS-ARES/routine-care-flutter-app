import 'package:flutter/material.dart';
import '../../domain/entities/achievement_statistics.dart';
import '../../domain/entities/user_progress.dart';
import '../../../../shared/models/achievement_model.dart';

class AchievementStatisticsWidget extends StatelessWidget {
  final AchievementStatistics statistics;
  final UserProgress userProgress;

  const AchievementStatisticsWidget({
    super.key,
    required this.statistics,
    required this.userProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall stats
        _buildOverallStats(context, theme),

        const SizedBox(height: 24),

        // Rarity breakdown
        _buildRarityBreakdown(context, theme),

        const SizedBox(height: 24),

        // Type breakdown
        _buildTypeBreakdown(context, theme),

        const SizedBox(height: 24),

        // Progress stats
        _buildProgressStats(context, theme),
      ],
    );
  }

  Widget _buildOverallStats(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Genel İstatistikler',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Açılan Başarımlar',
                    '${statistics.unlockedAchievements}',
                    '${statistics.totalAchievements} toplam',
                    Icons.emoji_events_rounded,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Tamamlama Oranı',
                    '${statistics.completionRate.toStringAsFixed(1)}%',
                    'Genel ilerleme',
                    Icons.pie_chart_rounded,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Toplam XP',
                    '${statistics.totalExperiencePoints}',
                    'Kazanılan deneyim',
                    Icons.stars_rounded,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'En Uzun Seri',
                    '${statistics.longestStreak}',
                    'günlük başarım',
                    Icons.local_fire_department_rounded,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRarityBreakdown(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nadirlik Dağılımı',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...AchievementRarity.values.map((rarity) {
              final count = statistics.rarityBreakdown[rarity] ?? 0;
              final color = _getRarityColor(rarity);
              final name = _getRarityName(rarity);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildProgressBar(
                  context,
                  name,
                  count,
                  statistics.totalAchievements,
                  color,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBreakdown(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tür Dağılımı',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...AchievementType.values.map((type) {
              final count = statistics.typeBreakdown[type] ?? 0;
              final color = _getTypeColor(type);
              final name = _getTypeName(type);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildProgressBar(
                  context,
                  name,
                  count,
                  statistics.totalAchievements,
                  color,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStats(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İlerleme Detayları',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildProgressDetail(
              context,
              'Rutin Tamamlamaları',
              userProgress.routineCompletions,
              Icons.repeat_rounded,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildProgressDetail(
              context,
              'Hedef Tamamlamaları',
              userProgress.goalCompletions,
              Icons.flag_rounded,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildProgressDetail(
              context,
              'Mevcut Seri',
              userProgress.currentStreak,
              Icons.local_fire_department_rounded,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildProgressDetail(
              context,
              'Ardışık Günler',
              userProgress.consecutiveDays,
              Icons.calendar_today_rounded,
              Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildProgressDetail(
              context,
              'Toplam Zaman',
              userProgress.totalTimeSpent,
              Icons.schedule_rounded,
              Colors.teal,
              suffix: ' dakika',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    String label,
    int current,
    int total,
    Color color,
  ) {
    final theme = Theme.of(context);
    final percentage = total > 0 ? (current / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$current',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 4),
        Text(
          '${(percentage * 100).toStringAsFixed(1)}% tamamlandı',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressDetail(
    BuildContext context,
    String label,
    int value,
    IconData icon,
    Color color, {
    String suffix = '',
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$value$suffix',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRarityName(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Ortak';
      case AchievementRarity.uncommon:
        return 'Nadir';
      case AchievementRarity.rare:
        return 'Ender';
      case AchievementRarity.epic:
        return 'Epik';
      case AchievementRarity.legendary:
        return 'Efsane';
    }
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }

  String _getTypeName(AchievementType type) {
    switch (type) {
      case AchievementType.routine:
        return 'Rutin';
      case AchievementType.goal:
        return 'Hedef';
      case AchievementType.streak:
        return 'Seri';
      case AchievementType.category:
        return 'Kategori';
      case AchievementType.time:
        return 'Zaman';
      case AchievementType.milestone:
        return 'Mil Taşı';
      case AchievementType.special:
        return 'Özel';
    }
  }

  Color _getTypeColor(AchievementType type) {
    switch (type) {
      case AchievementType.routine:
        return Colors.blue;
      case AchievementType.goal:
        return Colors.green;
      case AchievementType.streak:
        return Colors.orange;
      case AchievementType.category:
        return Colors.purple;
      case AchievementType.time:
        return Colors.teal;
      case AchievementType.milestone:
        return Colors.amber;
      case AchievementType.special:
        return Colors.pink;
    }
  }
}
