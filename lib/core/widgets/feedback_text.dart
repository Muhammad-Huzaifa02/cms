import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Small inline feedback line under a form — success in brand green, error
/// in the app's danger red. Used after Save/Change actions across account
/// screens so the visual treatment stays identical everywhere.
class FeedbackText extends StatelessWidget {
  final String text;
  final bool isError;
  const FeedbackText(this.text, {super.key, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 14,
            color: isError ? AppColors.danger : AppColors.brand,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(text, style: TextStyle(color: isError ? AppColors.danger : AppColors.brand, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
