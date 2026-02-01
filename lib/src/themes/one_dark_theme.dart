import 'package:flex_tabs/flex_tabs.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:terminal_studio/src/core/theme/theme_plugin.dart';

/// One Dark theme - Atom editor's iconic dark theme.
class OneDarkTheme extends ThemePlugin {
  @override
  String get id => 'one-dark';

  @override
  String get displayName => 'One Dark';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  FluentThemeData get fluentTheme => FluentThemeData(
        brightness: Brightness.dark,
        accentColor: AccentColor.swatch(const {
          'normal': Color(0xFF61AFEF),
        }),
        scaffoldBackgroundColor: const Color(0xFF282C34),
        micaBackgroundColor: const Color(0xFF21252B),
      );

  @override
  TabsViewThemeData get tabsTheme => const TabsViewThemeData(
        backgroundColor: Color(0xFF21252B),
        hoverBackgroundColor: Color(0xFF2C313A),
        selectedBackgroundColor: Color(0xFF282C34),
        labelColor: Color(0xFFABB2BF),
        closeButtonColor: Color(0xFF5C6370),
      );
}
