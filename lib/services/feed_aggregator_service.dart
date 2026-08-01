import '../core/errors/app_exception.dart';
import '../models/api_connection.dart';
import '../models/channel.dart';
import '../models/match_status.dart';
import '../models/match_summary.dart';
import '../models/sport_type.dart';
import 'adapters/sports_api_adapter.dart';

/// Fans out to every enabled, verified connection and merges the results into
/// normalized models for Home and Live.
///
/// **Error isolation:** each channel is fetched independently. A channel that
/// fails keeps its `lastError` (rendered as an inline chip) while the healthy
/// channels continue to render — one broken source never blanks a screen.
class FeedAggregatorService {
  FeedAggregatorService(this._adapters);

  final List<SportsApiAdapter> _adapters;

  /// Resolves the adapter registered for [type], or null when the user chose a
  /// sport this build has no adapter for yet (an honest "not supported" state).
  SportsApiAdapter? adapterFor(SportType type) {
    for (final adapter in _adapters) {
      if (adapter.sportType == type) return adapter;
    }
    return null;
  }

  /// Aggregates every active connection. Connections that are paused or
  /// unverified are skipped entirely.
  Future<AggregatedFeed> aggregate(List<ApiConnection> connections) async {
    final active = connections.where((c) => c.feedsFeed).toList(growable: false);

    final feeds = await Future.wait(active.map(_loadChannel));

    final channels = <ChannelFeed>[];
    for (final feed in feeds) {
      final sorted = [...feed.items]..sort(_compareMatches);
      channels.add(
        ChannelFeed(
          connection: feed.connection,
          items: sorted,
          lastError: feed.lastError,
        ),
      );
    }

    final liveOnly = <MatchSummary>[
      for (final channel in channels)
        ...channel.items.where((match) => match.isLive),
    ]..sort(_compareMatches);

    return AggregatedFeed(
      channels: channels,
      liveOnly: liveOnly,
      lastRefreshedAt: DateTime.now(),
    );
  }

  Future<ChannelFeed> _loadChannel(ApiConnection connection) async {
    final adapter = adapterFor(connection.sportType);
    if (adapter == null) {
      return ChannelFeed(
        connection: connection,
        lastError:
            'No adapter for ${connection.sportType.label} yet — this sport is not '
            'supported in this build.',
      );
    }

    try {
      final items = await adapter.fetchFeed(connection);
      return ChannelFeed(
        connection: connection,
        items: items
            .map((m) => _bindSource(m, connection))
            .toList(growable: false),
      );
    } catch (error) {
      final readable = normalizeError(error).message;
      return ChannelFeed(connection: connection, lastError: readable);
    }
  }

  /// Stamps each normalized match with the owning connection's id/label so the
  /// UI can tag cards and scope detail fetches back to the right adapter.
  MatchSummary _bindSource(MatchSummary match, ApiConnection connection) {
    return MatchSummary(
      providerId: match.providerId,
      connectionId: connection.id,
      connectionLabel: connection.label,
      sportType: match.sportType,
      status: match.status,
      home: match.home,
      away: match.away,
      name: match.name,
      seriesName: match.seriesName,
      venue: match.venue,
      startTime: match.startTime,
      statusText: match.statusText,
      result: match.result,
      homeScore: match.homeScore,
      awayScore: match.awayScore,
      coverUrl: match.coverUrl,
      videoUrl: match.videoUrl,
    );
  }

  /// Sorts: live first, then upcoming by start time, then recent.
  static int _compareMatches(MatchSummary a, MatchSummary b) {
    if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
    if (a.status == MatchStatus.scheduled && b.status == MatchStatus.scheduled) {
      final at = a.startTime?.millisecondsSinceEpoch ?? 0;
      final bt = b.startTime?.millisecondsSinceEpoch ?? 0;
      return at.compareTo(bt);
    }
    final ar = a.startTime?.millisecondsSinceEpoch ?? 0;
    final br = b.startTime?.millisecondsSinceEpoch ?? 0;
    return br.compareTo(ar);
  }
}
