import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../models/channel.dart';
import '../../../../models/match_summary.dart';
import '../../../../widgets/animations/shimmer.dart';
import '../../../../widgets/common/empty_state.dart';
import '../../../../widgets/common/error_state.dart';
import '../../../../widgets/matches/match_card.dart';

/// One connected channel's slice of the Home feed: a responsive grid of
/// match cards, and honest per-source states (loading skeleton / inline
/// error / empty).
class SourceSection extends StatelessWidget {
  const SourceSection({
    super.key,
    required this.channel,
    required this.onMatchTap,
    this.onRetry,
  });

  final ChannelFeed channel;
  final void Function(MatchSummary match) onMatchTap;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Fluid reflow: 1 col (phone) → 2 (large phone) → 3–4 (tablet).
            final maxCardWidth = context.isTabletOrWider ? 340.0 : 400.0;
            final columns =
                (constraints.maxWidth / maxCardWidth).floor().clamp(1, 4);
            final cardWidth = (constraints.maxWidth -
                    (columns - 1) * AppSizes.lg) /
                columns;

            if (channel.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.pagePadding,
                ),
                child: InlineErrorChip(
                  message: channel.lastError!,
                  sourceLabel: channel.connection.label,
                  onRetry: onRetry,
                ),
              );
            }

            if (channel.isLoading) {
              return _SkeletonGrid(columns: columns, cardWidth: cardWidth);
            }

            if (channel.items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
                child: InlineEmpty(
                  message: 'This channel returned no matches right now.',
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.pagePadding,
              ),
              child: Wrap(
                spacing: AppSizes.lg,
                runSpacing: AppSizes.lg,
                children: [
                  for (final match in channel.items)
                    SizedBox(
                      width: cardWidth,
                      child: MatchCard(
                        match: match,
                        onTap: () => onMatchTap(match),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSizes.sectionGap),
      ],
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid({required this.columns, required this.cardWidth});

  final int columns;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
      child: Wrap(
        spacing: AppSizes.lg,
        runSpacing: AppSizes.lg,
        children: [
          for (var i = 0; i < columns.clamp(1, 3); i++)
            SizedBox(width: cardWidth, child: _CardSkeleton()),
        ],
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: SizedBox(
        height: 148,
        child: ColoredBox(color: Colors.white),
      ),
    );
  }
}
