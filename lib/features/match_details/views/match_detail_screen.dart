import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/animations/shimmer.dart';
import '../../../widgets/common/error_state.dart';
import '../../../widgets/video/match_video_player.dart';
import '../viewmodels/match_detail_view_model.dart';
import 'widgets/commentary_tab.dart';
import 'widgets/info_tab.dart';
import 'widgets/scorecard_tab.dart';

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({
    super.key,
    required this.connectionId,
    required this.providerId,
  });

  final String connectionId;
  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args =
        MatchDetailArgs(connectionId: connectionId, providerId: providerId);
    final detail = ref.watch(matchDetailViewModelProvider(args));

    return Scaffold(
      appBar: AppBar(
        title: detail.valueOrNull == null
            ? const Text(AppStrings.matchLoading)
            : Text(detail.valueOrNull!.summary.title,
                maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: detail.when(
        loading: () => const _DetailSkeleton(),
        error: (error, _) => ErrorState(
          message: error.toString(),
          title: AppStrings.matchDetailError,
          onRetry: () =>
              ref.read(matchDetailViewModelProvider(args).notifier).retry(args),
        ),
        data: (match) {
          // Adaptive tabs — a tab hides itself when the source returns nothing.
          final tabs = <_TabDef>[
            _TabDef(AppStrings.tabInfo, Icons.info_outline_rounded, (_) => InfoTab(detail: match)),
            if (match.hasScorecard)
              _TabDef(
                AppStrings.tabScorecard,
                Icons.table_chart_outlined,
                (_) => ScorecardTab(detail: match),
              ),
            if (match.hasCommentary)
              _TabDef(
                AppStrings.tabCommentary,
                Icons.format_quote_rounded,
                (_) => CommentaryTab(items: match.commentary),
              ),
          ];

          return DefaultTabController(
            length: tabs.length,
            child: Column(
              children: [
                // Live video stream, when the provider offers one. Falls back
                // to the data card (score strip + tabs) automatically.
                if (match.summary.hasVideo) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.pagePadding,
                      AppSizes.md,
                      AppSizes.pagePadding,
                      0,
                    ),
                    child: MatchVideoPlayer(
                      videoUrl: match.summary.videoUrl,
                      borderRadius: AppSizes.radiusCard,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                ],
                // Compact score strip.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.pagePadding,
                    vertical: AppSizes.md,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1B9A63), Color(0xFF0B4D30)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${match.summary.home.name}  ${match.summary.homeScore?.line ?? '—'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${match.summary.away.name}  ${match.summary.awayScore?.line ?? '—'}',
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        match.summary.statusText ??
                            (match.summary.isLive
                                ? AppStrings.liveNow
                                : AppFormatters.relative(match.summary.startTime)),
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  tabs: [
                    for (final tab in tabs)
                      Tab(icon: Icon(tab.icon, size: 20), text: tab.label),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final tab in tabs) tab.builder(context),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TabDef {
  const _TabDef(this.label, this.icon, this.builder);
  final String label;
  final IconData icon;
  final Widget Function(BuildContext) builder;
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 200, height: 20),
            SizedBox(height: AppSizes.lg),
            SkeletonBox(width: double.infinity, height: 160),
            SizedBox(height: AppSizes.xl),
            SkeletonBox(width: double.infinity, height: 90),
          ],
        ),
      ),
    );
  }
}
