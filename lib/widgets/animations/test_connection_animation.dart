import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated result states for the "Test Connection" flow.
///
/// Success scales in a checkmark; error shakes a close glyph — both driven by
/// a single `AnimationController` with an ease-out-back curve for the success
/// spring and a decaying sine for the failure shake.
class TestResultAnimation extends StatefulWidget {
  const TestResultAnimation({super.key, required this.success, this.size = 56});

  final bool success;
  final double size;

  @override
  State<TestResultAnimation> createState() => _TestResultAnimationState();
}

class _TestResultAnimationState extends State<TestResultAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = widget.success ? scheme.primary : scheme.error;
    final icon = widget.success ? Icons.check_rounded : Icons.close_rounded;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final eased = Curves.easeOutBack.transform(t);
        final scale = widget.success ? 0.5 + eased * 0.5 : 1.0;
        final shake = widget.success ? 0.0 : _shake(t);

        return Transform.translate(
          offset: Offset(shake, 0),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.14),
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, color: color, size: widget.size * 0.55),
            ),
          ),
        );
      },
    );
  }

  /// Decaying horizontal oscillation — two strong swings that fade to rest.
  static double _shake(double t) {
    if (t < 0.15) return 0;
    final local = (t - 0.15) / 0.85;
    final decay = math.pow(1 - local, 1.6).toDouble();
    return 16 * decay * math.sin(local * 18 * math.pi);
  }
}
