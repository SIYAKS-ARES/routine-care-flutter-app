import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/streak_model.dart';

class StreakIndicator extends StatefulWidget {
  final StreakModel streak;
  final double size;
  final bool showNumber;
  final bool animated;
  final VoidCallback? onTap;

  const StreakIndicator({
    super.key,
    required this.streak,
    this.size = 24.0,
    this.showNumber = true,
    this.animated = true,
    this.onTap,
  });

  @override
  State<StreakIndicator> createState() => _StreakIndicatorState();
}

class _StreakIndicatorState extends State<StreakIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _flameController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _flameAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _flameController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _flameAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _flameController,
      curve: Curves.elasticOut,
    ));

    if (widget.animated && widget.streak.isActive) {
      _pulseController.repeat(reverse: true);
      _flameController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size * 1.5,
        height: widget.size * 1.5,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect for active streaks
            if (widget.streak.isActive && widget.animated)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getStreakColor().withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Main streak icon
            AnimatedBuilder(
              animation: widget.animated
                  ? _flameAnimation
                  : AlwaysStoppedAnimation(1.0),
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.animated ? _flameAnimation.value : 1.0,
                  child: _buildStreakIcon(),
                );
              },
            ),

            // Streak number overlay
            if (widget.showNumber && widget.streak.currentStreak > 0)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _getStreakColor(),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  constraints: BoxConstraints(
                    minWidth: widget.size * 0.4,
                    minHeight: widget.size * 0.4,
                  ),
                  child: Center(
                    child: Text(
                      '${widget.streak.currentStreak}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.size * 0.25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakIcon() {
    if (!widget.streak.isActive || widget.streak.currentStreak == 0) {
      return Icon(
        Icons.local_fire_department_outlined,
        size: widget.size,
        color: Colors.grey,
      );
    }

    // Get milestone for different fire intensities
    final milestone = widget.streak.currentMilestone;
    return Text(
      _getFireEmoji(),
      style: TextStyle(fontSize: widget.size),
    );
  }

  String _getFireEmoji() {
    final streak = widget.streak.currentStreak;
    if (streak >= 365) return '👑🔥👑';
    if (streak >= 200) return '💎🔥💎';
    if (streak >= 100) return '🏆🔥🏆';
    if (streak >= 50) return '🔥🔥🔥🔥🔥';
    if (streak >= 30) return '🔥🔥🔥🔥';
    if (streak >= 14) return '🔥🔥🔥';
    if (streak >= 7) return '🔥🔥';
    if (streak >= 3) return '🔥';
    return '🔥';
  }

  Color _getStreakColor() {
    if (!widget.streak.isActive) return Colors.grey;

    final milestone = widget.streak.currentMilestone;
    return milestone?.color ?? Colors.orange;
  }
}

class StreakProgressBar extends StatefulWidget {
  final StreakModel streak;
  final double height;
  final double borderRadius;
  final bool showMilestoneText;

  const StreakProgressBar({
    super.key,
    required this.streak,
    this.height = 8.0,
    this.borderRadius = 4.0,
    this.showMilestoneText = true,
  });

  @override
  State<StreakProgressBar> createState() => _StreakProgressBarState();
}

class _StreakProgressBarState extends State<StreakProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.streak.progressToNextMilestone,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextMilestone = widget.streak.nextMilestone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showMilestoneText && nextMilestone != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sonraki Hedef: ${nextMilestone.title}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                '${widget.streak.currentStreak}/${nextMilestone.days}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: nextMilestone.color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    nextMilestone?.color ?? Colors.orange,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class StreakMilestoneWidget extends StatelessWidget {
  final StreakMilestone milestone;
  final bool isAchieved;
  final bool isCurrent;
  final double size;

  const StreakMilestoneWidget({
    super.key,
    required this.milestone,
    this.isAchieved = false,
    this.isCurrent = false,
    this.size = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isAchieved ? milestone.color : Colors.grey[200],
        border: Border.all(
          color: isCurrent ? milestone.color : Colors.transparent,
          width: 3,
        ),
        boxShadow: isAchieved
            ? [
                BoxShadow(
                  color: milestone.color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            milestone.emoji,
            style: TextStyle(fontSize: size * 0.3),
          ),
          Text(
            '${milestone.days}',
            style: TextStyle(
              fontSize: size * 0.15,
              fontWeight: FontWeight.bold,
              color: isAchieved ? Colors.white : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class StreakCard extends StatelessWidget {
  final StreakModel streak;
  final VoidCallback? onTap;
  final bool showProgress;

  const StreakCard({
    super.key,
    required this.streak,
    this.onTap,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StreakIndicator(
                    streak: streak,
                    size: 32,
                    animated: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStreakTitle(),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          _getStreakSubtitle(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  _buildStreakStats(context),
                ],
              ),
              if (showProgress && streak.nextMilestone != null) ...[
                const SizedBox(height: 16),
                StreakProgressBar(streak: streak),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getStreakTitle() {
    switch (streak.type) {
      case StreakType.overall:
        return 'Genel Seri';
      case StreakType.routine:
        return 'Rutin Serisi';
      case StreakType.category:
        return 'Kategori Serisi';
      case StreakType.daily:
        return 'Günlük Seri';
      case StreakType.perfect:
        return 'Mükemmel Gün Serisi';
    }
  }

  String _getStreakSubtitle() {
    if (!streak.isActive) {
      return 'Seri kırıldı • En uzun: ${streak.longestStreak} gün';
    }

    final milestone = streak.currentMilestone;
    if (milestone != null) {
      return '${milestone.title} • ${streak.currentStreak} gün';
    }

    return '${streak.currentStreak} gün aktif';
  }

  Widget _buildStreakStats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${streak.currentStreak}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: streak.isActive ? Colors.orange : Colors.grey,
              ),
        ),
        Text(
          'gün',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}

class StreakFireAnimation extends StatefulWidget {
  final double size;
  final int intensity; // 1-5
  final bool isActive;

  const StreakFireAnimation({
    super.key,
    this.size = 30.0,
    this.intensity = 1,
    this.isActive = true,
  });

  @override
  State<StreakFireAnimation> createState() => _StreakFireAnimationState();
}

class _StreakFireAnimationState extends State<StreakFireAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(widget.intensity, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 500 + (index * 200)),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    if (widget.isActive) {
      for (int i = 0; i < _controllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 100), () {
          if (mounted) {
            _controllers[i].repeat(reverse: true);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Icon(
        Icons.local_fire_department_outlined,
        size: widget.size,
        color: Colors.grey,
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(widget.intensity, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _animations[index].value,
                child: Text(
                  '🔥',
                  style: TextStyle(
                    fontSize: widget.size * (0.8 + (index * 0.1)),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// Streak özet widget'ı
class StreakSummaryCard extends StatelessWidget {
  final List<StreakModel> streaks;
  final VoidCallback? onViewAll;

  const StreakSummaryCard({
    super.key,
    required this.streaks,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final activeStreaks = streaks.where((s) => s.isActive).toList();
    final longestStreak = streaks.isNotEmpty
        ? streaks.map((s) => s.longestStreak).reduce(math.max)
        : 0;
    final totalStreaks = activeStreaks.length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seri Durumu',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('Tümünü Gör'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: '🔥',
                    title: 'Aktif Seriler',
                    value: '$totalStreaks',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: '🏆',
                    title: 'En Uzun Seri',
                    value: '$longestStreak gün',
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            if (activeStreaks.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ...activeStreaks.take(3).map((streak) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        StreakIndicator(
                          streak: streak,
                          size: 20,
                          showNumber: false,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getStreakName(streak),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '${streak.currentStreak} gün',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getStreakName(StreakModel streak) {
    switch (streak.type) {
      case StreakType.overall:
        return 'Genel Aktivite';
      case StreakType.routine:
        return 'Rutin Serisi';
      case StreakType.category:
        return 'Kategori Serisi';
      case StreakType.daily:
        return 'Günlük Seri';
      case StreakType.perfect:
        return 'Mükemmel Günler';
    }
  }
}
