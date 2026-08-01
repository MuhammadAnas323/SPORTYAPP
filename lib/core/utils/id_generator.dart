import 'package:uuid/uuid.dart';

/// Thin wrapper around `uuid` so entity ids are created from one place and can
/// be swapped for a server-friendly generator later without touching callers.
abstract final class IdGenerator {
  IdGenerator._();

  static const Uuid _uuid = Uuid();

  /// Returns a fresh v4 id for connections / channels.
  static String newId() => _uuid.v4();

  /// Stable id derived from a match + source so detail routes are unique.
  static String matchId({required String connectionId, required String providerId}) =>
      '$connectionId::$providerId';
}
