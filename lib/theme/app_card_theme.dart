import 'package:flutter/material.dart';

class AppCardTheme {
  static const double borderRadius = 15.0;
  static const double elevation = 0.0;
  static const EdgeInsetsGeometry margins = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 8.0,
  );
  static const EdgeInsetsGeometry padding = EdgeInsets.all(16.0);
  static const String fontFamily = 'amiri';

  static RoundedRectangleBorder get shape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius));
}

extension ColorContrast on Color {
  /// Returns the higher-contrast neutral foreground for this surface.
  ///
  /// Comparing both WCAG contrast ratios gives more reliable results than a
  /// fixed luminance cut-off, especially for saturated colours such as the
  /// app's forest-green card surface.
  Color get contrastTextColor {
    final luminance = computeLuminance();
    final contrastWithBlack = (luminance + 0.05) / 0.05;
    final contrastWithWhite = 1.05 / (luminance + 0.05);
    return contrastWithBlack >= contrastWithWhite ? Colors.black : Colors.white;
  }
}
