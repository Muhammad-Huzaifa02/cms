import 'package:flutter/material.dart';

class Perspective3DRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  Perspective3DRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            return AnimatedBuilder(
              animation: curved,
              child: RepaintBoundary(child: child),
              builder: (context, child) {
                final angleY = (1 - curved.value) * -0.2;
                final scale = 0.97 + (0.03 * curved.value);

                return Opacity(
                  opacity: curved.value.clamp(0.0, 1.0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
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

Future<T?> push3D<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(Perspective3DRoute<T>(page: page));
}
