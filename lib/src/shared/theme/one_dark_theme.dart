import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/material.dart';
import 'package:open_term/src/shared/theme/theme_plugin.dart';

/// One Dark theme - Atom editor's iconic dark theme.
class OneDarkTheme extends ThemePlugin {
  @override
  String get id => 'one-dark';

  @override
  String get displayName => 'One Dark';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF61AFEF),
      brightness: Brightness.dark,
      surface: const Color(0xFF282C34),
      primary: const Color(0xFF61AFEF),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF282C34),
      dividerColor: const Color(0xFF3E4451),
    );
  }

  @override
  TabsViewThemeData get tabsTheme => const TabsViewThemeData(
        backgroundColor: Color(0xFF21252B),
        hoverBackgroundColor: Color(0xFF2C313A),
        selectedBackgroundColor: Color(0xFF282C34),
        labelColor: Color(0xFFABB2BF),
        closeButtonColor: Color(0xFF5C6370),
      );
}
