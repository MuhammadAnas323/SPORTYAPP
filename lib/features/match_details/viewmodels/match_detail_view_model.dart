import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../models/match_detail.dart';
import '../../../models/match_summary.dart';
import '../../../repositories/providers.dart';
import '../../../services/feed_store.dart';

/// Route args for match detail (deep-link ready: both ids are stable).
class MatchDetailArgs extends Equatable {
  const MatchDetailArgs({
    required this.connectionId,
    required this.providerId,
  });

  final String connectionId;
  final String providerId;

  @override
  List<Object?> get props => [connectionId, providerId];
}

/// ViewModel for Match Detail.
///
/// Reconstructs the owning connection and match from ids (so a deep link
/// works even without navigating from Home/Live), then asks the correct
/// sport adapter for full detail. The match is resolved from the shared
/// feed store whenever possible — no extra full-feed fetch on navigation.
final matchDetailViewModelProvider = AsyncNotifierProvider.family<
    MatchDetailViewModel, MatchDetail, MatchDetailArgs>(
  MatchDetailViewModel.new,
);

class MatchDetailViewModel extends FamilyAsyncNotifier<MatchDetail, MatchDetailArgs> {
  @override
  Future<MatchDetail> build(MatchDetailArgs args) async {
    ref.watch(connectionsProvider);

    final connections = ref.read(connectionsProvider).valueOrNull ?? const [];
    final connection = connections
        .where((c) => c.id == args.connectionId)
        .firstOrNull;

    if (connection == null) {
      throw const NotFoundException(
        'This channel no longer exists. It may have been deleted.',
      );
    }

    final aggregator = ref.read(feedAggregatorProvider);
    final adapter = aggregator.adapterFor(connection.sportType);
    if (adapter == null) {
      throw AdapterException(
        'No adapter available for ${connection.sportType.label} yet.',
      );
    }

    // Fast path: resolve the normalized summary from the shared feed store,
    // which is already loaded and cached by Home/Live.
    MatchSummary? match;
    final cached = ref.read(feedStoreProvider).valueOrNull?.feed;
    if (cached != null) {
      match = cached.allItems
          .where((m) =>
              m.connectionId == args.connectionId &&
              m.providerId == args.providerId)
          .firstOrNull;
    }

    // Deep-link / first launch before the store resolved: fetch once.
    if (match == null) {
      final feed = await aggregator.aggregate(connections);
      match = feed.allItems
          .where((m) =>
              m.connectionId == args.connectionId &&
              m.providerId == args.providerId)
          .firstOrNull;
    }

    if (match == null) {
      throw const NotFoundException(
        'This match is no longer in the channel feed.',
      );
    }

    return adapter.fetchMatchDetail(connection, match);
  }

  Future<void> retry(MatchDetailArgs args) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(args));
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
