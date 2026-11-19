import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Interactive Permission Chip with Spring Scale & Confirmation Pulse.
///
/// Triggers a micro-haptic elastic bounce and expanding emerald confirmation ring
/// when granted or revoked by an administrator.
class AnimatedPermissionChip extends StatefulWidget {
  final String label;
  final bool isGranted;
  final ValueChanged<bool> onChanged;

  const AnimatedPermissionChip({
    super.key,
    required this.label,
    required this.isGranted,
    required this.onChanged,
  });

  @override
  State<AnimatedPermissionChip> createState() => _AnimatedPermissionChipState();
}

class _AnimatedPermissionChipState extends State<AnimatedPermissionChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.88, end: 1.14)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.14, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 35,
      ),
    ]).animate(_controller);

    _ringAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedPermissionChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isGranted != oldWidget.isGranted) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0.0);
    widget.onChanged(!widget.isGranted);
  }

  @override
  Widget build(BuildContext context) {
    final granted = widget.isGranted;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final ringProgress = _ringAnimation.value;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Expanding confirmation ring
              if (_controller.isAnimating && ringProgress > 0 && ringProgress < 1.0)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (granted ? AppColors.brand : AppColors.danger)
                            .withValues(alpha: (0.45 * (1.0 - ringProgress)).clamp(0.0, 1.0)),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

              // Spring scaling chip body
              Transform.scale(
                scale: _controller.isAnimating ? _scaleAnimation.value : 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: granted ? AppColors.brandSoft : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: granted
                          ? AppColors.brand.withValues(alpha: 0.45)
                          : const Color(0xFFE2E8F0),
                      width: 1.1,
                    ),
                    boxShadow: [
                      if (granted)
                        BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        granted ? Icons.verified_user_rounded : Icons.shield_outlined,
                        size: 13,
                        color: granted ? AppColors.brand : AppColors.muted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: granted ? FontWeight.w700 : FontWeight.w500,
                          color: granted ? AppColors.brand : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
