import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../shared/models/achievement_model.dart';

// Extensions for enums
extension AchievementRarityExtension on AchievementRarity {
  String get displayName {
    switch (this) {
      case AchievementRarity.common:
        return 'Ortak';
      case AchievementRarity.uncommon:
        return 'Nadir';
      case AchievementRarity.rare:
        return 'Nadide';
      case AchievementRarity.epic:
        return 'Epik';
      case AchievementRarity.legendary:
        return 'Efsanevi';
    }
  }

  Color get color {
    switch (this) {
      case AchievementRarity.common:
        return const Color(0xFFCD7F32); // Bronze
      case AchievementRarity.uncommon:
        return const Color(0xFFC0C0C0); // Silver
      case AchievementRarity.rare:
        return const Color(0xFFFFD700); // Gold
      case AchievementRarity.epic:
        return const Color(0xFF9932CC); // Purple
      case AchievementRarity.legendary:
        return const Color(0xFFE5E4E2); // Platinum
    }
  }
}

extension AchievementTypeExtension on AchievementType {
  String get displayName {
    switch (this) {
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
        return 'Milestone';
      case AchievementType.special:
        return 'Özel';
    }
  }

  IconData get icon {
    switch (this) {
      case AchievementType.routine:
        return Icons.repeat;
      case AchievementType.goal:
        return Icons.flag;
      case AchievementType.streak:
        return Icons.local_fire_department;
      case AchievementType.category:
        return Icons.category;
      case AchievementType.time:
        return Icons.schedule;
      case AchievementType.milestone:
        return Icons.emoji_events;
      case AchievementType.special:
        return Icons.star;
    }
  }
}

class AchievementBadge extends StatelessWidget {
  final AchievementModel achievement;
  final double size;
  final bool showTitle;
  final bool showProgress;
  final VoidCallback? onTap;
  final bool isLocked;

  const AchievementBadge({
    super.key,
    required this.achievement,
    this.size = 80,
    this.showTitle = true,
    this.showProgress = false,
    this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeSize = size;
    final iconSize = badgeSize * 0.4;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge Container
          Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _getBadgeGradient(),
              boxShadow: [
                BoxShadow(
                  color: _getBadgeColor().withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: _getRarityAccentColor(),
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                // Background pattern
                _buildBackgroundPattern(),

                // Main icon
                Center(
                  child: Icon(
                    isLocked ? Icons.lock_rounded : achievement.icon,
                    size: iconSize,
                    color: isLocked ? Colors.grey[400] : Colors.white,
                  ),
                ),

                // Rarity indicator
                Positioned(
                  top: 4,
                  right: 4,
                  child: _buildRarityIndicator(),
                ),

                // Lock overlay
                if (isLocked) _buildLockOverlay(),

                // Progress indicator
                if (showProgress && !isLocked) _buildProgressIndicator(),
              ],
            ),
          ),

          if (showTitle) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: badgeSize + 20,
              child: Text(
                achievement.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isLocked
                      ? theme.colorScheme.onSurface.withOpacity(0.5)
                      : theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBadgeColor() {
    if (isLocked) return Colors.grey[400]!;
    return achievement.color;
  }

  Gradient _getBadgeGradient() {
    final color = _getBadgeColor();
    return RadialGradient(
      colors: [
        color.withOpacity(0.8),
        color,
        color.withOpacity(0.9),
      ],
      stops: const [0.0, 0.7, 1.0],
    );
  }

  Color _getRarityAccentColor() {
    if (isLocked) return Colors.grey[300]!;

    switch (achievement.rarity) {
      case AchievementRarity.common:
        return const Color(0xFF8BC34A);
      case AchievementRarity.uncommon:
        return const Color(0xFF2196F3);
      case AchievementRarity.rare:
        return const Color(0xFF9C27B0);
      case AchievementRarity.epic:
        return const Color(0xFFFF9800);
      case AchievementRarity.legendary:
        return const Color(0xFFFFD700);
    }
  }

  Widget _buildBackgroundPattern() {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: CustomPaint(
          painter: _BadgePatternPainter(
            rarity: achievement.rarity,
            isLocked: isLocked,
          ),
        ),
      ),
    );
  }

  Widget _buildRarityIndicator() {
    IconData rarityIcon;
    switch (achievement.rarity) {
      case AchievementRarity.common:
        rarityIcon = Icons.circle;
        break;
      case AchievementRarity.uncommon:
        rarityIcon = Icons.star_border_rounded;
        break;
      case AchievementRarity.rare:
        rarityIcon = Icons.star_rounded;
        break;
      case AchievementRarity.epic:
        rarityIcon = Icons.stars_rounded;
        break;
      case AchievementRarity.legendary:
        rarityIcon = Icons.auto_awesome_rounded;
        break;
    }

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: _getRarityAccentColor(),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Icon(
        rarityIcon,
        size: 10,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLockOverlay() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.6),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (achievement.currentProgress == 0) return const SizedBox.shrink();

    final totalProgress = achievement.unlockConditions.isNotEmpty
        ? achievement.unlockConditions.first.targetValue
        : 100;
    final progress = achievement.currentProgress / totalProgress;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: _getRarityAccentColor(),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgePatternPainter extends CustomPainter {
  final AchievementRarity rarity;
  final bool isLocked;

  _BadgePatternPainter({required this.rarity, required this.isLocked});

  @override
  void paint(Canvas canvas, Size size) {
    if (isLocked) return;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    switch (rarity) {
      case AchievementRarity.common:
        // Simple circle pattern
        canvas.drawCircle(center, radius * 0.7, paint);
        break;

      case AchievementRarity.uncommon:
        // Concentric circles
        canvas.drawCircle(center, radius * 0.6, paint);
        canvas.drawCircle(center, radius * 0.8, paint);
        break;

      case AchievementRarity.rare:
        // Star pattern
        _drawStar(canvas, center, radius * 0.3, paint);
        break;

      case AchievementRarity.epic:
        // Complex star with rays
        _drawStar(canvas, center, radius * 0.3, paint);
        _drawRays(canvas, center, radius * 0.8, paint);
        break;

      case AchievementRarity.legendary:
        // Elaborate pattern with multiple elements
        _drawStar(canvas, center, radius * 0.3, paint);
        _drawRays(canvas, center, radius * 0.8, paint);
        canvas.drawCircle(center, radius * 0.5, paint);
        break;
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final points = 5;
    final angle = 2 * math.pi / points;

    for (int i = 0; i < points; i++) {
      final x = center.dx + radius * 0.8 * math.cos(i * angle - math.pi / 2);
      final y = center.dy + radius * 0.8 * math.sin(i * angle - math.pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Inner point
      final innerX =
          center.dx + radius * 0.3 * math.cos((i + 0.5) * angle - math.pi / 2);
      final innerY =
          center.dy + radius * 0.3 * math.sin((i + 0.5) * angle - math.pi / 2);
      path.lineTo(innerX, innerY);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawRays(Canvas canvas, Offset center, double radius, Paint paint) {
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final startX = center.dx + radius * 0.6 * math.cos(angle);
      final startY = center.dy + radius * 0.6 * math.sin(angle);
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Achievement grid widget for displaying multiple badges
class AchievementGrid extends StatelessWidget {
  final List<AchievementModel> achievements;
  final double badgeSize;
  final bool showTitles;
  final bool showProgress;
  final Function(AchievementModel)? onAchievementTap;
  final int maxVisible;

  const AchievementGrid({
    super.key,
    required this.achievements,
    this.badgeSize = 48,
    this.showTitles = false,
    this.showProgress = false,
    this.onAchievementTap,
    this.maxVisible = 12,
  });

  @override
  Widget build(BuildContext context) {
    final visibleAchievements = achievements.take(maxVisible).toList();
    final hasMore = achievements.length > maxVisible;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...visibleAchievements.map((achievement) => AchievementBadge(
              achievement: achievement,
              size: badgeSize,
              showTitle: showTitles,
              showProgress: showProgress,
              onTap: () => onAchievementTap?.call(achievement),
            )),

        // Show "more" indicator if there are additional achievements
        if (hasMore) _buildMoreIndicator(context),
      ],
    );
  }

  Widget _buildMoreIndicator(BuildContext context) {
    final remainingCount = achievements.length - maxVisible;

    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          '+$remainingCount',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
        ),
      ),
    );
  }
}

// Recent achievements widget - horizontal scrollable list
class RecentAchievements extends StatelessWidget {
  final List<AchievementModel> achievements;
  final Function(AchievementModel)? onAchievementTap;

  const RecentAchievements({
    super.key,
    required this.achievements,
    this.onAchievementTap,
  });

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Son Kazanılan Başarımlar',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    AchievementBadge(
                      achievement: achievement,
                      size: 56,
                      onTap: () => onAchievementTap?.call(achievement),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 64,
                      child: Text(
                        achievement.title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Achievement rarity filter chips
class AchievementRarityFilter extends StatelessWidget {
  final AchievementRarity? selectedRarity;
  final Function(AchievementRarity?) onRarityChanged;
  final Map<AchievementRarity, int> counts;

  const AchievementRarityFilter({
    super.key,
    required this.selectedRarity,
    required this.onRarityChanged,
    this.counts = const {},
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // All filter
          _buildFilterChip(
            context,
            label: 'Hepsi',
            rarity: null,
            count: counts.values.fold(0, (sum, count) => sum + count),
          ),
          const SizedBox(width: 8),

          // Rarity filters
          ...AchievementRarity.values.map((rarity) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                  context,
                  label: rarity.displayName,
                  rarity: rarity,
                  count: counts[rarity] ?? 0,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required AchievementRarity? rarity,
    required int count,
  }) {
    final isSelected = selectedRarity == rarity;
    final color = rarity?.color ?? Colors.grey;

    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => onRarityChanged(rarity),
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.grey.shade300,
      ),
    );
  }
}

// Achievement type filter chips
class AchievementTypeFilter extends StatelessWidget {
  final AchievementType? selectedType;
  final Function(AchievementType?) onTypeChanged;
  final Map<AchievementType, int> counts;

  const AchievementTypeFilter({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.counts = const {},
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // All filter
          _buildFilterChip(
            context,
            label: 'Hepsi',
            type: null,
            icon: Icons.apps,
            count: counts.values.fold(0, (sum, count) => sum + count),
          ),
          const SizedBox(width: 8),

          // Type filters
          ...AchievementType.values.map((type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                  context,
                  label: type.displayName,
                  type: type,
                  icon: type.icon,
                  count: counts[type] ?? 0,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required AchievementType? type,
    required IconData icon,
    required int count,
  }) {
    final isSelected = selectedType == type;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text('$label ($count)'),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTypeChanged(type),
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Colors.blue : Colors.grey.shade300,
      ),
    );
  }
}
