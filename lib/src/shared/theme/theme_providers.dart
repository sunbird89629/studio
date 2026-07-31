import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_term/src/features/settings/infrastructure/config_file_repository.dart';
import 'package:open_term/src/features/settings/application/database_providers.dart';
import 'package:open_term/src/features/settings/application/settings_providers.dart';
import 'package:open_term/src/shared/theme/theme_plugin.dart';
import 'package:open_term/src/shared/theme/theme_registry.dart';
import 'package:open_term/src/shared/theme/themes.dart';

/// Global theme registry containing all registered themes.
final themeRegistryProvider = Provider<ThemeRegistry>((ref) {
  final registry = ThemeRegistry();

  // Register built-in themes
  registry.registerAll([
    LightTheme(),
    DarkTheme(),
    MonokaiTheme(),
    DraculaTheme(),
    OneDarkTheme(),
    NordTheme(),
    SolarizedDarkTheme(),
    SolarizedLightTheme(),
    GitHubDarkTheme(),
    GitHubLightTheme(),
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

    final settings = await ref.read(settingsProvider.future);
    settings.themeId = themeId;
    final config = ref.read(configFileServiceProvider);
    final profiles = await ref.read(profilesProvider.future);
    await config.saveToFile(settings, profiles: profiles);
    ref.invalidate(settingsProvider);
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
