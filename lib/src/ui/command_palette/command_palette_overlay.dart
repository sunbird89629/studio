import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/command/command.dart';
import 'package:terminal_studio/src/core/service/command_palette_service.dart';
import 'package:terminal_studio/src/core/state/keymap.dart';
import 'package:terminal_studio/src/ui/shortcuts.dart';

/// Command Palette 覆盖层组件
///
/// 在应用顶层使用此组件，通过 CommandPaletteService 控制显示/隐藏。
class CommandPaletteOverlay extends ConsumerStatefulWidget {
  const CommandPaletteOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CommandPaletteOverlay> createState() =>
      _CommandPaletteOverlayState();
}

class _CommandPaletteOverlayState extends ConsumerState<CommandPaletteOverlay> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final notifier = ref.read(commandPaletteServiceProvider.notifier);

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      notifier.selectNext();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      notifier.selectPrevious();
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      notifier.executeSelected(context, ref);
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      notifier.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commandPaletteServiceProvider);

    return Stack(
      children: [
        widget.child,
        if (state.isVisible) ...[
          // 背景遮罩
          GestureDetector(
            onTap: () =>
                ref.read(commandPaletteServiceProvider.notifier).hide(),
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          // Command Palette 面板
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: _CommandPalettePanel(
                textController: _textController,
                focusNode: _focusNode,
                onKeyEvent: _handleKeyEvent,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CommandPalettePanel extends ConsumerStatefulWidget {
  const _CommandPalettePanel({
    required this.textController,
    required this.focusNode,
    required this.onKeyEvent,
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final void Function(KeyEvent) onKeyEvent;

  @override
  ConsumerState<_CommandPalettePanel> createState() =>
      _CommandPalettePanelState();
}

class _CommandPalettePanelState extends ConsumerState<_CommandPalettePanel> {
  final _panelFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 显示时自动聚焦
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.focusNode.requestFocus();
      widget.textController.clear();
    });
  }

  @override
  void dispose() {
    _panelFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commandPaletteServiceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return KeyboardListener(
      focusNode: _panelFocusNode,
      onKeyEvent: widget.onKeyEvent,
      child: Material(
        elevation: 8,
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.dividerColor,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 搜索输入框
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: widget.textController,
                  focusNode: widget.focusNode,
                  decoration: InputDecoration(
                    hintText: 'Type a command...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    ref
                        .read(commandPaletteServiceProvider.notifier)
                        .setQuery(value);
                  },
                ),
              ),
              // 命令列表
              if (state.filteredCommands.isNotEmpty)
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: state.filteredCommands.length,
                    itemBuilder: (context, index) {
                      final command = state.filteredCommands[index];
                      final isSelected = index == state.selectedIndex;
                      return _CommandPaletteItem(
                        command: command,
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(commandPaletteServiceProvider.notifier)
                              .executeCommand(command, context, ref);
                        },
                      );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No commands found',
                    style: TextStyle(color: theme.disabledColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommandPaletteItem extends ConsumerWidget {
  const _CommandPaletteItem({
    required this.command,
    required this.isSelected,
    required this.onTap,
  });

  final Command command;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final keymap = ref.watch(keymapProvider).value ?? defaultKeymaps;
    final shortcut =
        command.shortcutId != null ? keymap[command.shortcutId!] : null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color:
                isSelected ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // 分类标签
              if (command.category != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    command.category!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // 命令名称
              Expanded(
                child: Text(
                  command.label,
                  style: TextStyle(
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              // 快捷键
              if (shortcut != null) ...[
                const SizedBox(width: 8),
                _ShortcutLabel(shortcut: shortcut),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutLabel extends StatelessWidget {
  const _ShortcutLabel({required this.shortcut});

  final SingleActivator shortcut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final keys = <String>[];

    final isApple = TargetPlatform.macOS == theme.platform ||
        TargetPlatform.iOS == theme.platform;

    if (shortcut.meta) {
      keys.add(isApple ? '⌘' : 'Ctrl');
    }
    if (shortcut.control && !shortcut.meta) {
      keys.add('Ctrl');
    }
    if (shortcut.alt) {
      keys.add(isApple ? '⌥' : 'Alt');
    }
    if (shortcut.shift) {
      keys.add(isApple ? '⇧' : 'Shift');
    }

    // 获取按键名称
    final keyLabel = _getKeyLabel(shortcut.trigger);
    keys.add(keyLabel);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: keys.map((key) {
        return Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: theme.dividerColor,
              width: 1,
            ),
          ),
          child: Text(
            key,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getKeyLabel(LogicalKeyboardKey key) {
    // 常见按键映射
    final keyLabels = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.keyA: 'A',
      LogicalKeyboardKey.keyB: 'B',
      LogicalKeyboardKey.keyC: 'C',
      LogicalKeyboardKey.keyD: 'D',
      LogicalKeyboardKey.keyE: 'E',
      LogicalKeyboardKey.keyF: 'F',
      LogicalKeyboardKey.keyG: 'G',
      LogicalKeyboardKey.keyH: 'H',
      LogicalKeyboardKey.keyI: 'I',
      LogicalKeyboardKey.keyJ: 'J',
      LogicalKeyboardKey.keyK: 'K',
      LogicalKeyboardKey.keyL: 'L',
      LogicalKeyboardKey.keyM: 'M',
      LogicalKeyboardKey.keyN: 'N',
      LogicalKeyboardKey.keyO: 'O',
      LogicalKeyboardKey.keyP: 'P',
      LogicalKeyboardKey.keyQ: 'Q',
      LogicalKeyboardKey.keyR: 'R',
      LogicalKeyboardKey.keyS: 'S',
      LogicalKeyboardKey.keyT: 'T',
      LogicalKeyboardKey.keyU: 'U',
      LogicalKeyboardKey.keyV: 'V',
      LogicalKeyboardKey.keyW: 'W',
      LogicalKeyboardKey.keyX: 'X',
      LogicalKeyboardKey.keyY: 'Y',
      LogicalKeyboardKey.keyZ: 'Z',
      LogicalKeyboardKey.comma: ',',
      LogicalKeyboardKey.period: '.',
      LogicalKeyboardKey.bracketLeft: '[',
      LogicalKeyboardKey.bracketRight: ']',
      LogicalKeyboardKey.enter: '↵',
      LogicalKeyboardKey.escape: 'Esc',
      LogicalKeyboardKey.tab: 'Tab',
      LogicalKeyboardKey.space: 'Space',
      LogicalKeyboardKey.backspace: '⌫',
      LogicalKeyboardKey.delete: 'Del',
      LogicalKeyboardKey.arrowUp: '↑',
      LogicalKeyboardKey.arrowDown: '↓',
      LogicalKeyboardKey.arrowLeft: '←',
      LogicalKeyboardKey.arrowRight: '→',
      LogicalKeyboardKey.pageUp: 'PgUp',
      LogicalKeyboardKey.pageDown: 'PgDn',
      LogicalKeyboardKey.f1: 'F1',
      LogicalKeyboardKey.f2: 'F2',
      LogicalKeyboardKey.f3: 'F3',
      LogicalKeyboardKey.f4: 'F4',
      LogicalKeyboardKey.f5: 'F5',
      LogicalKeyboardKey.f6: 'F6',
      LogicalKeyboardKey.f7: 'F7',
      LogicalKeyboardKey.f8: 'F8',
      LogicalKeyboardKey.f9: 'F9',
      LogicalKeyboardKey.f10: 'F10',
      LogicalKeyboardKey.f11: 'F11',
      LogicalKeyboardKey.f12: 'F12',
    };

    return keyLabels[key] ?? key.keyLabel;
  }
}
