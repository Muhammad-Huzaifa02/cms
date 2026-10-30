import 'package:flutter/material.dart';

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

class _TiltTapCardState extends State<TiltTapCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    lowerBound: 0.0,
    upperBound: 1.0,
  );

  void _down(TapDownDetails _) => _ctrl.forward();
  void _up(TapUpDetails _) => _ctrl.reverse();
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
          final t = _ctrl.value;
          final scale = 1.0 - (0.025 * t);
          final tiltY = 0.01 * t;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(tiltY)
              // ignore: deprecated_member_use
              ..scale(scale, scale, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
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
