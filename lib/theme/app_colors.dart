import 'package:flutter/material.dart';

/// SportSync's dual-sport colour identity.
///
/// Palette philosophy:
/// * **Cricket** — pitch green + willow brown.
/// * **Football** — turf green, classic black/white ball accents, and
///   floodlight gold for highlights.
/// * **Neutrals** — charcoal family for dark-mode surfaces.
///
/// Seed swatches are blended into a Material 3 [ColorScheme] in `AppTheme`;
/// [AppColors] holds the raw brand swatches referenced directly by widgets
/// (hero gradients, badges, charts).
abstract final class AppColors {
  AppColors._();

  // ---- Brand greens ---------------------------------------------------------
  /// Pitch green — the primary identity (cricket).
  static const Color pitchGreen = Color(0xFF1B9A63);

  /// Turf green — football identity, slightly deeper than pitch green.
  static const Color turfGreen = Color(0xFF0E7A45);

  /// Gradient partner for hero elements (lighter end).
  static const Color mintGreen = Color(0xFF37C787);

  /// Deep end of hero gradients.
  static const Color deepGreen = Color(0xFF0B4D30);

  // ---- Willow brown (cricket accents) ---------------------------------------
  static const Color willowBrown = Color(0xFF8A5A33);
  static const Color willowLight = Color(0xFFC99A66);

  // ---- Floodlight gold (highlights / live emphasis) -------------------------
  static const Color floodlightGold = Color(0xFFFFC24D);
  static const Color floodlightAmber = Color(0xFFFF9E3D);

  // ---- Classic ball / ink ---------------------------------------------------
  static const Color ink = Color(0xFF10161B);
  static const Color ballWhite = Color(0xFFF5F7F6);

  // ---- Status ---------------------------------------------------------------
  static const Color liveRed = Color(0xFFE53950);
  static const Color success = Color(0xFF22A06B);
  static const Color warning = Color(0xFFE9A23B);
  static const Color error = Color(0xFFD64545);
  static const Color info = Color(0xFF3D8BFF);

  // ---- Charcoal neutrals (dark mode surfaces) --------------------------------
  static const Color charcoal950 = Color(0xFF0C1216);
  static const Color charcoal900 = Color(0xFF111A1F);
  static const Color charcoal850 = Color(0xFF162127);
  static const Color charcoal800 = Color(0xFF1C2930);
  static const Color charcoal700 = Color(0xFF2A3A43);
  static const Color charcoal600 = Color(0xFF3C4E58);

  // ---- Light-mode neutrals ---------------------------------------------------
  static const Color cloud = Color(0xFFF4F6F5);
  static const Color mist = Color(0xFFEAEEEB);
  static const Color stone = Color(0xFFDFE5E1);
  static const Color slate = Color(0xFF6B7B84);
  static const Color slateDark = Color(0xFF41505A);

  // ---- Gradient helpers -------------------------------------------------------
  /// Hero gradient used on the featured live card and splash.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pitchGreen, deepGreen],
  );

  /// Warmer hero variant used for football-leaning highlights.
  static const LinearGradient footballGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [turfGreen, Color(0xFF0B3D2A)],
  );

  /// Gold accent used behind the pulsing live badge.
  static const LinearGradient liveGradient = LinearGradient(
    colors: [floodlightAmber, liveRed],
  );
}
