import 'package:equatable/equatable.dart';

import '../models/api_connection.dart';
import '../models/match_summary.dart';

/// Renderable state of one connected channel inside the aggregated feed.
///
/// Error isolation: a channel that fails its fetch is still listed with a
/// [lastError] while healthy channels keep rendering — one broken source never
/// blanks Home or Live.
class ChannelFeed extends Equatable {
  const ChannelFeed({
    required this.connection,
    this.items = const [],
    this.lastError,
    this.isLoading = false,
  });

  final ApiConnection connection;
  final List<MatchSummary> items;
  final String? lastError;
  final bool isLoading;

  bool get hasError => lastError != null;
  bool get isLiveCapable => connection.isLiveCapable;

  ChannelFeed copyWith({
    List<MatchSummary>? items,
    String? lastError,
    bool clearError = false,
    bool? isLoading,
  }) {
    return ChannelFeed(
      connection: connection,
      items: items ?? this.items,
      lastError: clearError ? null : lastError ?? this.lastError,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [connection, items, lastError, isLoading];
}

/// Aggregated feed state handed to Home and Live ViewModels.
class AggregatedFeed extends Equatable {
  const AggregatedFeed({
    this.channels = const [],
    this.liveOnly = const [],
    this.lastRefreshedAt,
  });

  /// One [ChannelFeed] per enabled + verified connection.
  final List<ChannelFeed> channels;

  /// Convenience: every live item across all channels, already sorted.
  final List<MatchSummary> liveOnly;

  final DateTime? lastRefreshedAt;

  /// All items across all channels, for Home's unfiltered feed.
  List<MatchSummary> get allItems =>
      channels.expand((c) => c.items).toList(growable: false);

  bool get isEmpty => channels.every((c) => c.items.isEmpty);

  @override
  List<Object?> get props => [channels, liveOnly, lastRefreshedAt];
}
