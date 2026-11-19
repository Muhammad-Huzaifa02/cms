import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Banking Frosted Glass Dual-Orbit Refresh Indicator.
///
/// Dual gold and emerald orbiting light beads rotating within a floating
/// frosted glass pill, creating an executive refresh indicator.
class GlassOrbitSpinner extends StatefulWidget {
  final double size;

  const GlassOrbitSpinner({super.key, this.size = 32});

  @override
  State<GlassOrbitSpinner> createState() => _GlassOrbitSpinnerState();
}

class _GlassOrbitSpinnerState extends State<GlassOrbitSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
      animation: _controller,
      builder: (context, _) {
        final angle = _controller.value * 2 * math.pi;

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: const Color(0xFF022B24).withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.0,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Orbit 1: Emerald Bead
              Transform.translate(
                offset: Offset(
                  math.cos(angle) * (widget.size * 0.28),
                  math.sin(angle) * (widget.size * 0.28),
                ),
                child: Container(
                  width: widget.size * 0.24,
                  height: widget.size * 0.24,
                  decoration: const BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brand,
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

              // Orbit 2: Gold Bead
              Transform.translate(
                offset: Offset(
                  math.cos(angle + math.pi) * (widget.size * 0.28),
                  math.sin(angle + math.pi) * (widget.size * 0.28),
                ),
                child: Container(
                  width: widget.size * 0.24,
                  height: widget.size * 0.24,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold,
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
