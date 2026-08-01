import '../../models/api_connection.dart';
import '../../models/match_detail.dart';
import '../../models/match_summary.dart';
import '../../models/sport_type.dart';
import 'adapter_test_result.dart';

/// Contract every sport-family adapter must satisfy.
///
/// A new sport (basketball, tennis…) is added by implementing this interface
/// for its [SportType] and registering the adapter in the provider list — no
/// other layer changes.
abstract class SportsApiAdapter {
  /// Which [SportType] this adapter speaks.
  SportType get sportType;

  /// Human name, e.g. "Cricket adapter".
  String get displayName;

  /// Lightweight real validation call against the user's host/key.
  ///
  /// Returns a [AdapterTestResult] — on failure the message must be a
  /// readable explanation of *why* (bad host, bad key, timeout, odd shape).
  Future<AdapterTestResult> testConnection(ApiConnection connection);

  /// Fetches the provider's current feed (upcoming / recent / live) and maps
  /// it into normalized [MatchSummary] items.
  ///
  /// Implementations must be defensive: missing or mistyped fields become
  /// `null`, never a crash. On an unrecognized response shape, throw an
  /// [AppException] with a readable message.
  Future<List<MatchSummary>> fetchFeed(ApiConnection connection);

  /// Fetches a single match's detail (scorecard / stats / commentary) from the
  /// provider. Providers without a detail endpoint may return a detail built
  /// solely from the summary.
  Future<MatchDetail> fetchMatchDetail(
    ApiConnection connection,
    MatchSummary match,
  );
}
