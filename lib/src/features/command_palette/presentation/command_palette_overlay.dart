import 'package:command_palette/command_palette.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/features/command_palette/application/command.dart';
import 'package:terminal_studio/src/features/command_palette/application/command_palette_notifier.dart';
import 'package:terminal_studio/src/features/command_palette/application/shortcuts.dart';
import 'package:terminal_studio/src/features/settings/application/keymap_providers.dart';

class CommandPaletteListener extends ConsumerWidget {
  const CommandPaletteListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commands = ref.watch(commandPaletteCommandsProvider);
    final keymapAsync = ref.watch(keymapProvider);
    final keymap = keymapAsync.value ?? defaultKeymaps;

    return CommandPalette(
      actions: _toActions(
        context: context,
        ref: ref,
        commands: commands,
        keymap: keymap,
      ),
      config: CommandPaletteConfig(
        hintText: 'Type a command...',
        openKeySet: keymap[ShortcutId.commandPalette] ??
            defaultKeymaps[ShortcutId.commandPalette]!,
      ),
      child: child,
    );
  }

  List<CommandPaletteAction> _toActions({
    required BuildContext context,
    required WidgetRef ref,
    required List<Command> commands,
    required Map<String, SingleActivator> keymap,
  }) {
    return commands
        .map(
          (command) => CommandPaletteAction.single(
            id: command.id,
            label: command.label,
            description: command.category,
            shortcut: command.shortcutId == null
                ? null
                : _shortcutParts(keymap[command.shortcutId!]),
            onSelect: () {
              if (!command.isEnabled(context)) {
                return;
              }
              command.execute(context, ref);
            },
          ),
        )
        .toList(growable: false);
  }

  List<String>? _shortcutParts(SingleActivator? activator) {
    if (activator == null) {
      return null;
    }

    final parts = <String>[];
    if (activator.meta) parts.add('⌘');
    if (activator.control) parts.add('Ctrl');
    if (activator.alt) parts.add('⌥');
    if (activator.shift) parts.add('⇧');

    final keyLabel = activator.trigger.keyLabel;
    if (keyLabel.isNotEmpty) {
      parts.add(keyLabel.length == 1 ? keyLabel.toUpperCase() : keyLabel);
    }

    return parts;
  }
}
