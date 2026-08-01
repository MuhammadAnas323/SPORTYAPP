/// Defensive JSON access helpers.
///
/// Third-party sport APIs are inconsistent: a field may be nested, missing,
/// or typed differently between providers. Every adapter reads through these
/// guards so a surprising shape produces `null` (and an honest UI state)
/// instead of a cast crash.
abstract final class JsonGuard {
  JsonGuard._();

  /// Reads the first key (in order) that exists on [map].
  static dynamic pick(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key)) return map[key];
    }
    return null;
  }

  static String? asString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final v = value.trim();
      return v.isEmpty ? null : v;
    }
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    return null;
  }

  static int? asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double? asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static bool asBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes') return true;
      if (v == 'false' || v == '0' || v == 'no') return false;
    }
    return fallback;
  }

  /// Best-effort map extraction; non-maps become `null`.
  static Map<String, dynamic>? asMap(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  /// Best-effort list extraction; non-lists become an empty list.
  static List<dynamic> asList(dynamic value) {
    if (value is List) return value;
    if (value is Map) return value.values.toList();
    return const [];
  }

  /// Picks a nested value by a dotted path, e.g. `data.match.teams`.
  /// Unlike a typed getter this returns the raw value, so it also works when
  /// the final node is a list.
  static dynamic pickValuePath(
    Map<String, dynamic> map,
    String path,
  ) {
    final parts = path.split('.');
    dynamic cursor = map;
    for (final part in parts) {
      final m = asMap(cursor);
      if (m == null || !m.containsKey(part)) return null;
      cursor = m[part];
    }
    return cursor;
  }
}
