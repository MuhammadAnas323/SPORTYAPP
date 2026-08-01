import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/match_summary.dart';
import '../../../models/sport_type.dart';
import '../../../services/feed_store.dart';
import '../../../widgets/animations/shimmer.dart';
import '../../../widgets/common/app_chips.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/error_state.dart';
import '../../../widgets/common/sport_filter_bar.dart';
import '../viewmodels/home_view_model.dart';
import 'widgets/featured_live_card.dart';
import 'widgets/source_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openSearch(BuildContext context, WidgetRef ref) {
    final feed = ref.read(homeViewModelProvider).feed;
    if (feed.allItems.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SearchSheet(items: feed.allItems),
    );
  }

  void _openNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.notificationsNote)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(feedStoreProvider);
    final home = ref.watch(homeViewModelProvider);

    final Widget body;
    if (store.isLoading && !store.hasValue) {
      body = const _HomeSkeleton();
    } else if (store.hasError && !store.hasValue) {
      body = ErrorState(
        message: store.error.toString(),
        onRetry: () => ref.read(feedStoreProvider.notifier).refresh(),
      );
    } else {
      body = _buildFeed(context, ref, home);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.sports_soccer_rounded,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppSizes.sm),
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _openSearch(context, ref),
            icon: const Icon(Icons.search_rounded),
            tooltip: AppStrings.searchHint,
          ),
          IconButton(
            onPressed: () => _openNotifications(context),
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildFeed(BuildContext context, WidgetRef ref, HomeState state) {
    // The filter bar is always visible so the user can filter even when the
    // feed is empty. Below it: a full-screen empty state when nothing matches,
    // otherwise the refreshable feed. A channel that exists but failed to load
    // or returned nothing renders its own diagnostic chip (error / "no
    // matches") instead of being hidden.
    final showEmpty =
        state.feed.channels.isEmpty || state.visibleChannels.isEmpty;

    return Column(
      children: [
        const SizedBox(height: AppSizes.lg),
        SportFilterBar(
          filter: state.filter,
          onChanged: (f) =>
              ref.read(homeViewModelProvider.notifier).setFilter(f),
        ),
        const SizedBox(height: AppSizes.lg),
        Expanded(
          child: showEmpty
              ? EmptyState(
                  icon: Icons.sports_soccer_rounded,
                  title: AppStrings.noMatchesTitle,
                  body: AppStrings.noMatchesBody,
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(feedStoreProvider.notifier).refresh(),
                  color: Theme.of(context).colorScheme.primary,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (state.isRefreshing)
                        const SliverToBoxAdapter(
                          child: LinearProgressIndicator(minHeight: 2),
                        ),

                      // Featured live hero (glassmorphism).
                      if (state.feed.liveOnly.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSizes.xl),
                            child: FeaturedLiveCard(
                              match: state.feed.liveOnly.first,
                              onTap: () =>
                                  _openMatch(context, state.feed.liveOnly.first),
                            ),
                          ),
                        )
                      else
                        const SliverToBoxAdapter(
                          child: SizedBox(height: AppSizes.xs),
                        ),

                      // Per-source sections.
                      SliverList.builder(
                        itemCount: state.visibleChannels.length,
                        itemBuilder: (context, index) {
                          final channel = state.visibleChannels[index];
                          return SourceSection(
                            channel: channel,
                            onMatchTap: (m) => _openMatch(context, m),
                            onRetry: () =>
                                ref.read(feedStoreProvider.notifier).refresh(),
                          );
                        },
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSizes.xxl),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  void _openMatch(BuildContext context, MatchSummary match) {
    context.push(
      '/match/${match.connectionId}/${Uri.encodeComponent(match.providerId)}',
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        MatchCardSkeleton(),
        SizedBox(height: AppSizes.lg),
        MatchCardSkeleton(),
        SizedBox(height: AppSizes.lg),
        MatchCardSkeleton(),
      ],
    );
  }
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({required this.items});

  final List<MatchSummary> items;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<MatchSummary> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items
        .where((m) =>
            m.title.toLowerCase().contains(q) ||
            m.home.name.toLowerCase().contains(q) ||
            m.away.name.toLowerCase().contains(q) ||
            (m.seriesName?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: AppStrings.searchHint,
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Expanded(
              child: results.isEmpty
                  ? const InlineEmpty(
                      message: 'No matches match your search.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.lg,
                        0,
                        AppSizes.lg,
                        AppSizes.lg,
                      ),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final match = results[index];
                        return ListTile(
                          leading: Icon(
                            match.sportType == SportType.football
                                ? Icons.sports_soccer_rounded
                                : Icons.sports_cricket_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(match.title, maxLines: 1),
                          subtitle: Text(
                            match.seriesName ?? match.connectionLabel,
                            maxLines: 1,
                          ),
                          trailing: SourceTag(label: match.connectionLabel),
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push(
                              '/match/${match.connectionId}/${Uri.encodeComponent(match.providerId)}',
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
