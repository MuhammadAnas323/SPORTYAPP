import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/channel.dart';

/// Mirrors the aggregated live feed into Firebase Realtime Database at
/// `live/{uid}/{connectionId}/{providerId}`.
///
/// Saved data (connections, profile) lives in Firestore; the live match
/// stream is pushed here so any screen can observe realtime updates. Writes
/// are guarded by `database.rules.json` to the signed-in owner only.
class LiveSyncService {
  LiveSyncService(this._database, this._auth);

  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  /// Writes the current live-only slice of [feed] under the signed-in user.
  ///
  /// Idempotent — re-running with the same data overwrites in place, and
  /// matches that drop off the live slice simply stop being updated here.
  Future<void> mirror(AggregatedFeed feed) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updates = <String, Object?>{};
    for (final match in feed.liveOnly) {
      updates['live/${user.uid}/${match.connectionId}/${match.providerId}'] = {
        'sportType': match.sportType.key,
        'title': match.title,
        'seriesName': match.seriesName,
        'home': match.home.name,
        'away': match.away.name,
        'homeScore': match.homeScore?.line,
        'awayScore': match.awayScore?.line,
        'status': match.status.name,
        'statusText': match.statusText,
        'videoUrl': match.videoUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }
    if (updates.isEmpty) return;

    try {
      await _database.ref().update(updates);
    } catch (_) {
      // Live mirroring is best-effort; a failure here must never break the
      // normal feed rendering.
    }
  }
}
