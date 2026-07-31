import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_term/src/features/settings/application/keymap_providers.dart';
import 'package:open_term/src/features/command_palette/application/shortcuts.dart';

/// Displays the keyboard shortcut for a given [shortcutId] as key-cap badges.
/// Returns [SizedBox.shrink] if the shortcut is not found.
class ShortcutLabel extends ConsumerWidget {
  const ShortcutLabel(this.shortcutId, {super.key});

  final String shortcutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keymap = ref.watch(keymapProvider).value ?? defaultKeymaps;
    final activator = keymap[shortcutId];
    if (activator == null) return const SizedBox.shrink();
    return _KeyCapRow(shortcut: activator);
  }
}

class _KeyCapRow extends StatelessWidget {
  const _KeyCapRow({required this.shortcut});

  final SingleActivator shortcut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isApple = theme.platform == TargetPlatform.macOS ||
        theme.platform == TargetPlatform.iOS;

    final keys = <String>[
      if (shortcut.meta) isApple ? '⌘' : 'Ctrl',
      if (shortcut.control && !shortcut.meta) 'Ctrl',
      if (shortcut.alt) isApple ? '⌥' : 'Alt',
      if (shortcut.shift) isApple ? '⇧' : 'Shift',
      _keyLabel(shortcut.trigger),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: keys.map((key) {
        return Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Text(
            key,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
        );
      }).toList(),
    );
  }

  static String _keyLabel(LogicalKeyboardKey key) {
    final labels = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.keyA: 'A', LogicalKeyboardKey.keyB: 'B',
      LogicalKeyboardKey.keyC: 'C', LogicalKeyboardKey.keyD: 'D',
      LogicalKeyboardKey.keyE: 'E', LogicalKeyboardKey.keyF: 'F',
      LogicalKeyboardKey.keyG: 'G', LogicalKeyboardKey.keyH: 'H',
      LogicalKeyboardKey.keyI: 'I', LogicalKeyboardKey.keyJ: 'J',
      LogicalKeyboardKey.keyK: 'K', LogicalKeyboardKey.keyL: 'L',
      LogicalKeyboardKey.keyM: 'M', LogicalKeyboardKey.keyN: 'N',
      LogicalKeyboardKey.keyO: 'O', LogicalKeyboardKey.keyP: 'P',
      LogicalKeyboardKey.keyQ: 'Q', LogicalKeyboardKey.keyR: 'R',
      LogicalKeyboardKey.keyS: 'S', LogicalKeyboardKey.keyT: 'T',
      LogicalKeyboardKey.keyU: 'U', LogicalKeyboardKey.keyV: 'V',
      LogicalKeyboardKey.keyW: 'W', LogicalKeyboardKey.keyX: 'X',
      LogicalKeyboardKey.keyY: 'Y', LogicalKeyboardKey.keyZ: 'Z',
      LogicalKeyboardKey.comma: ',', LogicalKeyboardKey.period: '.',
      LogicalKeyboardKey.bracketLeft: '[', LogicalKeyboardKey.bracketRight: ']',
      LogicalKeyboardKey.enter: '↵', LogicalKeyboardKey.escape: 'Esc',
      LogicalKeyboardKey.tab: 'Tab', LogicalKeyboardKey.space: 'Space',
      LogicalKeyboardKey.backspace: '⌫', LogicalKeyboardKey.delete: 'Del',
      LogicalKeyboardKey.arrowUp: '↑', LogicalKeyboardKey.arrowDown: '↓',
      LogicalKeyboardKey.arrowLeft: '←', LogicalKeyboardKey.arrowRight: '→',
      LogicalKeyboardKey.pageUp: 'PgUp', LogicalKeyboardKey.pageDown: 'PgDn',
      LogicalKeyboardKey.f1: 'F1', LogicalKeyboardKey.f2: 'F2',
      LogicalKeyboardKey.f3: 'F3', LogicalKeyboardKey.f4: 'F4',
      LogicalKeyboardKey.f5: 'F5', LogicalKeyboardKey.f6: 'F6',
      LogicalKeyboardKey.f7: 'F7', LogicalKeyboardKey.f8: 'F8',
      LogicalKeyboardKey.f9: 'F9', LogicalKeyboardKey.f10: 'F10',
      LogicalKeyboardKey.f11: 'F11', LogicalKeyboardKey.f12: 'F12',
    };
    return labels[key] ?? key.keyLabel;
  }
}
