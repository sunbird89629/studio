import 'package:flex_tabs/flex_tabs.dart';
import 'package:fluent_ui/fluent_ui.dart';
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
  FluentThemeData get fluentTheme => FluentThemeData(
        brightness: Brightness.dark,
        accentColor: AccentColor.swatch(const {
          'normal': Color(0xFF268BD2),
        }),
        scaffoldBackgroundColor: const Color(0xFF002B36),
        micaBackgroundColor: const Color(0xFF073642),
      );

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
  FluentThemeData get fluentTheme => FluentThemeData(
        brightness: Brightness.light,
        accentColor: AccentColor.swatch(const {
          'normal': Color(0xFF268BD2),
        }),
        scaffoldBackgroundColor: const Color(0xFFFDF6E3),
        micaBackgroundColor: const Color(0xFFEEE8D5),
      );

  @override
  TabsViewThemeData get tabsTheme => const TabsViewThemeData(
        backgroundColor: Color(0xFFEEE8D5),
        hoverBackgroundColor: Color(0xFFE4DFD0),
        selectedBackgroundColor: Color(0xFFFDF6E3),
        labelColor: Color(0xFF657B83),
        closeButtonColor: Color(0xFF93A1A1),
      );
}
