import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Premium3DCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Color? accentColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool enableTilt;

  const Premium3DCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.accentColor,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.enableTilt = true,
  });

  @override
  State<Premium3DCard> createState() => _Premium3DCardState();
}

class _Premium3DCardState extends State<Premium3DCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.975).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.brand;
    final surfaceColor = widget.color ?? Colors.white;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _isPressed
                  ? accent.withValues(alpha: 0.4)
                  : accent.withValues(alpha: 0.12),
              width: 1.2,
            ),
            boxShadow: [
              // Primary 3D depth drop shadow
              BoxShadow(
                color: _isPressed
                    ? accent.withValues(alpha: 0.06)
                    : accent.withValues(alpha: 0.12),
                blurRadius: _isPressed ? 6 : 14,
                offset: Offset(0, _isPressed ? 2 : 6),
              ),
              // Soft ambient floor shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
