import 'package:flutter/material.dart';

enum TransitionType {
  fade,
  slide,
  scale,
  rotation,
  slideFromBottom,
  slideFromTop,
  slideFromLeft,
  slideFromRight,
}

class CustomPageTransition<T> extends PageRouteBuilder<T> {
  final Widget child;
  final TransitionType type;
  final Duration duration;
  final Duration reverseDuration;
  final Curve curve;

  CustomPageTransition({
    required this.child,
    this.type = TransitionType.slide,
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration = const Duration(milliseconds: 250),
    this.curve = Curves.easeInOut,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, _) => child,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (type) {
      case TransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );

      case TransitionType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );

      case TransitionType.slideFromBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );

      case TransitionType.slideFromTop:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );

      case TransitionType.slideFromLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );

      case TransitionType.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );

      case TransitionType.scale:
        return ScaleTransition(
          scale: animation,
          child: child,
        );

      case TransitionType.rotation:
        return RotationTransition(
          turns: animation,
          child: child,
        );

      default:
        return child;
    }
  }
}

// Hero-enabled button with smooth transitions
class HeroButton extends StatelessWidget {
  final String heroTag;
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const HeroButton({
    super.key,
    required this.heroTag,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Hero(
      tag: heroTag,
      child: Material(
        color: backgroundColor ?? theme.colorScheme.primary,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
            child: DefaultTextStyle(
              style: TextStyle(
                color: foregroundColor ?? theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// Hero Card with smooth transitions
class HeroCard extends StatelessWidget {
  final String heroTag;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final BorderRadius? borderRadius;

  const HeroCard({
    super.key,
    required this.heroTag,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: Card(
        margin: margin,
        elevation: elevation,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Animated Page Wrapper
class AnimatedPageWrapper extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AnimatedPageWrapper({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedPageWrapper> createState() => _AnimatedPageWrapperState();
}

class _AnimatedPageWrapperState extends State<AnimatedPageWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    // Start animation with delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
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
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// Utility functions for navigation with custom transitions
class AppNavigator {
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget page, {
    TransitionType transition = TransitionType.slide,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    String? routeName,
  }) {
    return Navigator.of(context).push<T>(
      CustomPageTransition(
        child: page,
        type: transition,
        duration: duration,
        curve: curve,
        settings: RouteSettings(name: routeName),
      ),
    );
  }

  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page, {
    TransitionType transition = TransitionType.slide,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    TO? result,
    String? routeName,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      CustomPageTransition(
        child: page,
        type: transition,
        duration: duration,
        curve: curve,
        settings: RouteSettings(name: routeName),
      ),
      result: result,
    );
  }

  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    Widget page,
    RoutePredicate predicate, {
    TransitionType transition = TransitionType.slide,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    String? routeName,
  }) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      CustomPageTransition(
        child: page,
        type: transition,
        duration: duration,
        curve: curve,
        settings: RouteSettings(name: routeName),
      ),
      predicate,
    );
  }

  // Modal sheet with custom animation
  static Future<T?> showCustomModalBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
      transitionAnimationController: AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: Navigator.of(context),
      ),
      builder: (context) => child,
    );
  }
}
