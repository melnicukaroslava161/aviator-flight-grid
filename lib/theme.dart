import 'package:flutter/material.dart';

/// Canonical visual preset for this build (see design-system/presets-index.md).
class AppPreset {
  const AppPreset({required this.name});

  final String name;
}

const AppPreset appPreset = AppPreset(name: 'SPACE_COSMOS');

/// Night-navigation palette: deep cockpit blue base, sky-blue primary accent,
/// indigo secondary, storm red and marker gold as the two contrast flashes.
class AppColors {
  const AppColors._();

  static const Color bgDeep = Color(0xFF060D18);
  static const Color bgMid = Color(0xFF0E1A2C);
  static const Color bgBase = Color(0xFF14233A);
  static const Color surface = Color(0xFF1B2E4A);
  static const Color surfaceAlt = Color(0xFF24395C);

  static const Color accentSky = Color(0xFF39A9E8);
  static const Color accentIndigo = Color(0xFF6D7EE8);
  static const Color danger = Color(0xFFF25B4B);
  static const Color gold = Color(0xFFF4C64A);

  static const Color textPrimary = Color(0xFFF5F8FF);
  static const Color textSecondary = Color(0xFFA9BCD6);
  static const Color textMuted = Color(0xFF6D82A3);

  /// Ink colour used on top of the bright sky/indigo CTA gradient.
  static const Color onAccent = Color(0xFF0A1424);

  /// Gate colours, indexed by [gateColorIndex].
  static const List<Color> gateColors = <Color>[accentSky, accentIndigo, gold];
  static const List<String> gateColorNames = <String>['SKY', 'INDIGO', 'GOLD'];
}

/// Shared number style for stat cards / HUD counters.
const TextStyle kStatValueStyle = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w900,
  height: 1.1,
  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
);

ThemeData buildAppTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accentSky,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.accentSky,
    secondary: AppColors.accentIndigo,
    error: AppColors.danger,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bgBase,
    canvasColor: AppColors.bgBase,
    splashFactory: InkRipple.splashFactory,
    textTheme: const TextTheme(
      // Brand lockup on the loader.
      displayLarge: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w900,
        letterSpacing: 6,
        height: 1.05,
        color: AppColors.textPrimary,
      ),
      // Screen headlines.
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        height: 1.15,
        color: AppColors.textPrimary,
      ),
      // Call-to-action label.
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        height: 24 / 17,
        color: AppColors.textPrimary,
      ),
      // Body copy.
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.textSecondary,
      ),
      // Caps micro-labels.
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        height: 1.3,
        color: AppColors.textMuted,
      ),
    ),
  );
}
