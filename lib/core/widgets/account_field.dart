import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// A single labeled input used throughout account-style screens (My
/// Account, Add/Edit Customer, Add Staff). Height, radius, and spacing
/// all come from the app's global InputDecorationTheme (see
/// app_theme.dart) so this stays visually identical to every other text
/// field in the app — this widget's job is label placement, the
/// read-only visual treatment, and optional validation/helper content.
///
/// [validator]/[inputFormatters] are optional — when [validator] is
/// omitted this behaves exactly as it always has (a plain TextField);
/// passing one switches it to a TextFormField so it participates in a
/// parent Form's validation. This is deliberately one component for
/// both cases rather than a second near-duplicate widget.
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
      suffixIcon: suffixIcon,
      fillColor: readOnly ? AppColors.bg : Colors.white,
    );
    final style = TextStyle(fontSize: 14, color: readOnly ? AppColors.muted : AppColors.ink);

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
        if (validator != null)
          TextFormField(
            controller: controller,
            enabled: !readOnly,
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
            enabled: !readOnly,
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: style,
            decoration: decoration,
          ),
        if (helperText != null) ...[
          const SizedBox(height: 5),
          Text(helperText!, style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3)),
        ],
      ],
    );
  }
}
