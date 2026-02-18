import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/material.dart';
import 'package:terminal_studio/src/core/theme/theme_plugin.dart';

/// GitHub Dark theme.
class GitHubDarkTheme extends ThemePlugin {
  @override
  String get id => 'github-dark';

  @override
  String get displayName => 'GitHub Dark';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF58A6FF),
      brightness: Brightness.dark,
      surface: const Color(0xFF0D1117),
      primary: const Color(0xFF58A6FF),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      dividerColor: const Color(0xFF30363D),
    );
  }

  @override
  TabsViewThemeData get tabsTheme => const TabsViewThemeData(
        backgroundColor: Color(0xFF161B22),
        hoverBackgroundColor: Color(0xFF21262D),
        selectedBackgroundColor: Color(0xFF0D1117),
        labelColor: Color(0xFFC9D1D9),
        closeButtonColor: Color(0xFF8B949E),
      );
}

/// GitHub Light theme.
class GitHubLightTheme extends ThemePlugin {
  @override
  String get id => 'github-light';

  @override
  String get displayName => 'GitHub Light';

  @override
  Brightness get brightness => Brightness.light;

  @override
  ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0969DA),
      brightness: Brightness.light,
      surface: const Color(0xFFFFFFFF),
      primary: const Color(0xFF0969DA),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      dividerColor: const Color(0xFFD0D7DE),
    );
  }

  @override
  TabsViewThemeData get tabsTheme => const TabsViewThemeData(
        backgroundColor: Color(0xFFF6F8FA),
        hoverBackgroundColor: Color(0xFFEAEEF2),
        selectedBackgroundColor: Color(0xFFFFFFFF),
        labelColor: Color(0xFF24292F),
        closeButtonColor: Color(0xFF57606A),
      );
}
