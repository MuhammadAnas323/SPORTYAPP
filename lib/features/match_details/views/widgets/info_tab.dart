import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/match_detail.dart';
import '../../../../models/sport_type.dart';
import '../../../../widgets/common/app_avatar.dart';
import '../../../../widgets/common/stat_pill.dart';

/// Info tab — everything the provider told us about the match itself.
class InfoTab extends StatelessWidget {
  const InfoTab({super.key, required this.detail});

  final MatchDetail detail;

  @override
  Widget build(BuildContext context) {
    final match = detail.summary;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      children: [
        // Team vs team.
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Row(
              children: [
                Expanded(
                  child: _TeamColumn(
                    code: match.home.code,
                    name: match.home.name,
                    sport: match.sportType,
                    score: match.homeScore?.line,
                  ),
                ),
                Text(
                  match.isLive ? 'LIVE' : 'VS',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: match.isLive
                            ? const Color(0xFFE53950)
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Expanded(
                  child: _TeamColumn(
                    code: match.away.code,
                    name: match.away.name,
                    sport: match.sportType,
                    score: match.awayScore?.line,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.lg),

        // Stat grid.
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: [
            StatPill(
              value: AppFormatters.relative(match.startTime),
              label: 'Start',
            ),
            if (match.statusText != null && match.statusText!.isNotEmpty)
              StatPill(value: match.statusText!, label: 'Status', accent: match.isLive),
            if (match.seriesName != null)
              StatPill(value: match.seriesName!, label: 'Series'),
            if (match.venue != null) StatPill(value: match.venue!, label: 'Venue'),
          ],
        ),
        const SizedBox(height: AppSizes.lg),

        if (match.result != null) ...[
          Card(
            color: scheme.secondaryContainer.withValues(alpha: 0.6),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_rounded,
                      color: scheme.onSecondaryContainer, size: 20),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      match.result!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: scheme.onSecondaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
        ],
      ],
    );
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({
    required this.code,
    required this.name,
    required this.sport,
    this.score,
  });

  final String code;
  final String name;
  final SportType sport;
  final String? score;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppAvatar(label: code, sportType: sport, size: 56),
        const SizedBox(height: AppSizes.sm),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (score != null) ...[
          const SizedBox(height: 2),
          Text(
            score!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ],
    );
  }
}
