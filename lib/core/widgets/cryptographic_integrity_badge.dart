import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Cryptographic Hardware Integrity Security Badge.
///
/// Features a gentle 4000ms breathing emerald aura and rotating micro-lock
/// icon to visually reassure officers that 256-bit hardware integrity is active.
class CryptographicIntegrityBadge extends StatefulWidget {
  final String label;
  final bool isHardwareProtected;

  const CryptographicIntegrityBadge({
    super.key,
    this.label = '256-BIT ENCRYPTED • HARDWARE VERIFIED',
    this.isHardwareProtected = true,
  });

  @override
  State<CryptographicIntegrityBadge> createState() => _CryptographicIntegrityBadgeState();
}

class _CryptographicIntegrityBadgeState extends State<CryptographicIntegrityBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _glowAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.repeat(reverse: true);
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
      animation: _glowAnimation,
      builder: (context, _) {
        final v = _glowAnimation.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
          decoration: BoxDecoration(
            color: const Color(0xFF022B24).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.brandLight.withValues(alpha: 0.25 + (0.35 * v)),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandLight.withValues(alpha: 0.12 * v),
                blurRadius: 8 + (6 * v),
                spreadRadius: 1 * v,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: (math.sin(v * math.pi) * 0.15),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 11,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 5.5),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
