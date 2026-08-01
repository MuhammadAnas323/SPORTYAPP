import 'package:flutter/material.dart';

/// Convenience context extensions used across every screen.
extension ContextX on BuildContext {
  /// Pushes a route without animation friction.
  Future<T?> push<T>(Widget page) => Navigator.of(this).push(
        MaterialPageRoute<T>(builder: (_) => page),
      );

  /// Whether the current theme is dark.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Scaffold-level background honoring the theme.
  Color get background => Theme.of(this).scaffoldBackgroundColor;

  /// Primary color shortcut.
  Color get primary => Theme.of(this).colorScheme.primary;

  /// Safe horizontal inset (notch / home indicator aware).
  EdgeInsets get safePadding => MediaQuery.paddingOf(this);
}
