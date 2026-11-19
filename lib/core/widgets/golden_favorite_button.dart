import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Interactive Golden Favorite Star Button with Micro-Particle Burst.
///
/// Triggers a burst of 6 radiating gold spark rays and an elastic icon bounce
/// when toggled into the favorite state.
class GoldenFavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onToggle;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final String? tooltip;

  const GoldenFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onToggle,
    this.size = 24.0,
    this.activeColor,
    this.inactiveColor,
    this.tooltip,
  });

  @override
  State<GoldenFavoriteButton> createState() => _GoldenFavoriteButtonState();
}

class _GoldenFavoriteButtonState extends State<GoldenFavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _burstAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.65)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.65, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 35,
      ),
    ]).animate(_controller);

    _burstAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant GoldenFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isFavorite && widget.isFavorite) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isFavorite) {
      _controller.forward(from: 0.0);
    } else {
      _controller.forward(from: 0.0);
    }
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final activeCol = widget.activeColor ?? AppColors.gold;
    final inactiveCol = widget.inactiveColor ?? AppColors.muted;

    Widget button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: SizedBox(
        width: widget.size * 1.8,
        height: widget.size * 1.8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Micro-particle star burst sparks
            AnimatedBuilder(
              animation: _burstAnimation,
              builder: (context, _) {
                if (_burstAnimation.value == 0.0 || _burstAnimation.value == 1.0) {
                  return const SizedBox.shrink();
                }
                return CustomPaint(
                  size: Size(widget.size * 1.8, widget.size * 1.8),
                  painter: _StarBurstPainter(
                    progress: _burstAnimation.value,
                    color: activeCol,
                  ),
                );
              },
            ),

            // Spring bouncing star icon
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _controller.isAnimating ? _scaleAnimation.value : 1.0,
                  child: child,
                );
              },
              child: Icon(
                widget.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                size: widget.size,
                color: widget.isFavorite ? activeCol : inactiveCol,
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

class _StarBurstPainter extends CustomPainter {
  final double progress;
  final Color color;

  _StarBurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0))
      ..strokeWidth = 2.0 * (1.0 - progress * 0.5)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const rayCount = 7;
    final maxRadius = size.width * 0.46;
    final minRadius = size.width * 0.18;

    final currentInnerRadius = minRadius + (maxRadius - minRadius) * (progress * 0.6);
    final currentOuterRadius = minRadius + (maxRadius - minRadius) * progress;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i * 2 * math.pi / rayCount) - (math.pi / 2);
      final p1 = Offset(
        center.dx + currentInnerRadius * math.cos(angle),
        center.dy + currentInnerRadius * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + currentOuterRadius * math.cos(angle),
        center.dy + currentOuterRadius * math.sin(angle),
      );
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarBurstPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
