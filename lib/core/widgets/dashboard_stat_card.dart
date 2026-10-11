import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// One headline number on the Dashboard: icon, label, a count-up value and
/// an optional caption line. The count-up runs once when the card first
/// appears (and glides from the old value to a new one if it changes) — a
/// single short tween, not a continuous animation.
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: accent),
            ),
            const SizedBox(height: 14),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text(
                NumberFormat.decimalPattern().format(v),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.1),
              ),
            ),
            const SizedBox(height: 6),
            // Always render this line (even blank) so every card in a row
            // has the same height whether or not it has a caption.
            Text(
              caption ?? ' ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: captionColor ?? AppColors.muted, fontWeight: FontWeight.w600),
            ),
          ],
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
        height: 132,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
      boxShadow: [
        BoxShadow(color: AppColors.ink.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 6)),
      ],
    );
