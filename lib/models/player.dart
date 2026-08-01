import 'package:equatable/equatable.dart';

/// A player appearing in scorecards/commentary, normalized.
class Player extends Equatable {
  const Player({
    this.id,
    required this.name,
    this.role,
    this.batting = const BattingRecord.placeholder(),
    this.bowling = const BowlingRecord.placeholder(),
  });

  final String? id;
  final String name;

  /// e.g. "Batter", "Bowler", "All-rounder", "GK", "Striker".
  final String? role;

  final BattingRecord batting;
  final BowlingRecord bowling;

  @override
  List<Object?> get props => [id, name, role, batting, bowling];
}

/// Batting line for one player. All fields nullable — a defensive default is
/// rendered by the UI rather than a crash.
class BattingRecord extends Equatable {
  const BattingRecord({
    this.runs,
    this.balls,
    this.fours,
    this.sixes,
    this.strikeRate,
    this.out,
    this.dismissal,
  });

  const BattingRecord.placeholder()
      : runs = null,
        balls = null,
        fours = null,
        sixes = null,
        strikeRate = null,
        out = true,
        dismissal = '—';

  final int? runs;
  final int? balls;
  final int? fours;
  final int? sixes;
  final double? strikeRate;

  /// True when the batter has been dismissed; null when the API is silent.
  final bool? out;
  final String? dismissal;

  @override
  List<Object?> get props =>
      [runs, balls, fours, sixes, strikeRate, out, dismissal];
}

/// Bowling line for one player.
class BowlingRecord extends Equatable {
  const BowlingRecord({
    this.overs,
    this.maidens,
    this.runsConceded,
    this.wickets,
    this.economy,
  });

  const BowlingRecord.placeholder()
      : overs = null,
        maidens = null,
        runsConceded = null,
        wickets = null,
        economy = null;

  final double? overs;
  final int? maidens;
  final int? runsConceded;
  final int? wickets;
  final double? economy;

  @override
  List<Object?> get props => [overs, maidens, runsConceded, wickets, economy];
}
