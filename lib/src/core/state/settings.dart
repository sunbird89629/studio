import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/record/settings_record.dart';
import 'package:terminal_studio/src/core/state/database.dart';

final settingsProvider = FutureProvider<SettingsRecord>((ref) async {
  final box = await ref.watch(settingsBoxProvider.future);
  
  // Create default settings if not exists
  if (box.isEmpty) {
    await box.add(SettingsRecord());
  }

  // Listen for changes
  final listener = box.watch().listen((event) {
    ref.invalidateSelf();
  });
  ref.onDispose(listener.cancel);

  return box.getAt(0)!;
});
