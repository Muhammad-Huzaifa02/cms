import 'package:flutter/material.dart';

/// Full-width, content-height action button with a built-in loading spinner
/// state — every "Save"/"Change"/submit button in the app should look and
/// behave identically, so this is the single place that defines that.
class PrimaryButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        width: double.infinity,
        child: Listener(
          onPointerDown: (_) {
            if (widget.onPressed != null && !widget.loading) {
              setState(() => _isPressed = true);
            }
          },
          onPointerUp: (_) => setState(() => _isPressed = false),
          onPointerCancel: (_) => setState(() => _isPressed = false),
          child: ElevatedButton(
            onPressed: widget.loading ? null : widget.onPressed,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: widget.loading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      height: 19,
                      width: 19,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : Padding(
                      key: ValueKey(widget.label),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(widget.label, textAlign: TextAlign.center),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
