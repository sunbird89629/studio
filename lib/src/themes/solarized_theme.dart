import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/material.dart';
import 'package:terminal_studio/src/core/theme/theme_plugin.dart';

/// Solarized Dark theme - precision colors for machines and people.
class SolarizedDarkTheme extends ThemePlugin {
  @override
  String get id => 'solarized-dark';

  @override
  String get displayName => 'Solarized Dark';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF268BD2),
      brightness: Brightness.dark,
      surface: const Color(0xFF002B36),
      primary: const Color(0xFF268BD2),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF002B36),
      dividerColor: const Color(0xFF073642),
    );
  }

  @override
  TabsViewThemeData get tabsTheme => const TabsViewThemeData(
        backgroundColor: Color(0xFF073642),
        hoverBackgroundColor: Color(0xFF094959),
        selectedBackgroundColor: Color(0xFF002B36),
        labelColor: Color(0xFF839496),
        closeButtonColor: Color(0xFF586E75),
      );
}

/// Solarized Light theme.
class SolarizedLightTheme extends ThemePlugin {
  @override
  String get id => 'solarized-light';

  @override
  String get displayName => 'Solarized Light';

  @override
  Brightness get brightness => Brightness.light;

  @override
  ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF268BD2),
      brightness: Brightness.light,
      surface: const Color(0xFFFDF6E3),
      primary: const Color(0xFF268BD2),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFDF6E3),
      dividerColor: const Color(0xFFEEE8D5),
    );
  }

  @override
  TabsViewThemeData get tabsTheme => const TabsViewThemeData(
        backgroundColor: Color(0xFFEEE8D5),
        hoverBackgroundColor: Color(0xFFE4DFD0),
        selectedBackgroundColor: Color(0xFFFDF6E3),
        labelColor: Color(0xFF657B83),
        closeButtonColor: Color(0xFF93A1A1),
      );
}
