import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../models/api_connection.dart';
import '../../../../models/channel.dart';
import '../../../../models/connection_status.dart';
import '../../../../repositories/providers.dart';
import '../../../../services/feed_store.dart';

/// Immutable state for the API Integrations list screen.
class ApiIntegrationsState {
  const ApiIntegrationsState({
    required this.connections,
    this.liveByConnection = const {},
  });

  final List<ApiConnection> connections;

  /// connectionId → whether any currently-live item came from it. Computed by
  /// aggregating the real feed so the "Live now" pill is always honest.
  final Map<String, bool> liveByConnection;

  bool channelIsLive(String connectionId) =>
      liveByConnection[connectionId] ?? false;

  ApiIntegrationsState copyWith({
    List<ApiConnection>? connections,
    Map<String, bool>? liveByConnection,
  }) {
    return ApiIntegrationsState(
      connections: connections ?? this.connections,
      liveByConnection: liveByConnection ?? this.liveByConnection,
    );
  }
}

/// ViewModel for the API integrations list — derives from the shared
/// [feedStoreProvider] (already fetched/cached) plus the connection list, so
/// navigating here never re-fetches the whole feed.
final apiIntegrationsViewModelProvider =
    NotifierProvider<ApiIntegrationsViewModel, ApiIntegrationsState>(
  ApiIntegrationsViewModel.new,
);

class ApiIntegrationsViewModel extends Notifier<ApiIntegrationsState> {
  @override
  ApiIntegrationsState build() {
    ref.watch(connectionsProvider);
    final connections = ref.read(connectionsProvider).valueOrNull ?? const [];
    final feed = ref.watch(feedStoreProvider).valueOrNull?.feed ??
        const AggregatedFeed();

    final liveByConnection = <String, bool>{};
    for (final channel in feed.channels) {
      liveByConnection[channel.connection.id] =
          channel.items.any((m) => m.isLive);
    }

    return ApiIntegrationsState(
      connections: connections,
      liveByConnection: liveByConnection,
    );
  }

  /// Pull-to-refresh re-queries the connected sources via the shared store.
  Future<void> refresh() => ref.read(feedStoreProvider.notifier).refresh();

  Future<void> toggleEnabled(String id, bool enabled) async {
    await ref.read(connectionsProvider.notifier).setEnabled(id, enabled);
  }

  Future<void> delete(String id) async {
    await ref.read(connectionsProvider.notifier).delete(id);
  }

  /// On-demand re-test of a saved connection (keeps the label/url unchanged).
  Future<void> reTest(String id) async {
    final connection =
        state.connections.where((c) => c.id == id).firstOrNull;
    if (connection == null) return;

    final adapter =
        ref.read(feedAggregatorProvider).adapterFor(connection.sportType);
    final notifier = ref.read(connectionsProvider.notifier);

    if (adapter == null) {
      await notifier.save(
        connection.copyWith(
          status: ConnectionStatus.failed,
          lastTestedAt: DateTime.now(),
          lastError: 'No adapter for ${connection.sportType.label} yet.',
        ),
      );
      return;
    }

    await notifier.save(
      connection.copyWith(status: ConnectionStatus.testing, lastError: null),
    );

    try {
      final result = await adapter.testConnection(connection);
      await notifier.save(
        connection.copyWith(
          status: result.success
              ? ConnectionStatus.connected
              : ConnectionStatus.failed,
          lastTestedAt: DateTime.now(),
          lastError: result.success ? null : result.message,
        ),
      );
    } catch (error) {
      await notifier.save(
        connection.copyWith(
          status: ConnectionStatus.failed,
          lastTestedAt: DateTime.now(),
          lastError: normalizeError(error).message,
        ),
      );
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
