import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// One headline number on the Dashboard: icon, label, a count-up value and
/// an optional caption line. Wrapped in a frosted glass card container.
class DashboardStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final String? caption;

  /// Colors the caption. Use green/red for genuine up/down changes, muted
  /// otherwise — and never rely on color alone: callers should also put an
  /// arrow or sign in the caption text.
  final Color? captionColor;
  final Color accent;

  const DashboardStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.caption,
    this.captionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value${caption != null ? ', $caption' : ''}',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: _glassCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.28),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(icon, size: 17, color: accent),
                ),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: value),
                  duration: const Duration(milliseconds: 950),
                  curve: Curves.fastOutSlowIn,
                  builder: (context, v, _) => Text(
                    NumberFormat.decimalPattern().format(v),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.1),
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: captionColor ?? AppColors.muted, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shimmer placeholder with the same footprint as [DashboardStatCard], shown
/// while stats load so the UI never flashes a misleading "0".
class DashboardStatSkeleton extends StatelessWidget {
  const DashboardStatSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 104,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

BoxDecoration _glassCardDecoration() => BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.90),
          Colors.white.withValues(alpha: 0.72),
        ],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: 0.95), width: 1.4),
      boxShadow: [
        BoxShadow(color: AppColors.brandDeep.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 5)),
        BoxShadow(color: AppColors.brand.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8)),
      ],
    );
