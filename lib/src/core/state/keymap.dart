import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/record/keymap_record.dart';
import 'package:terminal_studio/src/core/state/database.dart';
import 'package:terminal_studio/src/ui/shortcuts.dart';

/// Provider for the KeymapRecord Hive box.
final keymapBoxProvider = FutureProvider((ref) async {
  final hive = await ref.watch(hiveProvider.future);
  hive.registerAdapter(KeymapRecordAdapter());
  return hive.openBox<KeymapRecord>('keymaps');
});

/// Merged keymaps: defaults + user overrides.
final keymapProvider =
    FutureProvider<Map<String, SingleActivator>>((ref) async {
  final box = await ref.watch(keymapBoxProvider.future);

  // Watch for changes
  final listener = box.watch().listen((_) => ref.invalidateSelf());
  ref.onDispose(listener.cancel);

  // Start with platform defaults
  final merged = Map<String, SingleActivator>.from(defaultKeymaps);

  // Apply user overrides
  if (box.isNotEmpty) {
    final record = box.getAt(0)!;
    final overrides = parseUserKeymaps(record.bindings);
    merged.addAll(overrides);
  }

  return merged;
});

/// Save a user keymap override.
Future<void> saveKeymapBinding(
  WidgetRef ref,
  String actionId,
  SingleActivator activator,
) async {
  final box = await ref.read(keymapBoxProvider.future);

  KeymapRecord record;
  if (box.isEmpty) {
    record = KeymapRecord();
    await box.add(record);
  } else {
    record = box.getAt(0)!;
  }

  record.bindings[actionId] = activatorToString(activator);
  await record.save();
}

/// Reset a keymap binding to default.
Future<void> resetKeymapBinding(WidgetRef ref, String actionId) async {
  final box = await ref.read(keymapBoxProvider.future);
  if (box.isEmpty) return;

  final record = box.getAt(0)!;
  record.bindings.remove(actionId);
  await record.save();
}

/// Reset all keymaps to defaults.
Future<void> resetAllKeymaps(WidgetRef ref) async {
  final box = await ref.read(keymapBoxProvider.future);
  if (box.isEmpty) return;

  final record = box.getAt(0)!;
  record.bindings.clear();
  await record.save();
}
