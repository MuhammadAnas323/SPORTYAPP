import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/match_summary.dart';
import '../../../services/feed_store.dart';
import '../../../widgets/animations/pulsing_live_badge.dart';
import '../../../widgets/animations/shimmer.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/error_state.dart';
import '../../../widgets/common/sport_filter_bar.dart';
import '../../../widgets/matches/match_card.dart';
import '../viewmodels/live_view_model.dart';

class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(feedStoreProvider);
    final live = ref.watch(liveViewModelProvider);

    final Widget body;
    if (store.isLoading && !store.hasValue) {
      body = const _LiveSkeleton();
    } else if (store.hasError && !store.hasValue) {
      body = ErrorState(
        message: store.error.toString(),
        onRetry: () => ref.read(feedStoreProvider.notifier).refresh(),
      );
    } else {
      body = _buildLive(context, ref, live);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const PulsingLiveBadge(compact: true),
            const SizedBox(width: AppSizes.sm),
            Text(AppStrings.liveTitle,
                style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
      body: body,
    );
  }

  Widget _buildLive(BuildContext context, WidgetRef ref, LiveState state) {
    if (state.visibleMatches.isEmpty) {
      return EmptyState(
        icon: Icons.sensors_off_rounded,
        title: AppStrings.nothingLiveTitle,
        body: AppStrings.nothingLiveBody,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(feedStoreProvider.notifier).refresh(),
      color: Theme.of(context).colorScheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: AppSizes.lg)),
          SliverToBoxAdapter(
            child: SportFilterBar(
              filter: state.filter,
              onChanged: (f) =>
                  ref.read(liveViewModelProvider.notifier).setFilter(f),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSizes.lg)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.pagePadding,
              ),
              child: Text(
                '${state.visibleMatches.length} '
                '${state.visibleMatches.length == 1 ? 'match is' : 'matches are'} live across your channels',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSizes.md)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pagePadding,
            ),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final maxCardWidth =
                    context.isTabletOrWider ? 340.0 : 400.0;
                final columns = (constraints.crossAxisExtent / maxCardWidth)
                    .floor()
                    .clamp(1, 4);
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: AppSizes.lg,
                    mainAxisSpacing: AppSizes.lg,
                    childAspectRatio: 1.55,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _LiveCard(
                      match: state.visibleMatches[index],
                      onTap: () => _openMatch(
                        context,
                        state.visibleMatches[index],
                      ),
                    ),
                    childCount: state.visibleMatches.length,
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSizes.xxl)),
        ],
      ),
    );
  }

  void _openMatch(BuildContext context, MatchSummary match) {
    context.push(
      '/match/${match.connectionId}/${Uri.encodeComponent(match.providerId)}',
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.match, this.onTap});

  final MatchSummary match;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MatchCard(match: match, onTap: onTap);
  }
}

class _LiveSkeleton extends StatelessWidget {
  const _LiveSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        MatchCardSkeleton(),
        SizedBox(height: AppSizes.lg),
        MatchCardSkeleton(),
      ],
    );
  }
}
