import 'package:flutter/material.dart';

/// Shared visual tokens for the application chrome and the home dashboard.
abstract final class AppPalette {
  static const forest = Color(0xFF123C32);
  static const forestLight = Color(0xFF245447);
  static const gold = Color(0xFFE1C47F);
  static const ivory = Color(0xFFF7F5EF);
  static const night = Color(0xFF111916);
}

abstract final class AppTheme {
  static ThemeData build({
    required Brightness brightness,
    required Color primary,
    required Color card,
  }) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    );
    final background = dark ? AppPalette.night : AppPalette.ivory;
    // Preserve the familiar dark surface when a user explicitly chooses white,
    // while keeping every other selected card colour exact in both themes.
    final effectiveCardColor =
        dark && card == Colors.white ? const Color(0xFF1D2B25) : card;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: background,
      cardColor: effectiveCardColor,
      // Material 3 Cards use surfaceContainerLow by default. Setting the theme
      // colour here ensures cards without a local override follow the user's
      // saved card-background choice too.
      cardTheme: CardThemeData(
        color: effectiveCardColor,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            dark ? const Color(0xFF18221D) : const Color(0xFFFFFEFB),
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontFamily: 'Cairo',
              color: scheme.onSurface,
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            )),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}
