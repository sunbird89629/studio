import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/material.dart';
import 'package:open_term/src/shared/theme/theme_plugin.dart';

/// Nord theme - Arctic, north-bluish color palette.
class NordTheme extends ThemePlugin {
  @override
  String get id => 'nord';

  @override
  String get displayName => 'Nord';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF88C0D0),
      brightness: Brightness.dark,
      surface: const Color(0xFF2E3440),
      primary: const Color(0xFF88C0D0),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF2E3440),
      dividerColor: const Color(0xFF3B4252),
    );
  }

  @override
  TabsViewThemeData get tabsTheme => const TabsViewThemeData(
        backgroundColor: Color(0xFF3B4252),
        hoverBackgroundColor: Color(0xFF434C5E),
        selectedBackgroundColor: Color(0xFF2E3440),
        labelColor: Color(0xFFECEFF4),
        closeButtonColor: Color(0xFF4C566A),
      );
}
