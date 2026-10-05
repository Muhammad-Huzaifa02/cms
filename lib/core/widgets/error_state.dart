import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shown when a stream/future genuinely fails (permission-denied, no
/// connectivity, etc.) — distinct from an empty-but-successful result, so
/// a real error can never be silently mistaken for "there's just no data
/// yet". Always offers Retry; never just blanks the screen.
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorStateWidget({super.key, this.message = "We couldn't load this information.", required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.danger.withValues(alpha: 0.6)),
            const SizedBox(height: 14),
            const Text('Something went wrong', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

/// Sliver wrapper so this can drop straight into a CustomScrollView
/// (the Dashboard is built on one) without each call site re-wrapping it.
class SliverErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const SliverErrorState({super.key, this.message = "We couldn't load this information.", required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: ErrorStateWidget(message: message, onRetry: onRetry),
    );
  }
}
