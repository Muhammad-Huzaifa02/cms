import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnimatedCounter extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final Duration duration;
  final Curve curve;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.prefix,
    this.suffix,
    this.duration = const Duration(milliseconds: 1000),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0');
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, val, child) {
        final formatted = formatter.format(val.round());
        return Text(
          '${prefix ?? ''}$formatted${suffix ?? ''}',
          style: style,
        );
      },
    );
  }
}
