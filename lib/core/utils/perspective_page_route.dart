import 'package:flutter/material.dart';

/// Shared-Axis Banking Page Route with 3D Depth Elevation.
///
/// Gives CMS a unified tier-1 banking portal transition:
/// - Incoming page smoothly elevates along the Z-axis (scale from 0.94 -> 1.0,
///   slide up slightly from offset (0, 0.04) -> (0, 0), opacity 0.0 -> 1.0)
///   using [Curves.fastLinearToSlowEaseIn].
/// - Outgoing page (via [secondaryAnimation]) smoothly recesses to 0.96 scale
///   with frosted glass dimming (opacity 1.0 -> 0.88), springing back when
///   the top page is popped.
class Perspective3DRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  Perspective3DRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Incoming page elevation
            final primaryCurved = CurvedAnimation(
              parent: animation,
              curve: Curves.fastLinearToSlowEaseIn,
              reverseCurve: Curves.easeInCubic,
            );

            // Outgoing (background) page recession
            final secondaryCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return AnimatedBuilder(
              animation: Listenable.merge([primaryCurved, secondaryCurved]),
              child: RepaintBoundary(child: child),
              builder: (context, child) {
                // Incoming transformations
                final inScale = 0.94 + (0.06 * primaryCurved.value);
                final inSlideY = (1.0 - primaryCurved.value) * 0.04;
                final inOpacity = primaryCurved.value.clamp(0.0, 1.0);

                // Background transformations (when another route is pushed on top)
                final bgScale = 1.0 - (0.04 * secondaryCurved.value);
                final bgOpacity = 1.0 - (0.12 * secondaryCurved.value);

                final combinedScale = inScale * bgScale;
                final combinedOpacity = (inOpacity * bgOpacity).clamp(0.0, 1.0);

                return Opacity(
                  opacity: combinedOpacity,
                  child: Transform.translate(
                    offset: Offset(0, inSlideY * MediaQuery.of(context).size.height),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0008)
                        // ignore: deprecated_member_use
                        ..scale(combinedScale, combinedScale, 1.0),
                      child: child,
                    ),
                  ),
                );
              },
            );
          },
        );
}

Future<T?> push3D<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(Perspective3DRoute<T>(page: page));
}

