import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/state/keymap.dart';
import 'package:terminal_studio/src/ui/shortcuts.dart' as shortcuts;
import 'package:terminal_studio/src/ui/shortcuts.dart' show ShortcutId, defaultKeymaps;

/// Settings panel for viewing and customizing keyboard shortcuts.
class ShortcutsSettingsView extends ConsumerWidget {
  const ShortcutsSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keymapAsync = ref.watch(keymapProvider);

    return keymapAsync.when(
      data: (keymap) => ScaffoldPage(
        header: PageHeader(
          title: const Text('Keyboard Shortcuts'),
          commandBar: CommandBar(
            mainAxisAlignment: MainAxisAlignment.end,
            primaryItems: [
              CommandBarButton(
                icon: const Icon(FluentIcons.refresh),
                label: const Text('Reset All'),
                onPressed: () => _confirmResetAll(context, ref),
              ),
            ],
          ),
        ),
        content: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: ShortcutId.labels.entries.map((entry) {
            final actionId = entry.key;
            final label = entry.value;
            final activator = keymap[actionId];
            final isDefault = defaultKeymaps[actionId] == activator;

            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: ListTile(
                title: Text(label),
                subtitle: activator != null
                    ? Text(
                        shortcuts.formatActivator(activator),
                        style: TextStyle(
                          color: isDefault ? null : Colors.blue,
                          fontFamily: 'monospace',
                        ),
                      )
                    : const Text('Not set'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Record new shortcut',
                      child: IconButton(
                        icon:
                            const Icon(FluentIcons.keyboard_classic, size: 16),
                        onPressed: () =>
                            _recordShortcut(context, ref, actionId, label),
                      ),
                    ),
                    if (!isDefault)
                      Tooltip(
                        message: 'Reset to default',
                        child: IconButton(
                          icon: const Icon(FluentIcons.undo, size: 16),
                          onPressed: () => resetKeymapBinding(ref, actionId),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Future<void> _recordShortcut(
    BuildContext context,
    WidgetRef ref,
    String actionId,
    String label,
  ) async {
    final result = await showDialog<SingleActivator>(
      context: context,
      builder: (ctx) => _ShortcutRecorderDialog(actionLabel: label),
    );
    if (result != null) {
      // Check for conflicts
      final keymap = ref.read(keymapProvider).value ?? {};
      final conflict = keymap.entries
          .where((e) => e.key != actionId && e.value == result)
          .firstOrNull;

      if (conflict != null && context.mounted) {
        final overwrite = await showDialog<bool>(
          context: context,
          builder: (ctx) => ContentDialog(
            title: const Text('Shortcut Conflict'),
            content: Text(
              '${shortcuts.formatActivator(result)} is already used by '
              '"${ShortcutId.label(conflict.key)}".\n\n'
              'Override?',
            ),
            actions: [
              Button(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              FilledButton(
                child: const Text('Override'),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
        );
        if (overwrite != true) return;
      }

      await saveKeymapBinding(ref, actionId, result);
    }
  }

  Future<void> _confirmResetAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Reset All Shortcuts'),
        content: const Text(
            'Reset all shortcuts to defaults? Custom bindings will be lost.'),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          FilledButton(
            child: const Text('Reset'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await resetAllKeymaps(ref);
    }
  }
}

/// Dialog that listens for a key combination and returns a SingleActivator.
class _ShortcutRecorderDialog extends StatefulWidget {
  const _ShortcutRecorderDialog({required this.actionLabel});
  final String actionLabel;

  @override
  State<_ShortcutRecorderDialog> createState() =>
      _ShortcutRecorderDialogState();
}

class _ShortcutRecorderDialogState extends State<_ShortcutRecorderDialog> {
  SingleActivator? _recorded;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text('Set shortcut for "${widget.actionLabel}"'),
      content: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is! KeyDownEvent) return;

          // Skip modifier-only keys
          if (_isModifierKey(event.logicalKey)) return;

          final meta = HardwareKeyboard.instance.isMetaPressed;
          final control = HardwareKeyboard.instance.isControlPressed;
          final shift = HardwareKeyboard.instance.isShiftPressed;
          final alt = HardwareKeyboard.instance.isAltPressed;

          setState(() {
            _recorded = SingleActivator(
              event.logicalKey,
              meta: meta,
              control: control,
              shift: shift,
              alt: alt,
            );
          });
        },
        child: Container(
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: FluentTheme.of(context).accentColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _recorded != null
              ? Text(
                  shortcuts.formatActivator(_recorded!),
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                )
              : const Text(
                  'Press a key combination...',
                  style: TextStyle(fontSize: 16),
                ),
        ),
      ),
      actions: [
        Button(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        FilledButton(
          onPressed: _recorded != null
              ? () => Navigator.of(context).pop(_recorded)
              : null,
          child: const Text('Apply'),
        ),
      ],
    );
  }

  bool _isModifierKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight;
  }

}
