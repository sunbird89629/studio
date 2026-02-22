import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/service/config_file_service.dart';
import 'package:terminal_studio/src/core/state/database.dart';
import 'package:terminal_studio/src/core/state/settings.dart';
import 'package:terminal_studio/src/ui/shortcuts.dart';

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
  final config = ref.read(configFileServiceProvider);

  // Load current state
  final settings = await ref.read(settingsProvider.future);
  final profiles = ref.read(profilesProvider).value ?? [];
  final currentBindings = await config.loadKeymaps();

  // Apply override
  currentBindings[actionId] = activatorToString(activator);

  await config.saveToFile(
    settings,
    profiles: profiles,
    keymaps: currentBindings,
  );

  ref.invalidate(keymapProvider);
}

/// Reset a keymap binding to platform default.
Future<void> resetKeymapBinding(WidgetRef ref, String actionId) async {
  final config = ref.read(configFileServiceProvider);

  final settings = await ref.read(settingsProvider.future);
  final profiles = ref.read(profilesProvider).value ?? [];
  final currentBindings = await config.loadKeymaps();

  currentBindings.remove(actionId);

  await config.saveToFile(
    settings,
    profiles: profiles,
    keymaps: currentBindings,
  );

  ref.invalidate(keymapProvider);
}

/// Reset all keymaps to platform defaults.
Future<void> resetAllKeymaps(WidgetRef ref) async {
  final config = ref.read(configFileServiceProvider);

  final settings = await ref.read(settingsProvider.future);
  final profiles = ref.read(profilesProvider).value ?? [];

  await config.saveToFile(
    settings,
    profiles: profiles,
    keymaps: const {},
  );

  ref.invalidate(keymapProvider);
}
