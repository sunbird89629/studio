import 'package:flex_tabs/flex_tabs.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:terminal_studio/src/core/theme/theme_plugin.dart';

/// Built-in light theme.
class LightTheme extends ThemePlugin {
  @override
  String get id => 'light';

  @override
  String get displayName => 'Light';

  @override
  Brightness get brightness => Brightness.light;

  @override
  FluentThemeData get fluentTheme => FluentThemeData(
        brightness: Brightness.light,
        accentColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF3F3F3),
        micaBackgroundColor: const Color(0xFFFFFFFF),
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
