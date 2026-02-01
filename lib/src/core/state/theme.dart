import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/state/database.dart';
import 'package:terminal_studio/src/core/state/settings.dart';
import 'package:terminal_studio/src/core/theme/theme_plugin.dart';
import 'package:terminal_studio/src/core/theme/theme_registry.dart';
import 'package:terminal_studio/src/themes/themes.dart';

/// Global theme registry containing all registered themes.
final themeRegistryProvider = Provider<ThemeRegistry>((ref) {
  final registry = ThemeRegistry();

  // Register built-in themes
  registry.registerAll([
    LightTheme(),
    DarkTheme(),
  ]);

  return registry;
});

/// Provider for the current theme ID from settings.
final themeIdProvider = Provider<String>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.when(
    data: (s) => s.themeId,
    loading: () => 'dark',
    error: (_, __) => 'dark',
  );
});

/// Provider for the currently active theme plugin.
final activeThemeProvider = Provider<ThemePlugin>((ref) {
  final registry = ref.watch(themeRegistryProvider);
  final themeId = ref.watch(themeIdProvider);

  return registry.get(themeId) ?? DarkTheme();
});

/// Service for changing themes.
class ThemeService {
  final Ref ref;

  ThemeService(this.ref);

  /// Set the theme by ID and persist the change.
  Future<void> setTheme(String themeId) async {
    final registry = ref.read(themeRegistryProvider);
    if (!registry.contains(themeId)) {
      throw ArgumentError('Unknown theme: $themeId');
    }

    final box = await ref.read(settingsBoxProvider.future);
    final settings = box.getAt(0);
    if (settings != null) {
      settings.themeId = themeId;
      await settings.save();
    }
  }

  /// Toggle between light and dark themes.
  Future<void> toggleTheme() async {
    final current = ref.read(themeIdProvider);
    final newTheme = current == 'light' ? 'dark' : 'light';
    await setTheme(newTheme);
  }
}

final themeServiceProvider = Provider<ThemeService>((ref) {
  return ThemeService(ref);
});
