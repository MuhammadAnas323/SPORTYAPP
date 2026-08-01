import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/errors/app_exception.dart';
import '../models/api_connection.dart';
import '../models/connection_status.dart';

/// Persists [ApiConnection] records in a **project-wide** Cloud Firestore
/// collection (`connections/{id}`), shared by every device that runs the app.
///
/// Because the app signs every install in as its own anonymous account, the
/// data can't live under `users/{uid}` or each device would only ever see its
/// own channels. A shared collection means a channel added on one device
/// appears instantly on every other device (the live snapshot stream keeps
/// Home/Live/Profile in sync).
class ConnectionRepository {
  ConnectionRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ApiConnection _sanitizeRemoteConnection(ApiConnection connection) {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return connection;
    if (connection.createdByUid == null || connection.createdByUid == currentUid) {
      return connection;
    }
    return connection.copyWith(
      apiKey: '',
      status: ConnectionStatus.notTested,
      lastTestedAt: null,
      lastError: null,
    );
  }

  /// Emits the full shared connection list after every change (local edit,
  /// another device, etc.).
  Stream<List<ApiConnection>> watchAll() {
    final controller = StreamController<List<ApiConnection>>.broadcast();
    StreamSubscription<User?>? authSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? firestoreSub;

    void attach(User? user) {
      firestoreSub?.cancel();
      firestoreSub = null;
      if (user == null) {
        controller.add(const []);
        return;
      }
      firestoreSub = _firestore.collection('connections').snapshots().listen(
        (snapshot) {
          controller.add(
            snapshot.docs
                .map((doc) => _sanitizeRemoteConnection(
                      ApiConnection.fromJson(doc.data()),
                    ))
                .toList(),
          );
        },
        onError: (Object error) {
          if (!controller.isClosed) controller.addError(error);
        },
      );
    }

    authSub = _auth.authStateChanges().listen(
          attach,
          onError: (Object error) {
            if (!controller.isClosed) controller.addError(error);
          },
        );
    controller.onCancel = () async {
      await authSub?.cancel();
      await firestoreSub?.cancel();
    };
    return controller.stream;
  }

  /// One-shot read for the notifier's initial build.
  Future<List<ApiConnection>> loadAll() async {
    if (_auth.currentUser == null) return const [];
    try {
      final snapshot = await _firestore.collection('connections').get();
      return snapshot.docs
          .map((doc) => _sanitizeRemoteConnection(
                ApiConnection.fromJson(doc.data()),
              ))
          .toList();
    } catch (error) {
      throw StorageException('Could not read saved connections.', cause: error);
    }
  }

  /// Upserts a connection into the shared collection.
  Future<void> save(ApiConnection connection) async {
    try {
      final currentUid = _auth.currentUser?.uid;
      final toSave = (currentUid != null && connection.createdByUid == null)
          ? connection.copyWith(createdByUid: currentUid)
          : connection;
      await _firestore
          .collection('connections')
          .doc(toSave.id)
          .set(toSave.toJson());
    } catch (error) {
      throw StorageException('Could not save this connection.', cause: error);
    }
  }

  /// Removes a connection from the shared collection.
  Future<void> delete(String id) async {
    try {
      await _firestore.collection('connections').doc(id).delete();
    } catch (error) {
      throw StorageException('Could not delete this connection.', cause: error);
    }
  }
}
