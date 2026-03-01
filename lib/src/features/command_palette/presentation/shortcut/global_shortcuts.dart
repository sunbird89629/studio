import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/features/settings/application/keymap_providers.dart';
import 'package:terminal_studio/src/features/command_palette/application/intents.dart';
import 'package:terminal_studio/src/features/command_palette/application/shortcuts.dart';

class GlobalShortcuts extends ConsumerWidget {
  const GlobalShortcuts({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keymapAsync = ref.watch(keymapProvider);

    // Use defaults while loading
    final keymap = keymapAsync.value ?? defaultKeymaps;

    return Shortcuts(
      shortcuts: {
        keymap[ShortcutId.newWindow]!: const NewWindowIntent(),
        keymap[ShortcutId.newTab]!: const NewTabIntent(),
        keymap[ShortcutId.previousTab]!: const PreviousTabIntent(),
        keymap[ShortcutId.nextTab]!: const NextTabIntent(),
        keymap[ShortcutId.closeTab]!: const CloseTabIntent(),
        keymap[ShortcutId.commandPalette]!: const OpenCommandPaletteIntent(),
        keymap[ShortcutId.vimEdit]!: const VimEditIntent(),
        keymap[ShortcutId.openSettings]!: const OpenSettingsIntent(),
        keymap[ShortcutId.openDevTools]!: const OpenDevToolsIntent(),
      },
      child: child,
    );
  }
}
