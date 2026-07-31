import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/material.dart';
import 'package:open_term/src/shared/theme/theme_plugin.dart';

/// Built-in light theme.
class LightTheme extends ThemePlugin {
  @override
  String get id => 'light';

  @override
  String get displayName => 'Light';

  @override
  Brightness get brightness => Brightness.light;

  @override
  ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
          surface: const Color(0xFFF3F3F3),
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F3F3),
      );

  @override
  TabsViewThemeData get tabsTheme => const TabsViewThemeData(
        backgroundColor: Color(0xFFF3F3F3),
        hoverBackgroundColor: Color(0xFFE8E8E8),
        selectedBackgroundColor: Color(0xFFFFFFFF),
        labelColor: Color(0xFF1A1A1A),
        closeButtonColor: Color(0xFF606060),
      );
}
