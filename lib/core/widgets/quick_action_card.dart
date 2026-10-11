import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// One tile in the Dashboard's Quick Actions row — icon, short label, a
/// floating card treatment, and a press-depth animation. Only ever points
/// at screens that genuinely exist in the app (see dashboard_screen.dart's
/// usage) — no placeholder "Reports"/"Settings" destinations invented
/// just to fill out a grid.
class QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: _pressed ? 0.03 : 0.07),
                blurRadius: _pressed ? 6 : 12,
                offset: Offset(0, _pressed ? 2 : 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: widget.accent.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(widget.icon, size: 19, color: widget.accent),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
