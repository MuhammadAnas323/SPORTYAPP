import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import 'pulse_dot.dart';

/// The pulsing "LIVE" badge shown on live cards and the featured hero.
class PulsingLiveBadge extends StatelessWidget {
  const PulsingLiveBadge({
    super.key,
    this.darkText = false,
    this.compact = false,
  });

  /// When true, renders on a light backdrop (e.g. a white scoreline card).
  final bool darkText;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSizes.sm : AppSizes.md,
        vertical: compact ? AppSizes.xs : AppSizes.sm - 2,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A65), Color(0xFFE53950)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53950).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PulseDot(color: Colors.white, size: 7, duration: Duration(milliseconds: 900)),
          SizedBox(width: compact ? AppSizes.xs : AppSizes.sm),
          Text(
            'LIVE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontSize: compact ? 9 : 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// Rotates the badge by a subtle amount over time — used to draw the eye on
/// the hero without shipping a gif.
class LiveBadgeTilt extends StatefulWidget {
  const LiveBadgeTilt({super.key, required this.child});

  final Widget child;

  @override
  State<LiveBadgeTilt> createState() => _LiveBadgeTiltState();
}

class _LiveBadgeTiltState extends State<LiveBadgeTilt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final angle = math.sin(_controller.value * math.pi) * 0.05;
        return Transform.rotate(angle: angle, child: widget.child);
      },
    );
  }
}
