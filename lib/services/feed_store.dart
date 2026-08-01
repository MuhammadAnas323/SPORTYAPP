import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/channel.dart';
import '../repositories/providers.dart';

/// How often the feed is re-fetched while at least one match is live.
/// This is what keeps live cricket cards ticking over ball-by-ball.
const Duration livePollInterval = Duration(seconds: 45);

/// Immutable state of the shared aggregated feed.
class FeedState {
  const FeedState({required this.feed, this.isRefreshing = false});

  final AggregatedFeed feed;

  /// True while a background/manual refresh is in flight. The previous
  /// [feed] stays visible so screens never blank out mid-refresh.
  final bool isRefreshing;

  FeedState copyWith({AggregatedFeed? feed, bool? isRefreshing}) {
    return FeedState(
      feed: feed ?? this.feed,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// Single source of truth for the aggregated feed.
///
/// Home, Live, Profile and Match Detail all watch this provider instead of
/// fetching the sport APIs themselves. The feed is fetched once, cached and
/// shared across every screen — so navigating never re-triggers loading.
///
/// While at least one match is live it also polls the connected sources so
/// scores and cards update automatically (ball-by-ball for cricket).
final feedStoreProvider =
    AsyncNotifierProvider<FeedStore, FeedState>(FeedStore.new);

class FeedStore extends AsyncNotifier<FeedState> {
  Timer? _pollTimer;
  bool _refreshing = false;

  @override
  Future<FeedState> build() async {
    // Rebuild whenever the persisted connection list changes (add/edit/delete).
    ref.watch(connectionsProvider);
    ref.onDispose(() {
      _pollTimer?.cancel();
      _pollTimer = null;
    });
    return _aggregateAndMirror();
  }

  Future<FeedState> _aggregateAndMirror() async {
    final connections = ref.read(connectionsProvider).valueOrNull ?? const [];
    final feed = await ref.read(feedAggregatorProvider).aggregate(connections);
    await ref.read(liveSyncServiceProvider).mirror(feed);
    _schedulePoll(feed);
    return FeedState(feed: feed);
  }

  void _schedulePoll(AggregatedFeed feed) {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (feed.liveOnly.isEmpty) return;
    _pollTimer = Timer.periodic(livePollInterval, (_) => refresh());
  }

  /// Re-fetches the feed. Keeps the last good data on screen on failure and
  /// never shows a blank loading state during a background poll.
  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    final previous = state.valueOrNull;
    if (previous != null && !previous.isRefreshing) {
      state = AsyncData(previous.copyWith(isRefreshing: true));
    }
    try {
      final loaded = await _aggregateAndMirror();
      state = AsyncData(loaded);
    } catch (error, stack) {
      state = previous != null
          ? AsyncData(previous.copyWith(isRefreshing: false))
          : AsyncError(error, stack);
    } finally {
      _refreshing = false;
    }
  }
}
