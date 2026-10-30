import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Central design tokens. New UI should pull spacing / radius / motion /
/// depth from here instead of inventing per-screen numbers — that's what
/// keeps every screen feeling like the same app.

class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  /// Horizontal screen gutter.
  static const double gutter = 20;
}

class Radii {
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 28;
}

/// Motion rules: fast for press/feedback, normal for most transitions,
/// emphasis for entrances. None of these overshoot — safe to feed into
/// Opacity. (The bouncy `easeOutBack` already used by the page transition
/// is the exception, and is always clamped where it touches opacity.)
class Motion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration emphasis = Duration(milliseconds: 420);
  static const Curve curve = Curves.easeOutCubic;
}

/// Depth hierarchy — what "floating" means in concrete shadow terms.
///   Level 0: background (no shadow)
///   Level 1: cards
///   Level 2: interactive/raised controls
///   Level 3: the floating nav dock
///   Level 4: primary floating action
class Depth {
  static List<BoxShadow> get card => [
        BoxShadow(color: AppColors.ink.withValues(alpha: 0.055), blurRadius: 9, offset: const Offset(0, 3)),
        BoxShadow(color: AppColors.ink.withValues(alpha: 0.035), blurRadius: 1, offset: const Offset(0, 1)),
      ];

  static List<BoxShadow> get raised => [
        BoxShadow(color: AppColors.ink.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 5)),
      ];

  static List<BoxShadow> get dock => [
        BoxShadow(color: AppColors.ink.withValues(alpha: 0.14), blurRadius: 20, offset: const Offset(0, 7)),
        BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1)),
      ];

  static List<BoxShadow> get primaryAction => [
        BoxShadow(color: AppColors.gold.withValues(alpha: 0.38), blurRadius: 16, offset: const Offset(0, 6)),
      ];
}
