import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/match_status.dart';
import '../../models/match_summary.dart';
import '../../models/sport_type.dart';
import '../animations/pulsing_live_badge.dart';
import '../common/app_avatar.dart';
import '../common/app_chips.dart';
import '../common/sport_icon.dart';

/// A normalized match card rendered by Home and Live.
///
/// Every value comes from a connected API via the adapter layer; when a field
/// is null the card shows an honest dash, never fabricated data.
class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match, this.onTap, this.heroTag});

  final MatchSummary match;
  final VoidCallback? onTap;

  /// When provided, enables the Hero flight into Match Detail.
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag ?? 'match-${match.connectionId}-${match.providerId}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(match: match),
                  const SizedBox(height: AppSizes.md),
                  _ScoreRow(match: match),
                  const SizedBox(height: AppSizes.md),
                  _Footer(match: match),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.match});

  final MatchSummary match;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        // Sport glyph.
        SportIcon(
          match.sportType == SportType.football
              ? SportIconName.football
              : SportIconName.bat,
          size: 13,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            match.seriesName ?? match.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        if (match.hasVideo) ...[
          Icon(
            Icons.play_circle_fill_rounded,
            size: 18,
            color: scheme.primary,
          ),
          const SizedBox(width: AppSizes.sm),
        ],
        if (match.isLive)
          const PulsingLiveBadge(compact: true)
        else if (match.statusText != null)
          PhasePill(
            text: match.statusText!,
            live: match.isLive,
          )
        else
          PhasePill(
            text: switch (match.kind) {
              MatchKind.upcoming => 'Upcoming',
              MatchKind.recent => 'Finished',
              MatchKind.live => 'Live',
            },
          ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.match});

  final MatchSummary match;

  @override
  Widget build(BuildContext context) {
    final home = match.home;
    final away = match.away;
    final homeScore = match.homeScore?.line ?? '—';
    final awayScore = match.awayScore?.line ?? '—';

    return Row(
      children: [
        _TeamSide(teamName: home.name, score: homeScore, teamCode: home.code, sport: match.sportType),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
          child: VsDivider(live: match.isLive),
        ),
        _TeamSide(teamName: away.name, score: awayScore, teamCode: away.code, sport: match.sportType),
      ],
    );
  }
}

class _TeamSide extends StatelessWidget {
  const _TeamSide({
    required this.teamName,
    required this.score,
    required this.teamCode,
    required this.sport,
  });

  final String teamName;
  final String score;
  final String teamCode;
  final SportType sport;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          AppAvatar(
            label: teamCode,
            sportType: sport,
            size: 34,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  score,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.match});

  final MatchSummary match;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final String line;
    if (match.kind == MatchKind.recent && match.result != null) {
      line = match.result!;
    } else if (match.kind == MatchKind.upcoming && match.startTime != null) {
      line = '${AppFormatters.day(match.startTime)}, ${AppFormatters.time(match.startTime)}';
    } else if (match.venue != null) {
      line = match.venue!;
    } else if (match.statusText != null) {
      line = match.statusText!;
    } else {
      line = '—';
    }

    return Row(
      children: [
        SourceTag(label: match.connectionLabel),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            line,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
