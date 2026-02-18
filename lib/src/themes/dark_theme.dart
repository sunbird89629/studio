import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/material.dart';
import 'package:terminal_studio/src/core/theme/theme_plugin.dart';

/// Built-in dark theme.
class DarkTheme extends ThemePlugin {
  @override
  String get id => 'dark';

  @override
  String get displayName => 'Dark';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      );

  @override
  TabsViewThemeData get tabsTheme => const TabsViewThemeData(
        backgroundColor: Color(0xFF252526),
        hoverBackgroundColor: Color(0xFF2D2D2D),
        selectedBackgroundColor: Color(0xFF1E1E1E),
        labelColor: Color(0xFFE0E0E0),
        closeButtonColor: Color(0xFFA0A0A0),
      );
}
