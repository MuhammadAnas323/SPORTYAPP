import 'package:flutter/widgets.dart';

/// Responsive breakpoints for SportSync.
///
/// The design system is fluid: phone (1 column) → large phone / foldable
/// (2 columns) → tablet (3–4 columns). Breakpoints are constants so every
/// screen in the app reflows consistently.
enum Breakpoint {
  /// < 600dp — typical phones.
  phone,

  /// 600–840dp — large phones, foldables (unfolded), small tablets.
  largePhone,

  /// >= 840dp — tablets and desktop web.
  tablet,
}

extension BreakpointX on BuildContext {
  /// The current [Breakpoint] derived from the available width.
  Breakpoint get breakpoint {
    final width = MediaQuery.sizeOf(this).width;
    if (width < 600) return Breakpoint.phone;
    if (width < 840) return Breakpoint.largePhone;
    return Breakpoint.tablet;
  }

  /// True when the layout should use multiple columns.
  bool get isTabletOrWider => breakpoint == Breakpoint.tablet;

  /// True when the layout is a single-column phone.
  bool get isPhone => breakpoint == Breakpoint.phone;

  /// Suggested number of columns for a fluid grid at this breakpoint.
  int get gridColumns => switch (breakpoint) {
        Breakpoint.phone => 1,
        Breakpoint.largePhone => 2,
        Breakpoint.tablet => 3,
      };

  /// Horizontal padding applied at the page level.
  double get pagePadding => breakpoint == Breakpoint.phone ? 16 : 24;

  /// Height of a compact card at this breakpoint (tablets get roomier cards).
  double get cardHeight => switch (breakpoint) {
        Breakpoint.phone => 148,
        Breakpoint.largePhone => 160,
        Breakpoint.tablet => 172,
      };
}
