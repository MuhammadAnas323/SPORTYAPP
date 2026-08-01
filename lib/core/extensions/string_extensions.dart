/// String helpers for normalising user-entered data (URLs, headers).
extension StringX on String {
  /// Trims surrounding whitespace and any trailing slash so hosts are stored
  /// consistently. Returns an empty string for blank input.
  String normalizedUrl() {
    final trimmed = trim();
    if (trimmed.isEmpty) return '';
    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }

  /// Parses `Header: Value` lines (one per line) into a map. Invalid lines are
  /// silently skipped so a typo never crashes the app.
  Map<String, String> parseHeaderLines() {
    final result = <String, String>{};
    for (final line in split('\n')) {
      final colon = line.indexOf(':');
      if (colon <= 0) continue;
      final key = line.substring(0, colon).trim();
      final value = line.substring(colon + 1).trim();
      if (key.isEmpty || value.isEmpty) continue;
      result[key] = value;
    }
    return result;
  }
}
