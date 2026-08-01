import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../models/connection_status.dart';
import '../../theme/app_colors.dart';
import '../animations/pulse_dot.dart';

/// The status pill shown on API integration cards.
///
/// States: Not tested (grey), Testing (spinner), Connected (pulsing green),
/// Live now (pulsing red), Failed (red), Paused (muted).
class ConnectionStatusPill extends StatelessWidget {
  const ConnectionStatusPill({
    super.key,
    required this.status,
    this.liveNow = false,
  });

  final ConnectionStatus status;
  final bool liveNow;

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = _visual();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm + 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == ConnectionStatus.testing)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else if (icon != null)
            Icon(icon, size: 12, color: color)
          else
            PulseDot(color: color, size: 8),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }

  (Color, String, IconData?) _visual() {
    if (liveNow) {
      return (AppColors.liveRed, 'Live now', null);
    }
    return switch (status) {
      ConnectionStatus.notTested => (AppColors.slate, 'Not tested', null),
      ConnectionStatus.testing => (AppColors.warning, 'Testing…', null),
      ConnectionStatus.connected => (AppColors.success, 'Connected', null),
      ConnectionStatus.disabled => (AppColors.slate, 'Paused', Icons.pause_rounded),
      ConnectionStatus.failed => (AppColors.error, 'Failed', null),
    };
  }
}
