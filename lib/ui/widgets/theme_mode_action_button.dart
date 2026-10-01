import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';

/// A compact, accessible theme control shared by the app's top-level pages.
class ThemeModeActionButton extends StatelessWidget {
  const ThemeModeActionButton({super.key, this.color});

  /// Optional foreground override for app bars drawn over a fixed-colour scene.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      key: const ValueKey('theme-mode-toggle'),
      tooltip:
          isDark ? 'التبديل إلى الوضع النهاري' : 'التبديل إلى الوضع الليلي',
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: color,
      ),
      onPressed: () => context.read<SettingsProvider>().toggleTheme(),
    );
  }
}
