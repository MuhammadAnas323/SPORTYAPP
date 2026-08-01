import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_sizes.dart';
import 'app_colors.dart';

/// Builds SportSync's Material 3 light and dark [ThemeData].
///
/// Both themes share the same brand palette, component shapes and elevation
/// language so a runtime theme toggle only flips surface brightness — never
/// the identity.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: isDark ? AppColors.turfGreen : AppColors.pitchGreen,
      brightness: brightness,
      primary: isDark ? AppColors.mintGreen : AppColors.pitchGreen,
      secondary: AppColors.willowBrown,
      error: AppColors.error,
      surface: isDark ? AppColors.charcoal900 : AppColors.ballWhite,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.charcoal950 : AppColors.cloud,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    // ---- Shared component styling -------------------------------------------
    final roundedCard = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        backgroundColor: isDark ? AppColors.charcoal950 : AppColors.cloud,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: AppSizes.elevationSoft,
        color: isDark ? AppColors.charcoal850 : AppColors.ballWhite,
        surfaceTintColor: Colors.transparent,
        shape: roundedCard,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: StadiumBorder(
          side: BorderSide(color: scheme.outlineVariant),
        ),
        backgroundColor: isDark ? AppColors.charcoal800 : AppColors.mist,
        selectedColor: scheme.primary,
        labelStyle: base.textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm - 2,
        ),
        side: BorderSide.none,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.xl,
            vertical: AppSizes.lg,
          ),
          textStyle: base.textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          side: BorderSide(color: scheme.outline),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.xl,
            vertical: AppSizes.lg,
          ),
          textStyle: base.textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.charcoal850 : AppColors.ballWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: scheme.error),
        ),
        hintStyle: base.textTheme.bodyMedium?.copyWith(color: scheme.outline),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.charcoal900 : AppColors.ballWhite,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        elevation: AppSizes.elevationRaised,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.charcoal700 : AppColors.stone,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorColor: scheme.primary,
        dividerColor: Colors.transparent,
        labelStyle: base.textTheme.labelLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.charcoal900 : AppColors.ballWhite,
        indicatorColor: scheme.primaryContainer,
        elevation: AppSizes.elevationRaised,
      ),
    );
  }
}
