import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Interactive Slide-to-Authorize Vault Release Slider.
///
/// Used for destructive banking actions (such as permanent customer deletion
/// or security privilege revocation) to replace standard dialog confirmations
/// with a secure, tactile slide gesture.
class SlideToAuthorizeSlider extends StatefulWidget {
  final String label;
  final String confirmedLabel;
  final Future<void> Function() onConfirmed;
  final Color baseColor;
  final Color activeColor;

  const SlideToAuthorizeSlider({
    super.key,
    this.label = 'Slide to confirm deletion',
    this.confirmedLabel = 'Authorizing...',
    required this.onConfirmed,
    this.baseColor = const Color(0xFFE5E7EB),
    this.activeColor = AppColors.danger,
  });

  @override
  State<SlideToAuthorizeSlider> createState() => _SlideToAuthorizeSliderState();
}

class _SlideToAuthorizeSliderState extends State<SlideToAuthorizeSlider>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isConfirmed = false;
  bool _isLoading = false;

  late final AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isConfirmed || _isLoading) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, double maxDrag) {
    if (_isConfirmed || _isLoading) return;

    if (_dragPosition >= maxDrag * 0.85) {
      // Completed drag
      setState(() {
        _dragPosition = maxDrag;
        _isConfirmed = true;
        _isLoading = true;
      });
      _executeAction();
    } else {
      // Snap back animation
      _resetAnimation = Tween<double>(begin: _dragPosition, end: 0.0).animate(
        CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
      )..addListener(() {
          setState(() {
            _dragPosition = _resetAnimation.value;
          });
        });
      _resetController.forward(from: 0.0);
    }
  }

  Future<void> _executeAction() async {
    try {
      await widget.onConfirmed();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isConfirmed = false;
          _isLoading = false;
          _dragPosition = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const trackHeight = 54.0;
    const thumbSize = 46.0;
    const padding = 4.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final maxDrag = (totalWidth - thumbSize - (padding * 2)).clamp(0.0, totalWidth);
        final progress = maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        return Container(
          height: trackHeight,
          decoration: BoxDecoration(
            color: widget.baseColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.activeColor.withValues(alpha: 0.2 + (0.4 * progress)),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.activeColor.withValues(alpha: 0.15 * progress),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Expanding active progress fill
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: padding + thumbSize + _dragPosition,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.activeColor.withValues(alpha: 0.15),
                        widget.activeColor.withValues(alpha: 0.35),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),

              // Centered background label
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(widget.activeColor),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                widget.confirmedLabel,
                                key: const ValueKey('loading'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: widget.activeColor,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            widget.label,
                            key: const ValueKey('label'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink.withValues(alpha: (0.85 - (progress * 0.4)).clamp(0.0, 1.0)),
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ),

              // Draggable thumb knob
              Positioned(
                left: padding + _dragPosition,
                top: padding,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(details, maxDrag),
                  onHorizontalDragEnd: (details) => _onHorizontalDragEnd(details, maxDrag),
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.activeColor,
                          Color.lerp(widget.activeColor, Colors.black, 0.25)!,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.activeColor.withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isConfirmed
                            ? Icons.check_rounded
                            : Icons.keyboard_double_arrow_right_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
