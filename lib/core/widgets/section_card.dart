import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A titled card with consistent padding/spacing — used to group related
/// fields or controls (Details, Change Password, App Lock, etc.) so every
/// section on a screen looks like it belongs to the same design system
/// instead of being hand-spaced per screen.
class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsets padding;

  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Small-caps section label, e.g. "DETAILS" — consistent across every
/// card on the account screen and reusable anywhere else a section needs
/// a label without a full [SectionCard].
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.1,
        color: AppColors.muted,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
