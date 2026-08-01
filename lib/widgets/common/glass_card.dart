import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

/// A frosted-glass card used for the featured live hero on Home.
///
/// Uses a translucent surface + blur backdrop filter so content behind the
/// card bleeds through subtly — the glassmorphism treatment.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.xl),
    this.borderRadius = AppSizes.radiusCardLg,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0x66FFFFFF),
                      const Color(0x26FFFFFF),
                    ]
                  : [
                      const Color(0xCCFFFFFF),
                      const Color(0x99FFFFFF),
                    ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
