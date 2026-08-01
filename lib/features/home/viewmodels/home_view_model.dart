import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/channel.dart';
import '../../../models/sport_type.dart';
import '../../../services/feed_store.dart';

/// Immutable UI state for the Home screen.
class HomeState {
  const HomeState({
    required this.feed,
    this.filter,
    this.isRefreshing = false,
    this.isLoading = false,
  });

  final AggregatedFeed feed;

  /// `null` means "All sports".
  final SportType? filter;
  final bool isRefreshing;

  /// True only while the feed has never loaded (first open).
  final bool isLoading;

  /// Channels to render after applying the sport filter. A channel is kept
  /// only when it carries matches for the filter or a fetch error (errors are
  /// never hidden by a filter).
  List<ChannelFeed> get visibleChannels {
    final all = feed.channels;
    if (filter == null) return all;
    return [
      for (final channel in all)
        if (channel.items.any((m) => m.sportType == filter) || channel.hasError)
          ChannelFeed(
            connection: channel.connection,
            items: channel.items
                .where((m) => m.sportType == filter)
                .toList(growable: false),
            lastError: channel.lastError,
          ),
    ];
  }

  HomeState copyWith({
    AggregatedFeed? feed,
    SportType? filter,
    bool clearFilter = false,
    bool? isRefreshing,
    bool? isLoading,
  }) {
    return HomeState(
      feed: feed ?? this.feed,
      filter: clearFilter ? null : filter ?? this.filter,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// ViewModel for Home — derives everything from the shared [feedStoreProvider]
/// (which owns fetching, caching and live polling) plus this screen's filter.
final homeViewModelProvider =
    NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);

class HomeViewModel extends Notifier<HomeState> {
  SportType? _filter;

  @override
  HomeState build() {
    final store = ref.watch(feedStoreProvider);
    return HomeState(
      feed: store.valueOrNull?.feed ?? const AggregatedFeed(),
      filter: _filter,
      isRefreshing: store.valueOrNull?.isRefreshing ?? false,
      isLoading: store.isLoading && !store.hasValue,
    );
  }

  /// Pull-to-refresh: re-queries every connected source via the shared store.
  Future<void> refresh() => ref.read(feedStoreProvider.notifier).refresh();

  /// Applies a sport filter without re-fetching anything.
  void setFilter(SportType? filter) {
    _filter = filter;
    state = state.copyWith(
      filter: filter,
      clearFilter: filter == null,
    );
  }
}
