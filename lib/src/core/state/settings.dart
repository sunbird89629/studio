import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:terminal_studio/src/core/record/settings_record.dart';
import 'package:terminal_studio/src/core/service/config_file_service.dart';
import 'package:terminal_studio/src/core/state/database.dart';
import 'package:terminal_studio/src/core/state/effective_settings.dart';
import 'package:terminal_studio/src/core/state/keymap.dart';

final settingsProvider = FutureProvider<SettingsRecord>((ref) async {
  final box = await ref.watch(settingsBoxProvider.future);

  // Create default settings if not exists
  if (box.isEmpty) {
    await box.add(SettingsRecord());
  }

  final settings = box.getAt(0)!;

  // Apply JSONC config overrides (Priority: JSONC > Hive > default)
  final configService = ref.read(configFileServiceProvider);
  await configService.generateDefaultConfig();
  await configService.loadFromFile(settings);

  // Start watching for external edits → hot reload
  configService.startWatching();

  // Listen for Hive changes → sync back to JSONC + invalidate UI
  final listener = box.watch().listen((event) {
    final current = box.getAt(0);
    if (current != null) {
      // Include profiles and keymaps in the JSONC output
      final profilesAsync = ref.read(profilesProvider);
      final profiles = profilesAsync.value;

      // Read keymaps
      final keymapBoxAsync = ref.read(keymapBoxProvider);
      final keymapBox = keymapBoxAsync.value;
      final keymaps = keymapBox != null && keymapBox.isNotEmpty
          ? keymapBox.getAt(0)?.bindings
          : null;

      configService.saveToFile(
        current,
        profiles: profiles,
        keymaps: keymaps,
      );
    }
    ref.invalidateSelf();
  });
  ref.onDispose(listener.cancel);

  return settings;
});

/// The ID of the currently active profile. null = use global settings.
final activeProfileIdProvider = StateProvider<String?>((ref) => null);

/// Resolved settings: active profile merged over global settings.
final effectiveSettingsProvider = Provider<EffectiveSettings>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  final profilesAsync = ref.watch(profilesProvider);
  final activeId = ref.watch(activeProfileIdProvider);

  final settings = settingsAsync.value;
  if (settings == null) return EffectiveSettings(SettingsRecord());

  final profiles = profilesAsync.value ?? [];
  final activeProfile = activeId != null
      ? profiles.where((p) => p.id == activeId).firstOrNull
      : null;

  return EffectiveSettings(settings, activeProfile);
});
