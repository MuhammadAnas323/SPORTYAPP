import 'dart:async';

import 'package:flutter/material.dart';

/// Wraps [child] with a hidden gesture detector: [onSecret] fires only after
/// [taps] consecutive taps, each within [window] of the previous one.
///
/// Deliberately shows no visual affordance — the wrapped widget looks and
/// behaves exactly as before. The counter resets to zero as soon as the user
/// stops tapping for longer than [window], or after [onSecret] fires.
class SecretTap extends StatefulWidget {
  const SecretTap({
    super.key,
    required this.child,
    required this.onSecret,
    this.taps = 7,
    this.window = const Duration(seconds: 3),
  });

  final Widget child;
  final VoidCallback onSecret;
  final int taps;
  final Duration window;

  @override
  State<SecretTap> createState() => _SecretTapState();
}

class _SecretTapState extends State<SecretTap> {
  int _count = 0;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    _resetTimer?.cancel();
    _count += 1;
    if (_count >= widget.taps) {
      _count = 0;
      widget.onSecret();
      return;
    }
    // Give up the streak if the next tap does not arrive in time.
    _resetTimer = Timer(widget.window, () => _count = 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: widget.child,
    );
  }
}
