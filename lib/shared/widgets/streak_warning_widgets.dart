import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/streak_model.dart';

class StreakRiskIndicator extends StatefulWidget {
  final StreakModel streak;
  final double size;
  final bool showText;

  const StreakRiskIndicator({
    super.key,
    required this.streak,
    this.size = 24.0,
    this.showText = true,
  });

  @override
  State<StreakRiskIndicator> createState() => _StreakRiskIndicatorState();
}

class _StreakRiskIndicatorState extends State<StreakRiskIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.streak.riskLevel > 0.5) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final riskLevel = widget.streak.riskLevel;
    final riskColor = _getRiskColor(riskLevel);
    final riskIcon = _getRiskIcon(riskLevel);
    final riskText = _getRiskText(riskLevel);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: riskLevel > 0.5 ? _pulseAnimation.value : 1.0,
              child: Icon(
                riskIcon,
                size: widget.size,
                color: riskColor,
              ),
            );
          },
        ),
        if (widget.showText) ...[
          const SizedBox(width: 4),
          Text(
            riskText,
            style: TextStyle(
              color: riskColor,
              fontSize: widget.size * 0.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Color _getRiskColor(double riskLevel) {
    if (riskLevel <= 0.3) return Colors.green;
    if (riskLevel <= 0.6) return Colors.orange;
    return Colors.red;
  }

  IconData _getRiskIcon(double riskLevel) {
    if (riskLevel <= 0.3) return Icons.check_circle;
    if (riskLevel <= 0.6) return Icons.warning;
    return Icons.error;
  }

  String _getRiskText(double riskLevel) {
    if (riskLevel <= 0.3) return 'Güvenli';
    if (riskLevel <= 0.6) return 'Dikkat';
    return 'Risk';
  }
}

class StreakWarningCard extends StatelessWidget {
  final StreakModel streak;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  const StreakWarningCard({
    super.key,
    required this.streak,
    this.onAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final riskLevel = streak.riskLevel;

    if (riskLevel <= 0.3) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      color: _getCardColor(riskLevel),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StreakRiskIndicator(
                  streak: streak,
                  size: 24,
                  showText: false,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getWarningTitle(riskLevel),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getTextColor(riskLevel),
                        ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: _getTextColor(riskLevel),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getWarningMessage(riskLevel, streak.currentStreak),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getTextColor(riskLevel),
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: _getTextColor(riskLevel).withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  _getTimeRemaining(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getTextColor(riskLevel).withOpacity(0.7),
                      ),
                ),
              ],
            ),
            if (onAction != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getButtonColor(riskLevel),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_getActionText()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getCardColor(double riskLevel) {
    if (riskLevel <= 0.6) return Colors.orange.shade50;
    return Colors.red.shade50;
  }

  Color _getTextColor(double riskLevel) {
    if (riskLevel <= 0.6) return Colors.orange.shade800;
    return Colors.red.shade800;
  }

  Color _getButtonColor(double riskLevel) {
    if (riskLevel <= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getWarningTitle(double riskLevel) {
    if (riskLevel <= 0.6) return '⚠️ Serini Kaybetme Riski';
    return '🚨 Serin Tehlikede!';
  }

  String _getWarningMessage(double riskLevel, int streakCount) {
    if (riskLevel <= 0.6) {
      return '$streakCount günlük serin risk altında. Bugün rutinini tamamlayarak serini koruyabilirsin.';
    }
    return '$streakCount günlük harika serin kırılmak üzere! Hemen harekete geçerek bu muhteşem başarını koruyabilirsin.';
  }

  String _getTimeRemaining() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final remaining = endOfDay.difference(now);

    if (remaining.inHours > 0) {
      return '${remaining.inHours} saat kaldı';
    } else {
      return '${remaining.inMinutes} dakika kaldı';
    }
  }

  String _getActionText() {
    return 'Rutinini Tamamla';
  }
}

class StreakRiskBanner extends StatefulWidget {
  final List<StreakModel> riskStreaks;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const StreakRiskBanner({
    super.key,
    required this.riskStreaks,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<StreakRiskBanner> createState() => _StreakRiskBannerState();
}

class _StreakRiskBannerState extends State<StreakRiskBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _visible = true;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _slideController.reverse();
    setState(() {
      _visible = false;
    });
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || widget.riskStreaks.isEmpty) {
      return const SizedBox.shrink();
    }

    final highestRisk =
        widget.riskStreaks.map((s) => s.riskLevel).reduce(math.max);

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              highestRisk > 0.6 ? Colors.red.shade100 : Colors.orange.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highestRisk > 0.6 ? Colors.red : Colors.orange,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Icon(
                highestRisk > 0.6 ? Icons.warning : Icons.notifications,
                color: highestRisk > 0.6 ? Colors.red : Colors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getBannerTitle(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: highestRisk > 0.6
                                ? Colors.red.shade800
                                : Colors.orange.shade800,
                          ),
                    ),
                    Text(
                      _getBannerMessage(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: highestRisk > 0.6
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                          ),
                    ),
                  ],
                ),
              ),
              if (widget.onDismiss != null)
                IconButton(
                  onPressed: _dismiss,
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: highestRisk > 0.6 ? Colors.red : Colors.orange,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBannerTitle() {
    if (widget.riskStreaks.length == 1) {
      return 'Bir serin risk altında';
    }
    return '${widget.riskStreaks.length} serin risk altında';
  }

  String _getBannerMessage() {
    final totalDays =
        widget.riskStreaks.map((s) => s.currentStreak).reduce((a, b) => a + b);
    return '$totalDays günlük birikimini korumak için harekete geç!';
  }
}

class StreakMotivationDialog extends StatefulWidget {
  final StreakModel streak;
  final VoidCallback? onComplete;
  final VoidCallback? onPostpone;

  const StreakMotivationDialog({
    super.key,
    required this.streak,
    this.onComplete,
    this.onPostpone,
  });

  static Future<void> show(
    BuildContext context, {
    required StreakModel streak,
    VoidCallback? onComplete,
    VoidCallback? onPostpone,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreakMotivationDialog(
        streak: streak,
        onComplete: onComplete,
        onPostpone: onPostpone,
      ),
    );
  }

  @override
  State<StreakMotivationDialog> createState() => _StreakMotivationDialogState();
}

class _StreakMotivationDialogState extends State<StreakMotivationDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _heartAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeInOut,
    ));

    _scaleController.forward();
    _heartController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Motivational icon
              AnimatedBuilder(
                animation: _heartAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _heartAnimation.value,
                    child: const Text(
                      '💪',
                      style: TextStyle(fontSize: 60),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              Text(
                'Harika Gidiyorsun!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                '${widget.streak.currentStreak} günlük serinin muhteşem! Bugün de devam ettirerek bu başarını taçlandırmaya ne dersin?',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[700],
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Progress indication
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mevcut Serin',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.orange.shade700,
                                    ),
                          ),
                          Text(
                            '${widget.streak.currentStreak} gün',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.streak.nextMilestone != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Sonraki Hedef',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.orange.shade700,
                                    ),
                          ),
                          Text(
                            '${widget.streak.nextMilestone!.days} gün',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  if (widget.onPostpone != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onPostpone?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                        child: const Text('Sonra'),
                      ),
                    ),
                  if (widget.onPostpone != null) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onComplete?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Devam Edelim!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StreakReminderWidget extends StatelessWidget {
  final List<StreakModel> streaks;
  final VoidCallback? onActionTap;

  const StreakReminderWidget({
    super.key,
    required this.streaks,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final riskyStreaks = streaks.where((s) => s.riskLevel > 0.3).toList();

    if (riskyStreaks.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade100,
            Colors.orange.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Günlük Hatırlatıcı',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getReminderMessage(riskyStreaks.length),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.orange.shade700,
                ),
          ),
          const SizedBox(height: 12),
          ...riskyStreaks.take(3).map((streak) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: Colors.orange.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getStreakName(streak),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${streak.currentStreak} gün',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.orange.shade800,
                          ),
                    ),
                  ],
                ),
              )),
          if (riskyStreaks.length > 3) ...[
            const SizedBox(height: 4),
            Text(
              've ${riskyStreaks.length - 3} seri daha...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade600,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
          if (onActionTap != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onActionTap,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Rutinlere Git'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getReminderMessage(int count) {
    if (count == 1) {
      return 'Bir serin bugün tamamlanmayı bekliyor. Harika serini sürdürmeye ne dersin?';
    }
    return '$count serin bugün tamamlanmayı bekliyor. Bu harika momentum\'u sürdürelim!';
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

// Streak warning notification helper
class StreakWarningManager {
  static void showMotivationDialog(
    BuildContext context, {
    required StreakModel streak,
    VoidCallback? onComplete,
    VoidCallback? onPostpone,
  }) {
    StreakMotivationDialog.show(
      context,
      streak: streak,
      onComplete: onComplete,
      onPostpone: onPostpone,
    );
  }

  static void showGentleReminder(
    BuildContext context, {
    required List<StreakModel> riskyStreaks,
  }) {
    if (riskyStreaks.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          riskyStreaks.length == 1
              ? 'Serini korumak için bugün rutinini tamamlamayı unutma! 🔥'
              : '${riskyStreaks.length} serin bugün tamamlanmayı bekliyor! 💪',
        ),
        action: SnackBarAction(
          label: 'Git',
          onPressed: () {
            // Navigate to routines
          },
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static bool shouldShowWarning(StreakModel streak) {
    return streak.isActive &&
        streak.riskLevel > 0.3 &&
        streak.currentStreak >= 3;
  }

  static List<StreakModel> getStreaksAtRisk(List<StreakModel> allStreaks) {
    return allStreaks.where(shouldShowWarning).toList();
  }
}
