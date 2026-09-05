import 'package:flutter/material.dart';

/// A page route that flies the incoming screen in with real 3D perspective
/// (rotateY + slight scale), echoing the tilted-phone look from the UI
/// concept mockups. Drop-in replacement for MaterialPageRoute:
///
///   Navigator.of(context).push(Perspective3DRoute(page: NextScreen()));
class Perspective3DRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  Perspective3DRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
            return AnimatedBuilder(
              animation: curved,
              child: child,
              builder: (context, child) {
                final angleY = (1 - curved.value) * -0.45; // rotate around Y
                final angleX = (1 - curved.value) * 0.15;  // slight rotate around X
                final scale = 0.85 + (0.15 * curved.value);
                return Opacity(
                  opacity: curved.value.clamp(0.0, 1.0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0018) // more depth
                      ..rotateX(angleX)
                      ..rotateY(angleY)
                      // ignore: deprecated_member_use
                      ..scale(scale, scale, 1.0),
                    child: child,
                  ),
                );
              },
            );
          },
        );
}

/// Shorthand used throughout the screens.
Future<T?> push3D<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(Perspective3DRoute<T>(page: page));
}
