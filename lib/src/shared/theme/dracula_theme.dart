import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/material.dart';
import 'package:terminal_studio/src/shared/theme/theme_plugin.dart';

/// Dracula theme - popular dark theme with purple accent.
class DraculaTheme extends ThemePlugin {
  @override
  String get id => 'dracula';

  @override
  String get displayName => 'Dracula';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFBD93F9),
      brightness: Brightness.dark,
      surface: const Color(0xFF282A36),
      onSurface: const Color(0xFFF8F8F2),
      primary: const Color(0xFFBD93F9),
      onPrimary: const Color(0xFF282A36),
      secondary: const Color(0xFF6272A4),
      onSecondary: const Color(0xFFF8F8F2),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF282A36),
      dividerColor: const Color(0xFF44475A),
    );
  }

  @override
  TabsViewThemeData get tabsTheme => const TabsViewThemeData(
        backgroundColor: Color(0xFF21222C),
        hoverBackgroundColor: Color(0xFF343746),
        selectedBackgroundColor: Color(0xFF282A36),
        labelColor: Color(0xFFF8F8F2),
        closeButtonColor: Color(0xFF6272A4),
      );
}
