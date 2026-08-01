import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../theme/app_colors.dart';
import 'sport_icon.dart';

/// A selectable sport filter chip (All • Cricket • Football…).
class SportFilterChip extends StatelessWidget {
  const SportFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.sportIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final SportIconName? sportIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? scheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg,
              vertical: AppSizes.sm + 1,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sportIcon != null) ...[
                  SportIcon(
                    sportIcon!,
                    size: 14,
                    color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSizes.xs + 2),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small static tag showing which connected channel an item came from.
class SourceTag extends StatelessWidget {
  const SourceTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 10, color: AppColors.info),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 9.5,
                  letterSpacing: 0.3,
                ),
          ),
        ],
      ),
    );
  }
}

/// A compact phase/result pill, e.g. "Innings Break", "65'", "India won".
class PhasePill extends StatelessWidget {
  const PhasePill({super.key, required this.text, this.live = false});

  final String text;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: live
            ? AppColors.liveRed.withValues(alpha: 0.16)
            : scheme.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: live ? AppColors.liveRed : scheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
  }
}
