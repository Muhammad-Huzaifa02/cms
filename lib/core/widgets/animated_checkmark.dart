import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated Drawing Checkmark SVG/Path Painter.
///
/// Smoothly animates a crisp banking checkmark path stroke when a form field
/// becomes valid, giving instant confidence to the user during entry.
class AnimatedCheckmark extends StatefulWidget {
  final bool isValid;
  final double size;
  final Color color;

  const AnimatedCheckmark({
    super.key,
    required this.isValid,
    this.size = 20.0,
    this.color = AppColors.brand,
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    if (widget.isValid) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCheckmark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isValid != oldWidget.isValid) {
      if (widget.isValid) {
        _controller.forward(from: 0.0);
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _checkAnimation,
      builder: (context, _) {
        final progress = _checkAnimation.value;
        if (progress <= 0.01) {
          return SizedBox(width: widget.size, height: widget.size);
        }

        return Transform.scale(
          scale: 0.6 + (0.4 * progress),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.12 * progress),
            ),
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _CheckmarkPainter(
                progress: progress,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final p1 = Offset(size.width * 0.28, size.height * 0.52);
    final p2 = Offset(size.width * 0.44, size.height * 0.68);
    final p3 = Offset(size.width * 0.74, size.height * 0.34);

    final path = Path();
    path.moveTo(p1.dx, p1.dy);

    if (progress <= 0.45) {
      final t = progress / 0.45;
      final currentX = p1.dx + (p2.dx - p1.dx) * t;
      final currentY = p1.dy + (p2.dy - p1.dy) * t;
      path.lineTo(currentX, currentY);
    } else {
      path.lineTo(p2.dx, p2.dy);
      final t = (progress - 0.45) / 0.55;
      final currentX = p2.dx + (p3.dx - p2.dx) * t;
      final currentY = p2.dy + (p3.dy - p2.dy) * t;
      path.lineTo(currentX, currentY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
