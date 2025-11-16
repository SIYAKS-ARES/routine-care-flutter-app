import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EnhancedRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double displacement;
  final Color? color;
  final Color? backgroundColor;
  final double strokeWidth;
  final String? refreshMessage;
  final IconData? refreshIcon;

  const EnhancedRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.displacement = 40.0,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 2.0,
    this.refreshMessage,
    this.refreshIcon,
  });

  @override
  State<EnhancedRefreshIndicator> createState() =>
      _EnhancedRefreshIndicatorState();
}

class _EnhancedRefreshIndicatorState extends State<EnhancedRefreshIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Start animations
    _controller.repeat();
    _scaleController.forward();

    try {
      await widget.onRefresh();

      // Success haptic
      HapticFeedback.lightImpact();
    } catch (e) {
      // Error haptic
      HapticFeedback.heavyImpact();
    } finally {
      // Stop animations
      _controller.stop();
      _scaleController.reverse();

      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      displacement: widget.displacement,
      color: widget.color ?? colorScheme.primary,
      backgroundColor: widget.backgroundColor ?? colorScheme.surface,
      strokeWidth: widget.strokeWidth,
      child: Stack(
        children: [
          widget.child,

          // Custom refresh indicator overlay
          if (_isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.primary.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated refresh icon
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _controller.value * 2 * math.pi,
                                child: Icon(
                                  widget.refreshIcon ?? Icons.refresh_rounded,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                              );
                            },
                          ),

                          const SizedBox(width: 8),

                          // Refresh message
                          Text(
                            widget.refreshMessage ?? 'Refreshing...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Pull-to-refresh with success/error feedback
class SmartRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String? successMessage;
  final String? errorMessage;
  final Duration feedbackDuration;
  final Color? color;
  final Color? backgroundColor;

  const SmartRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.successMessage,
    this.errorMessage,
    this.feedbackDuration = const Duration(seconds: 2),
    this.color,
    this.backgroundColor,
  });

  @override
  State<SmartRefreshIndicator> createState() => _SmartRefreshIndicatorState();
}

class _SmartRefreshIndicatorState extends State<SmartRefreshIndicator>
    with TickerProviderStateMixin {
  late AnimationController _feedbackController;
  late Animation<Offset> _slideAnimation;
  String? _feedbackMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();

    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    try {
      await widget.onRefresh();

      // Show success feedback
      _showFeedback(
        widget.successMessage ?? 'Updated successfully!',
        true,
      );
    } catch (e) {
      // Show error feedback
      _showFeedback(
        widget.errorMessage ?? 'Update failed. Please try again.',
        false,
      );
    }
  }

  void _showFeedback(String message, bool isSuccess) {
    setState(() {
      _feedbackMessage = message;
      _isSuccess = isSuccess;
    });

    _feedbackController.forward().then((_) {
      Future.delayed(widget.feedbackDuration, () {
        if (mounted) {
          _feedbackController.reverse().then((_) {
            setState(() {
              _feedbackMessage = null;
            });
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _handleRefresh,
          color: widget.color ?? colorScheme.primary,
          backgroundColor: widget.backgroundColor ?? colorScheme.surface,
          child: widget.child,
        ),

        // Feedback banner
        if (_feedbackMessage != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? Colors.green.withOpacity(0.9)
                      : colorScheme.error.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Icon(
                        _isSuccess
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _feedbackMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Animated pull indicator widget
class AnimatedPullIndicator extends StatefulWidget {
  final double pullDistance;
  final double maxPullDistance;
  final bool isActive;
  final Color? color;

  const AnimatedPullIndicator({
    super.key,
    required this.pullDistance,
    required this.maxPullDistance,
    required this.isActive,
    this.color,
  });

  @override
  State<AnimatedPullIndicator> createState() => _AnimatedPullIndicatorState();
}

class _AnimatedPullIndicatorState extends State<AnimatedPullIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedPullIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress =
        (widget.pullDistance / widget.maxPullDistance).clamp(0.0, 1.0);

    return SizedBox(
      height: 60,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress circle
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: widget.isActive ? null : progress,
                strokeWidth: 3,
                color: widget.color ?? colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),

            // Center icon
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: widget.isActive ? _controller.value * 2 * math.pi : 0,
                  child: Icon(
                    widget.isActive
                        ? Icons.refresh_rounded
                        : progress > 0.8
                            ? Icons.arrow_downward_rounded
                            : Icons.expand_more_rounded,
                    color: widget.color ?? colorScheme.primary,
                    size: 20,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
