import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Modern Frosted Glass (Glassmorphism) Container.
///
/// Features:
/// - [BackdropFilter] with customizable Gaussian blur ([sigmaX], [sigmaY]).
/// - Translucent frosted acrylic gradient fill.
/// - Crisp, subtle specular border highlighting light reflection.
/// - Soft multi-layer depth drop-shadows.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final Color? surfaceColor;
  final Gradient? surfaceGradient;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 16.0,
    this.surfaceColor,
    this.surfaceGradient,
    this.border,
    this.boxShadow,
    this.onTap,
  });

  /// Frosted glass card preset with standard banking depth.
  factory GlassContainer.card({
    Key? key,
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    double blur = 20.0,
    Color? surfaceColor,
    Gradient? surfaceGradient,
    Border? border,
    List<BoxShadow>? boxShadow,
    VoidCallback? onTap,
  }) {
    return GlassContainer(
      key: key,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      blur: blur,
      surfaceColor: surfaceColor,
      surfaceGradient: surfaceGradient ??
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.88),
              Colors.white.withValues(alpha: 0.70),
            ],
          ),
      border: border ??
          Border.all(
            color: Colors.white.withValues(alpha: 0.95),
            width: 1.5,
          ),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: AppColors.brandDeep.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.05),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
      onTap: onTap,
      child: child,
    );
  }

  /// Dark frosted glass preset for glowing/floating badges and dark hero headers.
  factory GlassContainer.dark({
    Key? key,
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    double blur = 20.0,
    VoidCallback? onTap,
  }) {
    return GlassContainer(
      key: key,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      blur: blur,
      surfaceGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0.08),
        ],
      ),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.45),
        width: 1.3,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.brandDeep.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: AppColors.gold.withValues(alpha: 0.20),
          blurRadius: 28,
          spreadRadius: 2,
        ),
      ],
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(16);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceGradient == null
            ? (surfaceColor ?? Colors.white.withValues(alpha: 0.75))
            : null,
        gradient: surfaceGradient,
        borderRadius: effectiveRadius,
        border: border ??
            Border.all(
              color: Colors.white.withValues(alpha: 0.85),
              width: 1.2,
            ),
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: effectiveRadius,
          onTap: onTap,
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: AppColors.brandDeep.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      ),
    );
  }
}

/// Ambient Glass Background wrapper.
/// Paints a sophisticated, subtle mesh gradient with soft color orbs
/// beneath a blur filter to give all frosted cards on the screen realistic,
/// glowing refraction and depth.
class GlassScaffoldBackground extends StatelessWidget {
  final Widget child;

  const GlassScaffoldBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 1: Ambient mesh orbs
        Positioned.fill(
          child: Container(
            color: const Color(0xFFEDF4F2),
            child: Stack(
              children: [
                // Top-right soft emerald orb
                Positioned(
                  top: -60,
                  right: -60,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.brandLight.withValues(alpha: 0.24),
                          AppColors.brandLight.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Center-left warm gold orb
                Positioned(
                  top: 260,
                  left: -80,
                  child: Container(
                    width: 340,
                    height: 340,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.gold.withValues(alpha: 0.20),
                          AppColors.gold.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom-right soft teal orb
                Positioned(
                  bottom: 60,
                  right: -70,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF0F766E).withValues(alpha: 0.18),
                          const Color(0xFF0F766E).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Layer 2: Main Content
        child,
      ],
    );
  }
}
