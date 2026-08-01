/// Central, reusable design tokens.
///
/// SportSync uses a strict 8pt spacing scale so every screen, card and list
/// stays visually consistent across phone, foldable and tablet layouts.
abstract final class AppSizes {
  AppSizes._();

  // ---- Spacing (8pt scale) -------------------------------------------------
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // ---- Radii ----------------------------------------------------------------
  /// Smallest radius for compact filter chips.
  static const double radiusXs = 5;

  /// Small rounded chip/pill radius.
  static const double radiusSm = 8;

  /// Standard control radius (buttons, text fields).
  static const double radiusMd = 12;

  /// Card radius — 16..20px per the design system.
  static const double radiusCard = 16;
  static const double radiusCardLg = 20;

  /// Fully rounded pills / avatars / status dots.
  static const double radiusPill = 999;

  // ---- Elevation ------------------------------------------------------------
  static const double elevationNone = 0;
  static const double elevationSoft = 1;
  static const double elevationRaised = 3;

  // ---- Components -----------------------------------------------------------
  static const double navBarHeight = 68;
  static const double appBarHeight = 64;
  static const double sectionGap = 28;
  static const double pagePadding = 20;

  /// Maximum content width before a screen becomes a centered, gutted grid
  /// on very wide tablets / desktop web.
  static const double maxContentWidth = 1200;
}
