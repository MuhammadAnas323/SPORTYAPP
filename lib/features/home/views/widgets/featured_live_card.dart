import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../models/match_summary.dart';
import '../../../../models/sport_type.dart';
import '../../../../widgets/animations/pulsing_live_badge.dart';
import '../../../../widgets/common/app_avatar.dart';
import '../../../../widgets/common/sport_icon.dart';

/// The glassmorphism hero card showing the first currently-live match.
class FeaturedLiveCard extends StatelessWidget {
  const FeaturedLiveCard({super.key, required this.match, this.onTap});

  final MatchSummary match;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isFootball = match.sportType == SportType.football;
    final homeScore = match.homeScore?.line ?? '—';
    final awayScore = match.awayScore?.line ?? '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 208,
          decoration: BoxDecoration(
            gradient: isFootball
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF155E3B), Color(0xFF0B3D2A)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B9A63), Color(0xFF0B4D30)],
                  ),
            borderRadius: BorderRadius.circular(AppSizes.radiusCardLg),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B4D30).withValues(alpha: 0.45),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusCardLg),
            child: Stack(
              children: [
                // Frosted glass inner panel.
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SportIcon(
                            isFootball
                                ? SportIconName.football
                                : SportIconName.bat,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Text(
                              match.seriesName ?? match.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.85),
                                    letterSpacing: 0.4,
                                  ),
                            ),
                          ),
                          if (match.hasVideo) ...[
                            Icon(
                              Icons.play_circle_fill_rounded,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: AppSizes.sm),
                          ],
                          const PulsingLiveBadge(compact: true),
                        ],
                      ),
                      const Spacer(),
                      _ScoreLine(
                        name: match.home.name,
                        code: match.home.code,
                        score: homeScore,
                        isFootball: isFootball,
                      ),
                      const SizedBox(height: AppSizes.md),
                      _ScoreLine(
                        name: match.away.name,
                        code: match.away.code,
                        score: awayScore,
                        isFootball: isFootball,
                      ),
                      const Spacer(),
                      if (match.statusText != null && match.statusText!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.timelapse_rounded,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                match.statusText!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                    ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Positioned(
                  right: AppSizes.lg,
                  top: AppSizes.xl,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.6),
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

class _ScoreLine extends StatelessWidget {
  const _ScoreLine({
    required this.name,
    required this.code,
    required this.score,
    required this.isFootball,
  });

  final String name;
  final String code;
  final String score;
  final bool isFootball;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppAvatar(
          label: code,
          sportType: isFootball ? SportType.football : SportType.cricket,
          size: 34,
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Text(
          score,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}
