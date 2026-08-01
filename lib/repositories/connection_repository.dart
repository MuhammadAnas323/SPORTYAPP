import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/errors/app_exception.dart';
import '../models/api_connection.dart';

/// Persists [ApiConnection] records in Cloud Firestore, scoped to the
/// signed-in user: `users/{uid}/connections/{id}`.
///
/// The Firestore security rules lock every user to their own subtree, and a
/// live snapshot stream keeps Home/Live/Profile in sync across devices.
class ConnectionRepository {
  ConnectionRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const String _prefix = 'conn.';

  /// Emits the full connection list for the signed-in user after every
  /// change (local edit, another device, sign-out → empty list).
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
      firestoreSub = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('connections')
          .snapshots()
          .listen(
        (snapshot) {
          controller.add(
            snapshot.docs
                .map((doc) => ApiConnection.fromJson(doc.data()))
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
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('connections')
          .get();
      return snapshot.docs
          .map((doc) => ApiConnection.fromJson(doc.data()))
          .toList();
    } catch (error) {
      throw StorageException('Could not read saved connections.', cause: error);
    }
  }

  /// Upserts a connection for the signed-in user.
  Future<void> save(ApiConnection connection) async {
    try {
      await _requireUid().collection('connections').doc(connection.id).set(
            connection.toJson(),
          );
    } catch (error) {
      throw StorageException('Could not save this connection.', cause: error);
    }
  }

  /// Removes a connection for the signed-in user.
  Future<void> delete(String id) async {
    try {
      await _requireUid().collection('connections').doc(id).delete();
    } catch (error) {
      throw StorageException('Could not delete this connection.', cause: error);
    }
  }

  DocumentReference<Map<String, dynamic>> _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AuthException('Sign in before managing connections.');
    }
    return _firestore.collection('users').doc(uid);
  }

  // Kept for API stability with older callers; Firestore handles ordering
  // itself so this is a no-op.
  static String storageKey(String id) => '$_prefix$id';
}
