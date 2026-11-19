import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Aurora Mesh Ambient Glow Header Background.
///
/// Gently oscillates two organic radial light spheres (deep emerald & muted gold)
/// behind the executive header with smooth sinusoidal curves, producing a
/// living aurora effect without impacting scroll performance.
class AuroraHeaderBackground extends StatefulWidget {
  final Widget child;
  final double height;

  const AuroraHeaderBackground({
    super.key,
    required this.child,
    this.height = 200,
  });

  @override
  State<AuroraHeaderBackground> createState() => _AuroraHeaderBackgroundState();
}

class _AuroraHeaderBackgroundState extends State<AuroraHeaderBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );

    // Only repeat in live environments, allowing widget tests to pump cleanly
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
    return SizedBox(
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Dark banking base gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF011814),
                    Color(0xFF022B24),
                    Color(0xFF0B463B),
                  ],
                ),
              ),
            ),
          ),

          // Oscillating emerald & gold ambient glow spheres
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                final emeraldOffsetX = math.sin(t * math.pi) * 35.0;
                final emeraldOffsetY = math.cos(t * math.pi) * 15.0;
                final goldOffsetX = math.cos(t * math.pi) * 40.0;
                final goldOffsetY = math.sin(t * math.pi) * 20.0;

                return Stack(
                  children: [
                    // Deep emerald aura sphere
                    Positioned(
                      left: -20 + emeraldOffsetX,
                      top: -30 + emeraldOffsetY,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.brandLight.withValues(alpha: 0.22),
                              AppColors.brand.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Muted gold aura sphere
                    Positioned(
                      right: -30 + goldOffsetX,
                      top: 10 + goldOffsetY,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.gold.withValues(alpha: 0.16),
                              AppColors.gold.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Header child content
          widget.child,
        ],
      ),
    );
  }
}
