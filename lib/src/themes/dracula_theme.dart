import 'package:flex_tabs/flex_tabs.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:terminal_studio/src/core/theme/theme_plugin.dart';

/// Dracula theme - popular dark theme with purple accent.
class DraculaTheme extends ThemePlugin {
  @override
  String get id => 'dracula';

  @override
  String get displayName => 'Dracula';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  FluentThemeData get fluentTheme => FluentThemeData(
        brightness: Brightness.dark,
        accentColor: AccentColor.swatch(const {
          'normal': Color(0xFFBD93F9),
        }),
        scaffoldBackgroundColor: const Color(0xFF282A36),
        micaBackgroundColor: const Color(0xFF21222C),
      );

  @override
  TabsViewThemeData get tabsTheme => const TabsViewThemeData(
        backgroundColor: Color(0xFF21222C),
        hoverBackgroundColor: Color(0xFF343746),
        selectedBackgroundColor: Color(0xFF282A36),
        labelColor: Color(0xFFF8F8F2),
        closeButtonColor: Color(0xFF6272A4),
      );
}
