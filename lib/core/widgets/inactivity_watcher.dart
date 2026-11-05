import 'dart:async';
import 'package:flutter/material.dart';

/// Monitors user interactions and triggers a timeout callback
/// after [timeoutDuration] of continuous inactivity.
class InactivityWatcher extends StatefulWidget {
  final Widget child;
  final Duration timeoutDuration;
  final VoidCallback onTimeout;
  final bool enabled;

  const InactivityWatcher({
    super.key,
    required this.child,
    this.timeoutDuration = const Duration(minutes: 5),
    required this.onTimeout,
    this.enabled = true,
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetTimer();
  }

  @override
  void didUpdateWidget(covariant InactivityWatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled || widget.timeoutDuration != oldWidget.timeoutDuration) {
      _resetTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetTimer();
    } else if (state == AppLifecycleState.paused) {
      // If the app is sent to the background, don't keep firing unneeded timers
      _timer?.cancel();
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    if (!widget.enabled) return;
    _timer = Timer(widget.timeoutDuration, () {
      if (mounted) widget.onTimeout();
    });
  }

  void _onInteraction() {
    _resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onInteraction(),
      onPointerMove: (_) => _onInteraction(),
      onPointerUp: (_) => _onInteraction(),
      child: widget.child,
    );
  }
}
