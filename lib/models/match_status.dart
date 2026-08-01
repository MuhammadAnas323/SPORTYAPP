/// Current phase of a match — drives the LIVE badge, filters and empty states.
enum MatchStatus { scheduled, live, completed, cancelled, abandoned }

/// How a match's outcome is treated in the UI.
enum MatchKind {
  /// Not started yet.
  upcoming,

  /// In progress right now.
  live,

  /// Finished (result known).
  recent,
}

extension MatchStatusX on MatchStatus {
  MatchKind get kind => switch (this) {
        MatchStatus.live => MatchKind.live,
        MatchStatus.scheduled => MatchKind.upcoming,
        MatchStatus.completed ||
        MatchStatus.cancelled ||
        MatchStatus.abandoned =>
          MatchKind.recent,
      };

  static MatchStatus fromWireValue(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.contains('live')) return MatchStatus.live;
    if (v.contains('sched') || v.contains('upcoming') || v.contains('not start')) {
      return MatchStatus.scheduled;
    }
    if (v.contains('abandon')) return MatchStatus.abandoned;
    if (v.contains('cancel')) return MatchStatus.cancelled;
    if (v.contains('complete') ||
        v.contains('finish') ||
        v.contains('result') ||
        v.contains('ended') ||
        v.contains('full time') ||
        v.contains('all out')) {
      return MatchStatus.completed;
    }
    return MatchStatus.scheduled;
  }
}
