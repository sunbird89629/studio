import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/features/command_palette/application/command.dart';
import 'package:terminal_studio/src/features/command_palette/application/command_palette_notifier.dart';
import 'package:terminal_studio/src/shared/widgets/shortcut_label.dart';

class CommandPaletteListener extends ConsumerWidget {
  const CommandPaletteListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(commandPaletteServiceProvider.select((s) => s.isVisible),
        (_, next) {
      if (next == true) {
        showDialog<void>(
          context: context,
          useRootNavigator: true,
          barrierDismissible: true,
          barrierColor: Colors.black38,
          builder: (_) => const _CommandPaletteDialog(),
        ).then((_) {
          // Sync state when dismissed externally (barrier tap or Escape)
          ref.read(commandPaletteServiceProvider.notifier).hide();
        });
      }
    });
    return child;
  }
}

class _CommandPaletteDialog extends ConsumerStatefulWidget {
  const _CommandPaletteDialog();

  @override
  ConsumerState<_CommandPaletteDialog> createState() =>
      _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends ConsumerState<_CommandPaletteDialog> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(commandPaletteServiceProvider.select((s) => s.isVisible),
        (_, next) {
      if (next == false && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });

    final state = ref.watch(commandPaletteServiceProvider);
    final notifier = ref.read(commandPaletteServiceProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Material(
          elevation: 8,
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Focus(
                    onKeyEvent: (_, event) {
                      if (event is! KeyDownEvent) return KeyEventResult.ignored;
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        notifier.selectNext();
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        notifier.selectPrevious();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Type a command...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onChanged: notifier.setQuery,
                      onSubmitted: (_) =>
                          notifier.executeSelected(context, ref),
                    ),
                  ),
                ),
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
                          onTap: () =>
                              notifier.executeCommand(command, context, ref),
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
              if (command.shortcutId != null) ...[
                const SizedBox(width: 8),
                ShortcutLabel(command.shortcutId!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

