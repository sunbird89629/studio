import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:terminal_studio/src/shared/models/records/profile_record.dart';
import 'package:terminal_studio/src/shared/models/records/settings_record.dart';
import 'package:terminal_studio/src/features/settings/infrastructure/config_file_repository.dart';
import 'package:terminal_studio/src/features/settings/application/database_providers.dart';
import 'package:terminal_studio/src/features/settings/domain/effective_settings.dart';

final settingsProvider = FutureProvider<SettingsRecord>((ref) async {
  final config = ref.read(configFileServiceProvider);

  final settings = SettingsRecord();

  // Generate default config on first run
  await config.generateDefaultConfig();

  // Apply JSONC values (if file exists)
  await config.loadFromFile(settings);

  // Watch for external edits → hot reload
  config.startWatching(() => ref.invalidateSelf());

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

/// Persist [settings] to `config.jsonc` and invalidate dependent providers.
///
/// Pass [profiles] and [keymaps] to include them in the saved file.
/// If [profiles] is omitted, current profilesProvider value is used.
Future<void> persistSettings(
  WidgetRef ref,
  SettingsRecord settings, {
  List<ProfileRecord>? profiles,
  Map<String, String>? keymaps,
}) async {
  final config = ref.read(configFileServiceProvider);
  final resolvedProfiles = profiles ?? ref.read(profilesProvider).value ?? [];
  await config.saveToFile(
    settings,
    profiles: resolvedProfiles,
    keymaps: keymaps,
  );
  ref.invalidate(settingsProvider);
}
