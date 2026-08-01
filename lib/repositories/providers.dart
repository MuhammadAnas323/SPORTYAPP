import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/api_connection.dart';
import '../services/adapters/cricket_api_adapter.dart';
import '../services/adapters/football_api_adapter.dart';
import '../services/adapters/sports_api_adapter.dart';
import '../services/feed_aggregator_service.dart';
import '../services/live_sync_service.dart';
import 'connection_repository.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) {
  return ConnectionRepository(
    FirebaseAuth.instance,
    ref.watch(firestoreProvider),
  );
});

/// Mirrors live match data into Realtime Database (Firestore holds the saved
/// connections; Realtime DB carries the live stream).
final liveSyncServiceProvider = Provider<LiveSyncService>((ref) {
  return LiveSyncService(FirebaseDatabase.instance, FirebaseAuth.instance);
});

// ---- Adapters + aggregator --------------------------------------------------

/// Register a new sport by appending its adapter here — nothing else changes.
final sportsAdaptersProvider = Provider<List<SportsApiAdapter>>((ref) {
  return [CricketApiAdapter(), FootballApiAdapter()];
});

final feedAggregatorProvider = Provider<FeedAggregatorService>((ref) {
  return FeedAggregatorService(ref.watch(sportsAdaptersProvider));
});

// ---- Connections state -------------------------------------------------------

/// Single source of truth for the persisted connection list.
///
/// Home/Live/Profile all watch this; any add/edit/delete/re-test flows through
/// the notifier methods so every screen stays in sync.
final connectionsProvider =
    AsyncNotifierProvider<ConnectionsNotifier, List<ApiConnection>>(
  ConnectionsNotifier.new,
);

class ConnectionsNotifier extends AsyncNotifier<List<ApiConnection>> {
  late final StreamSubscription<List<ApiConnection>> _subscription;
  bool _active = true;

  @override
  Future<List<ApiConnection>> build() async {
    final repository = ref.watch(connectionRepositoryProvider);
    _subscription = repository.watchAll().listen((items) {
      if (!_active) return;
      state = AsyncData(items);
    });
    ref.onDispose(() {
      _active = false;
      _subscription.cancel();
    });
    return repository.loadAll();
  }

  Future<void> add(ApiConnection connection) =>
      ref.read(connectionRepositoryProvider).save(connection);

  Future<void> save(ApiConnection connection) =>
      ref.read(connectionRepositoryProvider).save(connection);

  Future<void> delete(String id) =>
      ref.read(connectionRepositoryProvider).delete(id);

  Future<void> setEnabled(String id, bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final index = current.indexWhere((c) => c.id == id);
    if (index == -1) return;
    final updated = current[index].copyWith(enabled: enabled);
    await save(updated);
  }
}
