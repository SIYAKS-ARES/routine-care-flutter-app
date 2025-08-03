import 'package:flutter/material.dart';

class GoalProgressIndicator extends StatelessWidget {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double height;
  final BorderRadius? borderRadius;
  final bool showAnimation;

  const GoalProgressIndicator({
    super.key,
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.height = 8,
    this.borderRadius,
    this.showAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
        child: Stack(
          children: [
            if (showAnimation)
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                width: double.infinity,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius:
                          borderRadius ?? BorderRadius.circular(height / 2),
                    ),
                  ),
                ),
              )
            else
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius:
                        borderRadius ?? BorderRadius.circular(height / 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
