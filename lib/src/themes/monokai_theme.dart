import 'package:flex_tabs/flex_tabs.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:terminal_studio/src/core/theme/theme_plugin.dart';

/// Monokai Pro theme - popular dark theme with vibrant colors.
class MonokaiTheme extends ThemePlugin {
  @override
  String get id => 'monokai';

  @override
  String get displayName => 'Monokai Pro';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  FluentThemeData get fluentTheme => FluentThemeData(
        brightness: Brightness.dark,
        accentColor: AccentColor.swatch(const {
          'normal': Color(0xFFA9DC76),
        }),
        scaffoldBackgroundColor: const Color(0xFF2D2A2E),
        micaBackgroundColor: const Color(0xFF221F22),
      );

  @override
  TabsViewThemeData get tabsTheme => const TabsViewThemeData(
        backgroundColor: Color(0xFF221F22),
        hoverBackgroundColor: Color(0xFF363337),
        selectedBackgroundColor: Color(0xFF2D2A2E),
        labelColor: Color(0xFFFCFCFA),
        closeButtonColor: Color(0xFF939293),
      );
}
