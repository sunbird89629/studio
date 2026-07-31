import 'package:command_palette/command_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_term/src/features/command_palette/application/command.dart';
import 'package:open_term/src/features/command_palette/application/command_palette_notifier.dart';
import 'package:open_term/src/features/command_palette/application/shortcuts.dart';
import 'package:open_term/src/features/settings/application/keymap_providers.dart';

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
        filter: _fastFilter,
        builder: _fastBuilder,
        style: const CommandPaletteStyle(
          highlightSearchSubstring: false,
        ),
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

  static List<CommandPaletteAction> _fastFilter(
    String query,
    List<CommandPaletteAction> actions,
  ) {
    const maxResults = 120;
    if (query.isEmpty) {
      return actions.length <= maxResults
          ? actions
          : actions.take(maxResults).toList(growable: false);
    }

    final lowerQuery = query.toLowerCase();
    final scored = <({CommandPaletteAction action, int score})>[];

    for (final action in actions) {
      final score = _scoreAction(action, lowerQuery);
      if (score > 0) {
        scored.add((action: action, score: score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    if (scored.length > maxResults) {
      return scored
          .take(maxResults)
          .map((e) => e.action)
          .toList(growable: false);
    }
    return scored.map((e) => e.action).toList(growable: false);
  }

  static int _scoreAction(CommandPaletteAction action, String lowerQuery) {
    final label = action.label.toLowerCase();
    final category = (action.description ?? '').toLowerCase();

    if (label.startsWith(lowerQuery)) return 100;
    if (label.contains(lowerQuery)) return 80;
    if (category.contains(lowerQuery)) return 60;
    if (_fuzzyMatch(label, lowerQuery)) return 40;
    return 0;
  }

  static bool _fuzzyMatch(String text, String query) {
    var queryIndex = 0;
    for (var i = 0; i < text.length && queryIndex < query.length; i++) {
      if (text[i] == query[queryIndex]) {
        queryIndex++;
      }
    }
    return queryIndex == query.length;
  }

  static Widget _fastBuilder(
    BuildContext context,
    CommandPaletteStyle style,
    CommandPaletteAction action,
    bool isHighlighted,
    VoidCallback onSelected,
    List<String> searchTerms,
  ) {
    final labelStyle = style.actionLabelTextStyle ??
        Theme.of(context).textTheme.titleMedium ??
        const TextStyle();
    final descStyle = style.actionDescriptionTextStyle ??
        Theme.of(context).textTheme.bodySmall ??
        const TextStyle();

    return Material(
      color: isHighlighted ? style.selectedColor : style.actionColor,
      child: InkWell(
        onTap: onSelected,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                if (action.leading != null) ...[
                  action.leading!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        action.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle,
                      ),
                      if (action.description != null)
                        Text(
                          action.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: descStyle,
                        ),
                    ],
                  ),
                ),
                if (action.shortcut != null && action.shortcut!.isNotEmpty)
                  Text(
                    action.shortcut!.join(' '),
                    style: descStyle,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
