import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/shared/state/broadcast_service.dart';
import 'package:terminal_studio/src/features/tabs/application/tabs_service.dart';
import 'package:terminal_studio/src/features/file_manager/application/file_manager_plugin.dart';
import 'package:terminal_studio/src/features/tabs/application/starter_plugin.dart';
import 'package:terminal_studio/src/features/terminal/application/terminal_plugin.dart';
import 'package:xterm/xterm.dart';

class TerminalContextMenu extends ConsumerStatefulWidget {
  const TerminalContextMenu({
    super.key,
    required this.plugin,
    this.onOpenFind,
    this.onToggleRecording,
    this.onToggleBroadcast,
  });

  final TerminalPlugin plugin;
  final VoidCallback? onOpenFind;
  final Future<void> Function()? onToggleRecording;
  final VoidCallback? onToggleBroadcast;

  @override
  TerminalContextMenuState createState() => TerminalContextMenuState();
}

class TerminalContextMenuState extends ConsumerState<TerminalContextMenu>
    with ContextMenuStateMixin {
  TerminalPlugin get plugin => widget.plugin;

  Terminal get terminal => plugin.terminal;

  TerminalController get terminalController => plugin.terminalController;

  @override
  void initState() {
    terminalController.addListener(_onSelectionChanged);
    super.initState();
  }

  @override
  void dispose() {
    terminalController.removeListener(_onSelectionChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TerminalContextMenu oldWidget) {
    if (oldWidget.plugin.terminalController !=
        widget.plugin.terminalController) {
      oldWidget.plugin.terminalController.removeListener(_onSelectionChanged);
      widget.plugin.terminalController.addListener(_onSelectionChanged);
    }
    super.didUpdateWidget(oldWidget);
  }

  void _onSelectionChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return cardBuilder(
      context,
      [
        buttonBuilder(
          context,
          ContextMenuButtonConfig(
            "Copy",
            icon: const Icon(Icons.copy),
            shortcutLabel: 'Ctrl+C',
            onPressed: terminalController.selection != null
                ? () => handlePressed(context, _handleCopy)
                : null,
          ),
        ),
        buttonBuilder(
          context,
          ContextMenuButtonConfig(
            "Paste",
            icon: const Icon(Icons.paste),
            shortcutLabel: 'Ctrl+V',
            onPressed: () => handlePressed(context, _handlePaste),
          ),
        ),
        buttonBuilder(
          context,
          ContextMenuButtonConfig(
            "Select All",
            icon: const Icon(Icons.select_all),
            shortcutLabel: 'Ctrl+A',
            onPressed: () => handlePressed(context, _handleSelectAll),
          ),
        ),
        buttonBuilder(
          context,
          ContextMenuButtonConfig(
            "Find",
            icon: const Icon(Icons.search),
            shortcutLabel: 'Cmd+F',
            onPressed: widget.onOpenFind != null
                ? () => handlePressed(context, () async {
                      widget.onOpenFind!();
                    })
                : null,
          ),
        ),
        buildDivider(),
        buttonBuilder(
          context,
          ContextMenuButtonConfig(
            "File Manager",
            icon: const Icon(Icons.folder_open),
            shortcutLabel: 'Ctrl+Shift+F',
            onPressed: () => handlePressed(context, _handleOpenFileManager),
          ),
        ),
        buttonBuilder(
          context,
          ContextMenuButtonConfig(
            "Uptime",
            icon: const Icon(Icons.keyboard_double_arrow_up_outlined),
            // shortcutLabel: 'Ctrl+Shift+F',
            onPressed: () => handlePressed(context, _handleStarterPlugin),
          ),
        ),
        buildDivider(),
        buttonBuilder(
          context,
          ContextMenuButtonConfig(
            plugin.isRecording ? "Stop Recording" : "Start Recording",
            icon: Icon(
              plugin.isRecording
                  ? Icons.stop_circle_outlined
                  : Icons.fiber_manual_record,
              color: plugin.isRecording ? Colors.red : null,
            ),
            onPressed: widget.onToggleRecording != null
                ? () => handlePressed(context, widget.onToggleRecording!)
                : null,
          ),
        ),
        () {
          final inBroadcast = BroadcastService.instance.isParticipant(plugin);
          final count = BroadcastService.instance.participantCount;
          return buttonBuilder(
            context,
            ContextMenuButtonConfig(
              inBroadcast
                  ? 'Leave Broadcast${count > 1 ? ' ($count)' : ''}'
                  : 'Join Broadcast',
              icon: Icon(
                Icons.cell_tower,
                color: inBroadcast ? Colors.orange : null,
              ),
              onPressed: widget.onToggleBroadcast != null
                  ? () => handlePressed(context, () async {
                        widget.onToggleBroadcast!();
                      })
                  : null,
            ),
          );
        }(),
      ],
    );
  }

  Future<void> _handleCopy() async {
    final selection = terminalController.selection;

    if (selection == null) {
      return;
    }

    final text = terminal.buffer.getText(selection);

    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);

    if (data == null) {
      return;
    }

    final text = data.text;

    if (text == null) {
      return;
    }

    terminal.paste(text);
  }

  Future<void> _handleSelectAll() async {
    terminalController.setSelection(
      terminal.buffer
          .createAnchor(0, terminal.buffer.height - terminal.viewHeight),
      terminal.buffer
          .createAnchor(terminal.viewWidth, terminal.buffer.height - 1),
    );
  }

  Future<void> _handleOpenFileManager() async {
    ref.read(tabsServiceProvider).openPlugin(
          plugin.hostSpec,
          FileManagerPlugin(),
        );
  }

  Future<void> _handleStarterPlugin() async {
    ref.read(tabsServiceProvider).openPlugin(
          plugin.hostSpec,
          StarterPlugin(),
        );
  }
}
