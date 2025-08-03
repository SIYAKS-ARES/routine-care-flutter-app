import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/user_level_model.dart';

class LevelProgressIndicator extends StatefulWidget {
  final UserLevelModel userLevel;
  final double size;
  final bool showTitle;
  final bool showExperience;
  final bool animated;
  final VoidCallback? onTap;

  const LevelProgressIndicator({
    super.key,
    required this.userLevel,
    this.size = 120,
    this.showTitle = true,
    this.showExperience = true,
    this.animated = true,
    this.onTap,
  });

  @override
  State<LevelProgressIndicator> createState() => _LevelProgressIndicatorState();
}

class _LevelProgressIndicatorState extends State<LevelProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.userLevel.progressToNextLevel,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticInOut,
    ));

    if (widget.animated) {
      _progressController.forward();
      _pulseController.repeat(reverse: true);
    } else {
      _progressController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelTier =
        LevelSystemConfig.getLevelTier(widget.userLevel.currentLevel);

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main circular progress
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation:
                  Listenable.merge([_progressAnimation, _pulseAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.animated ? _pulseAnimation.value : 1.0,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _LevelProgressPainter(
                      progress: widget.animated
                          ? _progressAnimation.value
                          : widget.userLevel.progressToNextLevel,
                      levelTier: levelTier,
                      userLevel: widget.userLevel,
                    ),
                    child: _buildCenterContent(theme, levelTier),
                  ),
                );
              },
            ),
          ),

          if (widget.showTitle) ...[
            const SizedBox(height: 12),
            _buildTitleSection(theme, levelTier),
          ],

          if (widget.showExperience) ...[
            const SizedBox(height: 8),
            _buildExperienceSection(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildCenterContent(ThemeData theme, LevelTier levelTier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Level number
          Text(
            '${widget.userLevel.currentLevel}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.3),
                ),
              ],
            ),
          ),

          // Level icon
          Icon(
            levelTier.icon,
            color: Colors.white.withOpacity(0.9),
            size: widget.size * 0.15,
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(ThemeData theme, LevelTier levelTier) {
    return Column(
      children: [
        Text(
          levelTier.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: levelTier.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          levelTier.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildExperienceSection(ThemeData theme) {
    return Column(
      children: [
        Text(
          '${widget.userLevel.currentExperience} / ${widget.userLevel.currentExperience + widget.userLevel.experienceToNextLevel} XP',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.userLevel.experienceToNextLevel} XP to next level',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _LevelProgressPainter extends CustomPainter {
  final double progress;
  final LevelTier levelTier;
  final UserLevelModel userLevel;

  _LevelProgressPainter({
    required this.progress,
    required this.levelTier,
    required this.userLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background circle
    final backgroundPaint = Paint()
      ..color = levelTier.color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = _createGradient(size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // Inner glow circle
    final glowPaint = Paint()
      ..color = levelTier.color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius - 20, glowPaint);

    // Main background circle
    final mainPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          levelTier.color.withOpacity(0.8),
          levelTier.color,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 20))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius - 20, mainPaint);

    // Progress dots (for higher levels)
    if (userLevel.currentLevel >= 10) {
      _drawProgressDots(canvas, center, radius, progress);
    }
  }

  void _drawProgressDots(
      Canvas canvas, Offset center, double radius, double progress) {
    final dotCount = 12;
    final dotRadius = 3.0;
    final activeDots = (dotCount * progress).round();

    for (int i = 0; i < dotCount; i++) {
      final angle = (2 * math.pi * i / dotCount) - (math.pi / 2);
      final dotCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      final dotPaint = Paint()
        ..color = i < activeDots ? Colors.white : Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(dotCenter, dotRadius, dotPaint);
    }
  }

  Shader _createGradient(Size size) {
    return LinearGradient(
      colors: [
        levelTier.color,
        levelTier.color.withOpacity(0.7),
        Colors.white.withOpacity(0.9),
      ],
      stops: const [0.0, 0.7, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _LevelProgressPainter ||
        oldDelegate.progress != progress ||
        oldDelegate.levelTier != levelTier;
  }
}

// Compact level indicator for smaller spaces
class CompactLevelIndicator extends StatelessWidget {
  final UserLevelModel userLevel;
  final bool showProgress;

  const CompactLevelIndicator({
    super.key,
    required this.userLevel,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelTier = LevelSystemConfig.getLevelTier(userLevel.currentLevel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            levelTier.color.withOpacity(0.8),
            levelTier.color,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: levelTier.color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            levelTier.icon,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Lv.${userLevel.currentLevel}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showProgress) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              height: 4,
              child: LinearProgressIndicator(
                value: userLevel.progressToNextLevel,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Level benefits showcase widget
class LevelBenefitsShowcase extends StatelessWidget {
  final UserLevelModel userLevel;
  final bool showLocked;

  const LevelBenefitsShowcase({
    super.key,
    required this.userLevel,
    this.showLocked = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTier = LevelSystemConfig.getLevelTier(userLevel.currentLevel);
    final nextTier = LevelSystemConfig.getNextLevelTier(userLevel.currentLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Benefits',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Current benefits
        if (currentTier.benefits.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: currentTier.benefits
                .map((benefit) =>
                    _buildBenefitChip(context, benefit, isActive: true))
                .toList(),
          )
        else
          Text(
            'No benefits unlocked yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),

        // Next level benefits
        if (showLocked && nextTier != null) ...[
          const SizedBox(height: 20),
          Text(
            'Unlock at Level ${nextTier.level}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: nextTier.benefits
                .where((benefit) => !currentTier.benefits.contains(benefit))
                .map((benefit) =>
                    _buildBenefitChip(context, benefit, isActive: false))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildBenefitChip(BuildContext context, LevelBenefit benefit,
      {required bool isActive}) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.onSurface.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getBenefitIcon(benefit),
            size: 16,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(width: 6),
          Text(
            _getBenefitName(benefit),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isActive
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withOpacity(0.5),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBenefitIcon(LevelBenefit benefit) {
    switch (benefit) {
      case LevelBenefit.customThemes:
        return Icons.palette_rounded;
      case LevelBenefit.extraReminderSlots:
        return Icons.notifications_active_rounded;
      case LevelBenefit.advancedStatistics:
        return Icons.analytics_rounded;
      case LevelBenefit.premiumBadges:
        return Icons.workspace_premium_rounded;
      case LevelBenefit.prioritySupport:
        return Icons.support_agent_rounded;
      case LevelBenefit.exportData:
        return Icons.download_rounded;
      case LevelBenefit.unlimitedRoutines:
        return Icons.all_inclusive_rounded;
      case LevelBenefit.categoryCustomization:
        return Icons.tune_rounded;
      case LevelBenefit.achievementBonus:
        return Icons.emoji_events_rounded;
      case LevelBenefit.specialCelebrations:
        return Icons.celebration_rounded;
    }
  }

  String _getBenefitName(LevelBenefit benefit) {
    switch (benefit) {
      case LevelBenefit.customThemes:
        return 'Custom Themes';
      case LevelBenefit.extraReminderSlots:
        return 'Extra Reminders';
      case LevelBenefit.advancedStatistics:
        return 'Advanced Stats';
      case LevelBenefit.premiumBadges:
        return 'Premium Badges';
      case LevelBenefit.prioritySupport:
        return 'Priority Support';
      case LevelBenefit.exportData:
        return 'Data Export';
      case LevelBenefit.unlimitedRoutines:
        return 'Unlimited Routines';
      case LevelBenefit.categoryCustomization:
        return 'Category Customization';
      case LevelBenefit.achievementBonus:
        return 'Achievement Bonus';
      case LevelBenefit.specialCelebrations:
        return 'Special Celebrations';
    }
  }
}
