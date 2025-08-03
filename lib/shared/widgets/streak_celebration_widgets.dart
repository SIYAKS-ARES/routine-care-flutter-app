import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/streak_model.dart';

class StreakMilestoneCelebration extends StatefulWidget {
  final StreakMilestone milestone;
  final int streakCount;
  final VoidCallback? onComplete;
  final bool showFullscreen;

  const StreakMilestoneCelebration({
    super.key,
    required this.milestone,
    required this.streakCount,
    this.onComplete,
    this.showFullscreen = true,
  });

  @override
  State<StreakMilestoneCelebration> createState() =>
      _StreakMilestoneCelebrationState();
}

class _StreakMilestoneCelebrationState extends State<StreakMilestoneCelebration>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _confettiController;
  late AnimationController _textController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.bounceOut,
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    // Haptic feedback
    HapticFeedback.heavyImpact();

    // Start animations
    _confettiController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _mainController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();

    // Auto close after animation
    await Future.delayed(const Duration(milliseconds: 4000));
    if (mounted) {
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _confettiController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showFullscreen) {
      return _buildCompactCelebration();
    }

    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          // Background tap to close
          GestureDetector(
            onTap: widget.onComplete,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),

          // Confetti animation
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                painter: ConfettiPainter(
                  progress: _confettiController.value,
                  color: widget.milestone.color,
                ),
                size: MediaQuery.of(context).size,
              );
            },
          ),

          // Main celebration content
          Center(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildCelebrationCard(),
                  ),
                );
              },
            ),
          ),

          // Sliding text
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.3,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  Text(
                    '🎉 TÜBRİKLER! 🎉',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        const Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 4,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.streakCount} günlük serinin var!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      shadows: [
                        const Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 2,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationCard() {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Milestone emoji with animation
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 2 * math.pi,
                child: Text(
                  widget.milestone.emoji,
                  style: const TextStyle(fontSize: 80),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Milestone title
          Text(
            widget.milestone.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.milestone.color,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Milestone description
          Text(
            widget.milestone.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Streak counter with pulsing animation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: widget.milestone.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: widget.milestone.color, width: 2),
            ),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.8, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Text(
                    '${widget.streakCount} Gün',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.milestone.color,
                        ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Close button
          ElevatedButton(
            onPressed: widget.onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.milestone.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Devam Et',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCelebration() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.milestone.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: widget.milestone.color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.milestone.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.milestone.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.streakCount} gün',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  final Color color;
  final List<ConfettiParticle> particles;

  ConfettiPainter({
    required this.progress,
    required this.color,
  }) : particles = List.generate(50, (index) => ConfettiParticle(index: index));

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final particle in particles) {
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = particle.color.withOpacity(opacity);

      final x = particle.startX * size.width +
          particle.velocityX * progress * size.width;
      final y = particle.startY * size.height +
          particle.velocityY * progress * size.height +
          0.5 * 9.8 * progress * progress * size.height;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation * progress * 4 * math.pi);

      if (particle.shape == ParticleShape.rectangle) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: 8, height: 4),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, 3, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ConfettiParticle {
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final Color color;
  final ParticleShape shape;

  ConfettiParticle({required int index})
      : startX = math.Random(index).nextDouble(),
        startY = math.Random(index + 1).nextDouble() * 0.3,
        velocityX = (math.Random(index + 2).nextDouble() - 0.5) * 2,
        velocityY = math.Random(index + 3).nextDouble() * 0.5 + 0.2,
        rotation = math.Random(index + 4).nextDouble(),
        color = [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
        ][index % 6],
        shape = math.Random(index + 5).nextBool()
            ? ParticleShape.rectangle
            : ParticleShape.circle;
}

enum ParticleShape { rectangle, circle }

class StreakMilestoneDialog extends StatelessWidget {
  final StreakMilestone milestone;
  final int streakCount;
  final VoidCallback? onContinue;

  const StreakMilestoneDialog({
    super.key,
    required this.milestone,
    required this.streakCount,
    this.onContinue,
  });

  static Future<void> show(
    BuildContext context, {
    required StreakMilestone milestone,
    required int streakCount,
    VoidCallback? onContinue,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreakMilestoneDialog(
        milestone: milestone,
        streakCount: streakCount,
        onContinue: onContinue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: StreakMilestoneCelebration(
        milestone: milestone,
        streakCount: streakCount,
        showFullscreen: false,
        onComplete: () {
          Navigator.of(context).pop();
          onContinue?.call();
        },
      ),
    );
  }
}

class StreakCelebrationOverlay extends StatefulWidget {
  final Widget child;
  final StreakMilestone? milestone;
  final int? streakCount;
  final VoidCallback? onCelebrationComplete;

  const StreakCelebrationOverlay({
    super.key,
    required this.child,
    this.milestone,
    this.streakCount,
    this.onCelebrationComplete,
  });

  @override
  State<StreakCelebrationOverlay> createState() =>
      _StreakCelebrationOverlayState();
}

class _StreakCelebrationOverlayState extends State<StreakCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _overlayController;
  bool _showingCelebration = false;

  @override
  void initState() {
    super.initState();
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(StreakCelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if we should show celebration
    if (widget.milestone != null &&
        widget.streakCount != null &&
        !_showingCelebration) {
      _showCelebration();
    }
  }

  void _showCelebration() async {
    setState(() {
      _showingCelebration = true;
    });

    await _overlayController.forward();

    // Show celebration for duration
    await Future.delayed(const Duration(milliseconds: 4000));

    await _overlayController.reverse();

    setState(() {
      _showingCelebration = false;
    });

    widget.onCelebrationComplete?.call();
  }

  @override
  void dispose() {
    _overlayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showingCelebration && widget.milestone != null)
          AnimatedBuilder(
            animation: _overlayController,
            builder: (context, child) {
              return Opacity(
                opacity: _overlayController.value,
                child: StreakMilestoneCelebration(
                  milestone: widget.milestone!,
                  streakCount: widget.streakCount!,
                  showFullscreen: true,
                  onComplete: () {
                    _overlayController.reverse().then((_) {
                      setState(() {
                        _showingCelebration = false;
                      });
                      widget.onCelebrationComplete?.call();
                    });
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}

// Küçük streak kutlama widget'ı (liste içinde kullanım için)
class MiniStreakCelebration extends StatefulWidget {
  final StreakMilestone milestone;
  final Duration duration;

  const MiniStreakCelebration({
    super.key,
    required this.milestone,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<MiniStreakCelebration> createState() => _MiniStreakCelebrationState();
}

class _MiniStreakCelebrationState extends State<MiniStreakCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.milestone.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.milestone.color.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                widget.milestone.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Streak kutlama yöneticisi
class StreakCelebrationManager {
  static void showMilestoneCelebration(
    BuildContext context, {
    required StreakMilestone milestone,
    required int streakCount,
    bool fullscreen = true,
  }) {
    if (fullscreen) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              StreakMilestoneCelebration(
            milestone: milestone,
            streakCount: streakCount,
            onComplete: () => Navigator.of(context).pop(),
          ),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      StreakMilestoneDialog.show(
        context,
        milestone: milestone,
        streakCount: streakCount,
      );
    }
  }

  static void showQuickCelebration(
    BuildContext context, {
    required StreakMilestone milestone,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        right: 20,
        child: MiniStreakCelebration(
          milestone: milestone,
          duration: const Duration(milliseconds: 2000),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(milliseconds: 2500), () {
      overlayEntry.remove();
    });
  }
}
