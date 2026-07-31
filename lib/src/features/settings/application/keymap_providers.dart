import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_term/src/features/settings/infrastructure/config_file_repository.dart';
import 'package:open_term/src/features/settings/application/database_providers.dart';
import 'package:open_term/src/features/settings/application/settings_providers.dart';
import 'package:open_term/src/features/command_palette/application/shortcuts.dart';

/// Merged keymaps: platform defaults + user overrides from `config.jsonc`.
final keymapProvider =
    FutureProvider<Map<String, SingleActivator>>((ref) async {
  final config = ref.read(configFileServiceProvider);
  final bindings = await config.loadKeymaps();

  final merged = Map<String, SingleActivator>.from(defaultKeymaps);
  if (bindings.isNotEmpty) {
    merged.addAll(parseUserKeymaps(bindings));
  }

  return merged;
});

/// Save a user keymap override to `config.jsonc`.
Future<void> saveKeymapBinding(
  WidgetRef ref,
  String actionId,
  SingleActivator activator,
) async {
  final bindings = await ref.read(configFileServiceProvider).loadKeymaps();
  bindings[actionId] = activatorToString(activator);
  await _persistKeymaps(ref, bindings);
}

/// Reset a keymap binding to platform default.
Future<void> resetKeymapBinding(WidgetRef ref, String actionId) async {
  final bindings = await ref.read(configFileServiceProvider).loadKeymaps();
  bindings.remove(actionId);
  await _persistKeymaps(ref, bindings);
}

/// Reset all keymaps to platform defaults.
Future<void> resetAllKeymaps(WidgetRef ref) async {
  await _persistKeymaps(ref, const {});
}

/// Shared helper: write [keymaps] to config.jsonc and invalidate [keymapProvider].
Future<void> _persistKeymaps(WidgetRef ref, Map<String, String> keymaps) async {
  final config = ref.read(configFileServiceProvider);
  final settings = await ref.read(settingsProvider.future);
  final profiles = await ref.read(profilesProvider.future);
  await config.saveToFile(settings, profiles: profiles, keymaps: keymaps);
  ref.invalidate(keymapProvider);
}
