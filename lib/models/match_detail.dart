import 'package:equatable/equatable.dart';

import 'commentary_item.dart';
import 'match_summary.dart';
import 'player.dart';
import 'team.dart';

/// A cricket innings card (batting + bowling columns).
class InningsCard extends Equatable {
  const InningsCard({
    required this.team,
    this.total,
    this.wickets,
    this.overs,
    this.extras,
    this.batting = const [],
    this.bowling = const [],
    this.notes,
  });

  final Team team;
  final int? total;
  final int? wickets;
  final double? overs;
  final String? extras;

  /// Ordered batting lines.
  final List<BattingRecord> batting;

  /// Ordered bowling lines.
  final List<BowlingRecord> bowling;

  /// Provider note, e.g. "Yet to bat".
  final String? notes;

  String get scoreLine {
    final w = wickets == null ? '' : '/$wickets';
    final o = overs == null ? '' : ' ($overs)';
    return total == null ? '—' : '$total$w$o';
  }

  @override
  List<Object?> get props =>
      [team, total, wickets, overs, extras, batting, bowling, notes];
}

/// One football-style stat (possession, shots, corners…).
class MatchStatLine extends Equatable {
  const MatchStatLine({
    required this.label,
    this.home,
    this.away,
  });

  final String label;
  final String? home;
  final String? away;

  @override
  List<Object?> get props => [label, home, away];
}

/// A normalized match detail — everything the Info / Scorecard / Stats /
/// Commentary tabs can render. Tabs hide themselves when the provider returns
/// no data for their section.
class MatchDetail extends Equatable {
  const MatchDetail({
    required this.summary,
    this.innings = const [],
    this.matchStats = const [],
    this.commentary = const [],
    this.lineups = const [],
  });

  final MatchSummary summary;

  /// Cricket scorecards, one per innings.
  final List<InningsCard> innings;

  /// Football-style head-to-head stats.
  final List<MatchStatLine> matchStats;

  /// Live ball-by-ball or minute-by-minute feed.
  final List<CommentaryItem> commentary;

  /// Available players (lineups) if the provider returns them.
  final List<Player> lineups;

  bool get hasScorecard => innings.isNotEmpty || matchStats.isNotEmpty;
  bool get hasCommentary => commentary.isNotEmpty;

  @override
  List<Object?> get props =>
      [summary, innings, matchStats, commentary, lineups];
}
