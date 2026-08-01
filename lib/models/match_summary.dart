import 'package:equatable/equatable.dart';

import '../core/utils/video_url.dart';
import 'match_status.dart';
import 'sport_type.dart';
import 'team.dart';

/// A single team's live line on a card — one innings for cricket, one side's
/// goal tally for football.
class TeamScore extends Equatable {
  const TeamScore({
    required this.team,
    this.runs,
    this.wickets,
    this.overs,
    this.goals,
    this.displayScore,
  });

  final Team team;

  /// Cricket: runs scored.
  final int? runs;

  /// Cricket: wickets lost.
  final int? wickets;

  /// Cricket: overs bowled.
  final double? overs;

  /// Football: goals.
  final int? goals;

  /// Raw provider string used verbatim when the provider formats its own line.
  final String? displayScore;

  /// Best-effort rendered line for any sport.
  String get line {
    if (displayScore != null && displayScore!.trim().isNotEmpty) {
      return displayScore!;
    }
    if (goals != null) return '$goals';
    if (runs != null) {
      final w = wickets == null ? '' : '/$wickets';
      final o = overs == null ? '' : ' ($overs)';
      return '$runs$w$o';
    }
    return '—';
  }

  @override
  List<Object?> get props => [team, runs, wickets, overs, goals, displayScore];
}

/// Normalized match — the single shape Home, Live and Match Detail render.
///
/// Every field is populated by a `SportsApiAdapter` from a real provider
/// response; anything the provider omits stays `null` and the UI shows an
/// honest placeholder rather than fabricated data.
class MatchSummary extends Equatable {
  const MatchSummary({
    required this.providerId,
    required this.connectionId,
    required this.connectionLabel,
    required this.sportType,
    required this.status,
    required this.home,
    required this.away,
    this.name,
    this.seriesName,
    this.venue,
    this.startTime,
    this.statusText,
    this.result,
    this.homeScore,
    this.awayScore,
    this.coverUrl,
    this.videoUrl,
  });

  /// Id assigned by the provider, used to scope detail fetches.
  final String providerId;

  /// Owning ApiConnection id.
  final String connectionId;

  /// Human label of the owning channel (shown as a source tag on cards).
  final String connectionLabel;

  final SportType sportType;
  final MatchStatus status;
  final Team home;
  final Team away;

  /// Provider's own display name, e.g. "India vs Australia".
  final String? name;

  /// e.g. "T20 World Cup", "Premier League".
  final String? seriesName;

  final String? venue;
  final DateTime? startTime;

  /// Raw phase text, e.g. "Innings Break", "65'", "Day 3 Tea".
  final String? statusText;

  /// Final result when known.
  final String? result;

  final TeamScore? homeScore;
  final TeamScore? awayScore;
  final String? coverUrl;

  /// Live video stream URL if the provider offers one (HLS `.m3u8`, MP4
  /// `.mp4` or DASH `.mpd`). `null` means no stream — the UI shows the
  /// regular data card instead of a player.
  final String? videoUrl;

  /// Whether the provider gave us a stream that is safe to hand to a video
  /// player. Mirrored live so cards can auto-switch player ↔ data card.
  bool get hasVideo => MatchVideoUrl.isPlayable(videoUrl);

  bool get isLive => status == MatchStatus.live;

  MatchKind get kind => status.kind;

  /// Display title for cards: provider name or "Home vs Away".
  String get title =>
      (name != null && name!.trim().isNotEmpty) ? name! : '${home.name} vs ${away.name}';

  /// The side currently batting / ahead for hero ordering.
  bool get homeIsBatting => homeScore?.runs != null && awayScore?.runs == null;

  String get sportKey => sportType.key;

  @override
  List<Object?> get props => [
        providerId,
        connectionId,
        connectionLabel,
        sportType,
        status,
        home,
        away,
        name,
        seriesName,
        venue,
        startTime,
        statusText,
        result,
        homeScore,
        awayScore,
        coverUrl,
        videoUrl,
      ];
}
