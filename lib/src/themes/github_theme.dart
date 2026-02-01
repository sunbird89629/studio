import 'package:flex_tabs/flex_tabs.dart';
import 'package:fluent_ui/fluent_ui.dart';
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
  FluentThemeData get fluentTheme => FluentThemeData(
        brightness: Brightness.dark,
        accentColor: AccentColor.swatch(const {
          'normal': Color(0xFF58A6FF),
        }),
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        micaBackgroundColor: const Color(0xFF161B22),
      );

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
  FluentThemeData get fluentTheme => FluentThemeData(
        brightness: Brightness.light,
        accentColor: AccentColor.swatch(const {
          'normal': Color(0xFF0969DA),
        }),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        micaBackgroundColor: const Color(0xFFF6F8FA),
      );

  @override
  TabsViewThemeData get tabsTheme => const TabsViewThemeData(
        backgroundColor: Color(0xFFF6F8FA),
        hoverBackgroundColor: Color(0xFFEAEEF2),
        selectedBackgroundColor: Color(0xFFFFFFFF),
        labelColor: Color(0xFF24292F),
        closeButtonColor: Color(0xFF57606A),
      );
}
