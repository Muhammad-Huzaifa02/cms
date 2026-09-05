import 'package:flutter/material.dart';

/// Wraps any widget (customer cards, buttons) with a physical "press down"
/// 3D animation on tap — slight scale-down + shadow flattening, then
/// spring back on release. Matches the embossed-card look from the UI
/// concept doc.
class TiltTapCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const TiltTapCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(15)),
  });

  @override
  State<TiltTapCard> createState() => _TiltTapCardState();
}

class _TiltTapCardState extends State<TiltTapCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    lowerBound: 0.0,
    upperBound: 1.0,
  );

  void _down(_) => _ctrl.forward();
  void _up(_) => _ctrl.reverse();
  void _cancel() => _ctrl.reverse();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : _down,
      onTapUp: widget.onTap == null ? null : _up,
      onTapCancel: widget.onTap == null ? null : _cancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        child: widget.child,
        builder: (context, child) {
          final t = _ctrl.value; // 0 = resting, 1 = pressed
          final scale = 1.0 - (0.04 * t);
          final tiltX = 0.025 * t;
          final tiltY = 0.015 * t;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateX(tiltX)
              ..rotateY(tiltY)
              // ignore: deprecated_member_use
              ..scale(scale, scale, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15 * (1 - t)),
                    blurRadius: 10 + (10 * (1 - t)),
                    offset: Offset(0, 5 + (5 * (1 - t))),
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
