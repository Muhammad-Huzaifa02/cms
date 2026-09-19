import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A single labeled input used throughout account-style screens. Height,
/// radius, and spacing all come from the app's global InputDecorationTheme
/// (see app_theme.dart) so this stays visually identical to every other
/// text field in the app — this widget's job is just the label placement,
/// the read-only visual treatment, and optional helper/trailing content.
class AccountField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final String? helperText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final bool obscureText;

  const AccountField({
    super.key,
    required this.label,
    required this.controller,
    this.readOnly = false,
    this.helperText,
    this.keyboardType,
    this.suffixIcon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
            if (readOnly) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text('LOCKED', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.4)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: !readOnly,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 14, color: readOnly ? AppColors.muted : AppColors.ink),
          decoration: InputDecoration(
            isDense: false,
            suffixIcon: suffixIcon,
            fillColor: readOnly ? AppColors.bg : Colors.white,
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 5),
          Text(helperText!, style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3)),
        ],
      ],
    );
  }
}
