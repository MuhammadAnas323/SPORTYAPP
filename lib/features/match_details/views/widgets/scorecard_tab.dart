import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/match_detail.dart';
import '../../../../models/player.dart';
import '../../../../widgets/common/empty_state.dart';

/// Scorecard / match-stats tab.
///
/// Renders cricket innings tables when the provider returns innings, or
/// football stat bars when it returns statistics. The tab only appears when
/// the source has data for it (driven by the parent screen).
class ScorecardTab extends StatelessWidget {
  const ScorecardTab({super.key, required this.detail});

  final MatchDetail detail;

  @override
  Widget build(BuildContext context) {
    if (detail.innings.isNotEmpty) {
      return _CricketScorecard(innings: detail.innings);
    }
    if (detail.matchStats.isNotEmpty) {
      return _FootballStats(stats: detail.matchStats);
    }
    return const Center(
      child: EmptyState(
        icon: Icons.table_chart_outlined,
        title: AppStrings.tabScorecard,
        body: AppStrings.noScorecard,
        compact: true,
      ),
    );
  }
}

class _CricketScorecard extends StatelessWidget {
  const _CricketScorecard({required this.innings});

  final List<InningsCard> innings;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      itemCount: innings.length,
      itemBuilder: (context, index) {
        final inn = innings[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.lg),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${inn.team.name}  —  ${inn.scoreLine}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (inn.extras != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Extras: ${inn.extras}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: AppSizes.lg),
                  if (inn.batting.isNotEmpty)
                    _BattingTable(records: inn.batting)
                  else
                    Text(
                      inn.notes ?? 'No batting line returned by the source.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (inn.bowling.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.lg),
                    _BowlingTable(records: inn.bowling),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BattingTable extends StatelessWidget {
  const _BattingTable({required this.records});

  final List<BattingRecord> records;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.4),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1.2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _headerRow(context, const ['Batter', 'R', 'B', '4s', 'SR']),
        for (final r in records)
          TableRow(
            children: [
              _cell(context, _batterLabel(r), bold: true),
              _cell(context, _dash(r.runs)),
              _cell(context, _dash(r.balls)),
              _cell(context, _dash(r.fours)),
              _cell(context, r.strikeRate?.toStringAsFixed(1) ?? '—'),
            ],
          ),
      ],
    );
  }

  String _batterLabel(BattingRecord r) {
    if (r.out == false) return '${_dash(r.runs)}*';
    return _dash(r.runs);
  }

  String _dash(int? value) => value?.toString() ?? '—';
}

class _BowlingTable extends StatelessWidget {
  const _BowlingTable({required this.records});

  final List<BowlingRecord> records;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1.2),
      },
      children: [
        _headerRow(context, const ['Bowler', 'O', 'M', 'R', 'W']),
        for (final r in records)
          TableRow(
            children: [
              _cell(context, _fmt(r.overs), bold: true),
              _cell(context, _fmt(r.overs)),
              _cell(context, _fmt(r.maidens)),
              _cell(context, _fmt(r.runsConceded)),
              _cell(context, _fmt(r.wickets)),
            ],
          ),
      ],
    );
  }

  String _fmt(Object? v) => v == null ? '—' : v.toString();
}

class _FootballStats extends StatelessWidget {
  const _FootballStats({required this.stats});

  final List<MatchStatLine> stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg,
              vertical: AppSizes.md,
            ),
            child: Column(
              children: [
                Text(
                  stat.label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(
                        stat.home ?? '—',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Expanded(
                      child: _Bar(
                        home: _num(stat.home),
                        away: _num(stat.away),
                        color: scheme.primary,
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: Text(
                        stat.away ?? '—',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _num(String? v) {
    final parsed = double.tryParse(v ?? '');
    if (parsed == null) return 0.5;
    return parsed.isFinite ? parsed : 0.5;
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.home, required this.away, required this.color});

  final double home;
  final double away;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final total = (home + away).clamp(0.0001, double.infinity);
    final homeRatio = home / total;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: SizedBox(
        height: 6,
        child: Row(
          children: [
            Expanded(
              flex: (homeRatio * 1000).round(),
              child: ColoredBox(color: color),
            ),
            Expanded(
              flex: ((1 - homeRatio) * 1000).round().clamp(1, 1000),
              child: ColoredBox(
                color: color.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TableRow _headerRow(BuildContext context, List<String> labels) {
  final scheme = Theme.of(context).colorScheme;
  return TableRow(
    children: [
      for (final label in labels)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
    ],
  );
}

Widget _cell(BuildContext context, String text, {bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
    ),
  );
}
