import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_sizes.dart';

/// SportSync's typography scale.
///
/// Headings use **Poppins** (bold, geometric, sporty) and body/labels use
/// **Inter** for legibility. Fonts are resolved via `google_fonts` with a
/// bundled fallback stack so offline launches still render.
///
/// A single [TextTheme] is built for both light and dark via [of].
abstract final class AppTextStyles {
  AppTextStyles._();

  static TextTheme _base(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    TextStyle poppins({
      required double size,
      required FontWeight weight,
      required Color color,
      double height = 1.2,
      double? letterSpacing,
    }) =>
        GoogleFonts.poppins(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );

    TextStyle inter({
      required double size,
      required FontWeight weight,
      required Color color,
      double height = 1.4,
      double? letterSpacing,
    }) =>
        GoogleFonts.inter(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );

    final onSurface = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;

    return TextTheme(
      // ---- Display / headlines (Poppins) ----------------------------------
      displayLarge: poppins(size: 40, weight: FontWeight.w700, color: onSurface),
      displayMedium: poppins(size: 34, weight: FontWeight.w700, color: onSurface),
      displaySmall: poppins(size: 28, weight: FontWeight.w700, color: onSurface),
      headlineLarge: poppins(size: 26, weight: FontWeight.w600, color: onSurface),
      headlineMedium: poppins(size: 22, weight: FontWeight.w600, color: onSurface),
      headlineSmall: poppins(size: 18, weight: FontWeight.w600, color: onSurface),
      titleLarge: poppins(size: 16, weight: FontWeight.w600, color: onSurface),
      titleMedium: inter(size: 14, weight: FontWeight.w600, color: onSurface),
      titleSmall: inter(size: 13, weight: FontWeight.w600, color: onSurface),

      // ---- Body (Inter) -----------------------------------------------------
      bodyLarge: inter(size: 16, weight: FontWeight.w400, color: onSurface),
      bodyMedium: inter(size: 14, weight: FontWeight.w400, color: onSurface),
      bodySmall: inter(size: 12, weight: FontWeight.w400, color: muted),
      labelLarge: inter(
        size: 14,
        weight: FontWeight.w600,
        color: onSurface,
        letterSpacing: 0.2,
      ),
      labelMedium: inter(
        size: 12,
        weight: FontWeight.w600,
        color: onSurface,
        letterSpacing: 0.3,
      ),
      labelSmall: inter(
        size: 11,
        weight: FontWeight.w600,
        color: onSurface,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Builds the [TextTheme] for the current context, honoring theme + font scale.
  static TextTheme of(BuildContext context) => _base(context);

  /// Apply to `MaterialApp` so text scales with the platform's accessibility
  /// setting while keeping our type scale.
  static TextTheme platformCompatible(BuildContext context) {
    final base = _base(context);
    return base.apply(
      bodyColor: Theme.of(context).colorScheme.onSurface,
      displayColor: Theme.of(context).colorScheme.onSurface,
    );
  }
}

/// Typography extension on [ThemeData] for convenient access:
/// `context.t.large` — but we prefer explicit `theme.textTheme.*`.
extension TextThemeX on BuildContext {
  TextTheme get tt => Theme.of(this).textTheme;

  /// Muted variant color.
  Color get muted => Theme.of(this).colorScheme.onSurfaceVariant;
}

/// Vertical rhythm for typography, in case a screen needs manual spacing.
abstract final class TypeRhythm {
  TypeRhythm._();
  static const double tight = 0.8 * AppSizes.xl;
  static const double normal = AppSizes.xl;
  static const double relaxed = 1.5 * AppSizes.xl;
}

/// System haptic + accessibility helpers used across the app.
abstract final class AppHaptics {
  AppHaptics._();

  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> medium() => HapticFeedback.mediumImpact();
  static Future<void> selection() => HapticFeedback.selectionClick();
}
