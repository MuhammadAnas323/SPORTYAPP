import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/channel.dart';
import '../../../models/match_summary.dart';
import '../../../models/sport_type.dart';
import '../../../services/feed_store.dart';

/// Immutable UI state for the Live screen.
class LiveState {
  const LiveState({
    required this.feed,
    this.filter,
    this.isLoading = false,
  });

  final AggregatedFeed feed;

  /// `null` means "All sports".
  final SportType? filter;

  /// True only while the feed has never loaded (first open).
  final bool isLoading;

  /// Only matches currently reported as live, aggregated across every
  /// enabled + verified source, optionally filtered by sport.
  List<MatchSummary> get visibleMatches {
    final live = feed.liveOnly;
    if (filter == null) return live;
    return live.where((m) => m.sportType == filter).toList(growable: false);
  }

  LiveState copyWith({
    SportType? filter,
    bool clearFilter = false,
    bool? isLoading,
  }) {
    return LiveState(
      feed: feed,
      filter: clearFilter ? null : filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// ViewModel for Live — derives from the shared [feedStoreProvider] (which
/// owns fetching, caching and live polling) plus this screen's filter.
final liveViewModelProvider =
    NotifierProvider<LiveViewModel, LiveState>(LiveViewModel.new);

class LiveViewModel extends Notifier<LiveState> {
  SportType? _filter;

  @override
  LiveState build() {
    final store = ref.watch(feedStoreProvider);
    return LiveState(
      feed: store.valueOrNull?.feed ?? const AggregatedFeed(),
      filter: _filter,
      isLoading: store.isLoading && !store.hasValue,
    );
  }

  /// Pull-to-refresh: re-queries every connected source via the shared store.
  Future<void> refresh() => ref.read(feedStoreProvider.notifier).refresh();

  void setFilter(SportType? filter) {
    _filter = filter;
    state = state.copyWith(
      filter: filter,
      clearFilter: filter == null,
    );
  }
}
