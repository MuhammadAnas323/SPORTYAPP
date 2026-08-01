import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../models/sport_type.dart';
import 'app_chips.dart';
import 'sport_icon.dart';

/// Horizontal, scrollable sport filter bar shared by Home and Live.
class SportFilterBar extends StatelessWidget {
  const SportFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
    this.includeAll = true,
  });

  final SportType? filter;
  final ValueChanged<SportType?> onChanged;
  final bool includeAll;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
      child: Row(
        children: [
          if (includeAll) ...[
            SportFilterChip(
              label: AppStrings.filterAll,
              selected: filter == null,
              onSelected: () => onChanged(null),
            ),
            const SizedBox(width: AppSizes.sm),
          ],
          SportFilterChip(
            label: AppStrings.filterCricket,
            sportIcon: SportIconName.bat,
            selected: filter == SportType.cricket,
            onSelected: () => onChanged(SportType.cricket),
          ),
          const SizedBox(width: AppSizes.sm),
          SportFilterChip(
            label: AppStrings.filterFootball,
            sportIcon: SportIconName.football,
            selected: filter == SportType.football,
            onSelected: () => onChanged(SportType.football),
          ),
        ],
      ),
    );
  }
}
