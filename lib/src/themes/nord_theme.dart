import 'package:flex_tabs/flex_tabs.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:terminal_studio/src/core/theme/theme_plugin.dart';

/// Nord theme - Arctic, north-bluish color palette.
class NordTheme extends ThemePlugin {
  @override
  String get id => 'nord';

  @override
  String get displayName => 'Nord';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  FluentThemeData get fluentTheme => FluentThemeData(
        brightness: Brightness.dark,
        accentColor: AccentColor.swatch(const {
          'normal': Color(0xFF88C0D0),
        }),
        scaffoldBackgroundColor: const Color(0xFF2E3440),
        micaBackgroundColor: const Color(0xFF3B4252),
      );

  @override
  TabsViewThemeData get tabsTheme => const TabsViewThemeData(
        backgroundColor: Color(0xFF3B4252),
        hoverBackgroundColor: Color(0xFF434C5E),
        selectedBackgroundColor: Color(0xFF2E3440),
        labelColor: Color(0xFFECEFF4),
        closeButtonColor: Color(0xFF4C566A),
      );
}
