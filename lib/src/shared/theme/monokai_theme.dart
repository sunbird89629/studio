import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/material.dart';
import 'package:terminal_studio/src/shared/theme/theme_plugin.dart';

/// Monokai Pro theme - popular dark theme with vibrant colors.
class MonokaiTheme extends ThemePlugin {
  @override
  String get id => 'monokai';

  @override
  String get displayName => 'Monokai Pro';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFA9DC76),
      brightness: Brightness.dark,
      surface: const Color(0xFF2D2A2E),
      primary: const Color(0xFFA9DC76),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF2D2A2E),
      dividerColor: const Color(0xFF403E41),
    );
  }

  @override
  TabsViewThemeData get tabsTheme => const TabsViewThemeData(
        backgroundColor: Color(0xFF221F22),
        hoverBackgroundColor: Color(0xFF363337),
        selectedBackgroundColor: Color(0xFF2D2A2E),
        labelColor: Color(0xFFFCFCFA),
        closeButtonColor: Color(0xFF939293),
      );
}
