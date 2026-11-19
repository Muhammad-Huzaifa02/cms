import 'package:flutter/material.dart';

/// Periodic Specular Light Sheen sweep across status badges.
///
/// Sweeps a diagonal frosted light ray across the badge with an interval
/// pause, reinforcing live security and real-time status.
class ShimmerSheenBadge extends StatefulWidget {
  final Widget child;
  final Duration sweepDuration;
  final Duration pauseDuration;

  const ShimmerSheenBadge({
    super.key,
    required this.child,
    this.sweepDuration = const Duration(milliseconds: 1100),
    this.pauseDuration = const Duration(milliseconds: 3200),
  });

  @override
  State<ShimmerSheenBadge> createState() => _ShimmerSheenBadgeState();
}

class _ShimmerSheenBadgeState extends State<ShimmerSheenBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _sheenAnimation;

  @override
  void initState() {
    super.initState();
    final totalDuration = widget.sweepDuration + widget.pauseDuration;
    _controller = AnimationController(
      vsync: this,
      duration: totalDuration,
    );

    // Only run the sheen during the first portion of the total loop
    final sweepRatio = widget.sweepDuration.inMilliseconds / totalDuration.inMilliseconds;
    _sheenAnimation = Tween<double>(begin: -1.2, end: 2.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, sweepRatio, curve: Curves.easeInOutSine),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.repeat();
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
      animation: _sheenAnimation,
      builder: (context, child) {
        // Only show sheen overlay during sweep interval
        final sweepRatio = widget.sweepDuration.inMilliseconds /
            (_controller.duration?.inMilliseconds ?? 4300);
        final isSweeping = _controller.value <= sweepRatio;

        return Stack(
          alignment: Alignment.center,
          children: [
            widget.child,
            if (isSweeping)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Transform.translate(
                    offset: Offset(_sheenAnimation.value * 70.0, 0),
                    child: Transform.rotate(
                      angle: 0.35,
                      child: Container(
                        width: 18,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.42),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
