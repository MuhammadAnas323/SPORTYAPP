import 'package:intl/intl.dart';

/// Formatting helpers for dates, times and sport-specific display strings.
///
/// All formatters are locale-aware via `intl` and never mutate domain models.
abstract final class AppFormatters {
  AppFormatters._();

  static final DateFormat _time = DateFormat.jm();
  static final DateFormat _day = DateFormat.EEEE();
  static final DateFormat _date = DateFormat('d MMM');

  /// "3:30 PM" for a kick-off / toss time.
  static String time(DateTime? value) =>
      value == null ? '—' : _time.format(value.toLocal());

  /// "Friday" — used on upcoming cards.
  static String day(DateTime? value) =>
      value == null ? '—' : _day.format(value.toLocal());

  /// "12 Aug" — used as a compact date.
  static String shortDate(DateTime? value) =>
      value == null ? '—' : _date.format(value.toLocal());

  /// Relative label like "in 3h", "2d ago". Falls back to a plain date.
  static String relative(DateTime? value) {
    if (value == null) return '—';
    final now = DateTime.now();
    final diff = value.toLocal().difference(now);
    if (diff.inSeconds.abs() < 60) return 'just now';
    if (diff.inMinutes.abs() < 60) {
      return diff.inMinutes >= 0
          ? 'in ${diff.inMinutes}m'
          : '${diff.inMinutes.abs()}m ago';
    }
    if (diff.inHours.abs() < 24) {
      return diff.inHours >= 0
          ? 'in ${diff.inHours}h'
          : '${diff.inHours.abs()}h ago';
    }
    if (diff.inDays.abs() < 7) {
      return diff.inDays >= 0
          ? 'in ${diff.inDays}d'
          : '${diff.inDays.abs()}d ago';
    }
    return shortDate(value);
  }

  /// Masks a long API key for display, keeping the first/last few characters.
  /// Returns a fixed placeholder when the key is empty or very short.
  static String maskSecret(String secret) {
    final trimmed = secret.trim();
    if (trimmed.length <= 6) return '••••••••';
    final head = trimmed.substring(0, 3);
    final tail = trimmed.substring(trimmed.length - 3);
    return '$head••••••$tail';
  }

  /// Formats a cricket innings score line like `IND 178/4 (20)`.
  static String cricketScoreLine({
    int? runs,
    int? wickets,
    int? overs,
  }) {
    if (runs == null) return '—';
    final w = wickets == null ? '' : '/$wickets';
    final o = overs == null ? '' : ' ($overs)';
    return '$runs$w$o';
  }

  /// Formats a football score line like `2 – 1`.
  static String footballScoreLine({int? home, int? away}) {
    if (home == null || away == null) return 'v';
    return '$home – $away';
  }

  /// Short label for a sport type used in chips/tags.
  static String sportLabel(String sport) => sport.toLowerCase();

  /// Parses an ISO-8601 timestamp defensively; returns null on failure.
  static DateTime? tryParseIso(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed != null) return parsed;
    // Some cricket APIs ship epoch millisecond values as strings.
    final asInt = int.tryParse(raw.trim());
    if (asInt != null) {
      if (asInt > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(asInt);
      }
      return DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
    }
    return null;
  }
}
