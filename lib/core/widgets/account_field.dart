import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// A single labeled input used throughout account-style screens (My
/// Account, Add/Edit Customer, Add Staff). Height, radius, and spacing
/// all come from the app's global InputDecorationTheme (see
/// app_theme.dart) so this stays visually identical to every other text
/// field in the app.
///
/// Customer data readability is prioritized: read-only text is rendered
/// in deep high-contrast ink ([AppColors.ink]) rather than faint gray,
/// ensuring banking data remains crystal clear across all devices.
class AccountField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final String? helperText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autovalidateMode;
  final String? hintText;

  const AccountField({
    super.key,
    required this.label,
    required this.controller,
    this.readOnly = false,
    this.helperText,
    this.keyboardType,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
    this.inputFormatters,
    this.autovalidateMode,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = InputDecoration(
      isDense: false,
      hintText: hintText,
      suffixIcon: suffixIcon ??
          (readOnly ? const Icon(Icons.lock_outline, size: 16, color: AppColors.muted) : null),
      fillColor: readOnly ? const Color(0xFFF7FAF9) : Colors.white,
    );
    // Deep high-contrast font so read-only customer data is always easily readable.
    final style = TextStyle(
      fontSize: 15,
      fontWeight: readOnly ? FontWeight.w600 : FontWeight.w500,
      color: AppColors.ink,
      letterSpacing: 0.2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            if (readOnly) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  'LOCKED',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        if (validator != null)
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: readOnly ? null : validator,
            autovalidateMode: autovalidateMode,
            style: style,
            decoration: decoration,
          )
        else
          TextField(
            controller: controller,
            readOnly: readOnly,
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: style,
            decoration: decoration,
          ),
        if (helperText != null) ...[
          const SizedBox(height: 5),
          Text(helperText!, style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4)),
        ],
      ],
    );
  }
}
