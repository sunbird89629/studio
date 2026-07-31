import 'dart:io' as io;

import 'package:context_menus/context_menus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        Colors,
        ElevatedButton,
        IconButton,
        Icons,
        InputDecoration,
        Material,
        OutlineInputBorder,
        ScaffoldMessenger,
        SnackBar,
        Text,
        TextField,
        Theme;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_term/src/features/command_palette/application/intents.dart';
import 'package:open_term/src/features/command_palette/application/shortcuts.dart';
import 'package:open_term/src/features/settings/application/keymap_providers.dart';
import 'package:open_term/src/features/settings/application/settings_providers.dart';
import 'package:open_term/src/features/terminal/application/inline_image.dart';
import 'package:open_term/src/features/terminal/application/terminal_menu.dart';
import 'package:open_term/src/features/terminal/application/terminal_plugin.dart';
import 'package:open_term/src/platform/hosts/host_connector.dart';
import 'package:open_term/src/platform/hosts/host_providers.dart';
import 'package:open_term/src/shared/logging/app_logger.dart';
import 'package:open_term/src/shared/state/broadcast_service.dart';
import 'package:open_term/src/shared/state/launcher_service.dart';
import 'package:open_term/src/shared/utils/link_detector.dart';
import 'package:xterm/xterm.dart';

class TerminalTabView extends ConsumerStatefulWidget {
  const TerminalTabView(this.plugin, {super.key});

  final TerminalPlugin plugin;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _TerminalTabViewState();
}

class _TerminalTabViewState extends ConsumerState<TerminalTabView> {
  static const _passthroughIntents = <String, Intent>{
    ShortcutId.previousTab: PreviousTabIntent(),
    ShortcutId.nextTab: NextTabIntent(),
    ShortcutId.commandPalette: OpenCommandPaletteIntent(),
    ShortcutId.vimEdit: VimEditIntent(),
  };

  final _logger = AppLogger.forComponent('TerminalTabView');

  Map<String, SingleActivator> _currentKeymap = defaultKeymaps;
  bool _openModifierActive = false;

  final _terminalFocus = FocusNode();

  bool _findVisible = false;
  final _findController = TextEditingController();
  final _findFocus = FocusNode();
  List<int> _findMatchLines = [];
  int _findCurrentMatch = 0;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    _findController.addListener(_onFindQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _terminalFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _terminalFocus.dispose();
    _findController.dispose();
    _findFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openFind() {
    setState(() => _findVisible = true);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _findFocus.requestFocus());
  }

  void _closeFind() {
    setState(() {
      _findVisible = false;
      _findMatchLines = [];
      _findCurrentMatch = 0;
    });
    _findController.clear();
  }

  void _onFindQueryChanged() {
    final query = _findController.text;
    if (query.isEmpty) {
      setState(() {
        _findMatchLines = [];
        _findCurrentMatch = 0;
      });
      return;
    }

    final buffer = widget.plugin.terminal.buffer;
    final lowerQuery = query.toLowerCase();
    final matches = <int>[];

    for (var i = 0; i < buffer.height; i++) {
      final lineText = buffer.getText(
        BufferRangeLine(
          CellOffset(0, i),
          CellOffset(buffer.viewWidth - 1, i),
        ),
      );
      if (lineText.toLowerCase().contains(lowerQuery)) {
        matches.add(i);
      }
    }

    setState(() {
      _findMatchLines = matches;
      _findCurrentMatch = matches.isEmpty ? 0 : matches.length - 1;
    });

    if (matches.isNotEmpty) {
      _scrollToMatch(matches.last);
    }
  }

  void _findNext() {
    if (_findMatchLines.isEmpty) return;
    setState(() {
      _findCurrentMatch = (_findCurrentMatch + 1) % _findMatchLines.length;
    });
    _scrollToMatch(_findMatchLines[_findCurrentMatch]);
  }

  void _findPrevious() {
    if (_findMatchLines.isEmpty) return;
    setState(() {
      _findCurrentMatch = (_findCurrentMatch - 1 + _findMatchLines.length) %
          _findMatchLines.length;
    });
    _scrollToMatch(_findMatchLines[_findCurrentMatch]);
  }

  void _scrollToMatch(int bufferLine) {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final maxExtent = pos.maxScrollExtent;
    if (maxExtent <= 0) return;

    final buffer = widget.plugin.terminal.buffer;
    final scrollableLines = buffer.height - widget.plugin.terminal.viewHeight;
    if (scrollableLines <= 0) return;

    final targetPixels = (bufferLine / scrollableLines) * maxExtent;
    _scrollController.jumpTo(targetPixels.clamp(0.0, maxExtent));
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (!mounted) return false;

    final isModActive = HardwareKeyboard.instance.logicalKeysPressed.any(
      (key) => io.Platform.isMacOS
          ? key == LogicalKeyboardKey.metaLeft ||
              key == LogicalKeyboardKey.metaRight
          : key == LogicalKeyboardKey.controlLeft ||
              key == LogicalKeyboardKey.controlRight,
    );
    if (isModActive != _openModifierActive) {
      setState(() => _openModifierActive = isModActive);
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return false;
    }

    final findActivator = _currentKeymap[ShortcutId.findInTerminal];
    if (findActivator != null &&
        findActivator.accepts(event, HardwareKeyboard.instance)) {
      if (_findVisible) {
        _closeFind();
      } else {
        _openFind();
      }
      return true;
    }

    if (_findVisible &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        event is KeyDownEvent) {
      _closeFind();
      return true;
    }

    for (final entry in _passthroughIntents.entries) {
      final activator = _currentKeymap[entry.key];
      if (activator != null &&
          activator.accepts(event, HardwareKeyboard.instance)) {
        Actions.invoke(context, entry.value);
        return true;
      }
    }

    return false;
  }

  void _handleTapUp(TapUpDetails _, CellOffset cellOffset) {
    _logger.d(
      'onTapUp cell=(${cellOffset.x},${cellOffset.y}) modActive=$_openModifierActive',
    );
    if (!_openModifierActive) return;

    final plugin = widget.plugin;
    final buffer = plugin.terminal.buffer;
    final safeY = cellOffset.y.clamp(0, buffer.lines.length - 1);

    _logger.d(
        'buffer: lines=${buffer.lines.length} viewWidth=${buffer.viewWidth} viewHeight=${plugin.terminal.viewHeight} safeY=$safeY');

    final lineText = buffer.getText(
      BufferRangeLine(
        CellOffset(0, safeY),
        CellOffset(buffer.viewWidth - 1, safeY),
      ),
    );

    _logger.d('lineText: "${lineText.trimRight()}"');

    final target = LinkDetector.detectAt(lineText, cellOffset.x);
    _logger.d('target: $target');
    if (target == null) return;

    LauncherService.open(target);
  }

  @override
  Widget build(BuildContext context) {
    _currentKeymap = ref.watch(keymapProvider).value ?? defaultKeymaps;

    final settingsAsync = ref.watch(settingsProvider);
    final connStatus = ref
        .watch(connectorStatusProvider(widget.plugin.hostSpec))
        .value
        ?.status;
    final isDisconnected = connStatus == HostConnectorStatus.disconnected;

    return settingsAsync.when(
      data: (settings) {
        final fontFamily = settings.terminalFontFamily?.isNotEmpty == true
            ? settings.terminalFontFamily!
            : 'Hack Nerd Font Mono';

        final style = TerminalStyle(
          fontSize: settings.terminalFontSize,
          fontFamily: fontFamily,
        );

        return CupertinoPageScaffold(
          key: ValueKey(widget.plugin),
          backgroundColor: Colors.transparent,
          child: SafeArea(
            child: Stack(
              children: [
                TerminalView(
                  widget.plugin.terminal,
                  focusNode: _terminalFocus,
                  textStyle: style,
                  controller: widget.plugin.terminalController,
                  scrollController: _scrollController,
                  onTapUp: _handleTapUp,
                  onSecondaryTapDown: (_, __) => showMenu(),
                  onPaste: widget.plugin.paste,
                  mouseCursor: _openModifierActive
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.text,
                  backgroundOpacity: settings.backgroundOpacity,
                  padding: EdgeInsets.all(settings.padding),
                  autofocus: true,
                ),
                _InlineImageOverlay(
                  terminal: widget.plugin.terminal,
                  images: widget.plugin.inlineImages,
                  padding: settings.padding,
                ),
                if (_findVisible)
                  _FindBar(
                    controller: _findController,
                    focusNode: _findFocus,
                    matchCount: _findMatchLines.length,
                    currentMatch: _findCurrentMatch,
                    onNext: _findNext,
                    onPrevious: _findPrevious,
                    onClose: _closeFind,
                  ),
                if (isDisconnected) _ReconnectOverlay(plugin: widget.plugin),
              ],
            ),
          ),
        );
      },
      loading: () => const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (error, stack) => CupertinoPageScaffold(
        child: Center(child: Text('Error: $error')),
      ),
    );
  }

  void showMenu() {
    final plugin = widget.plugin;
    final menu = TerminalContextMenu(
      plugin: plugin,
      onOpenFind: _openFind,
      onToggleRecording: () async {
        if (plugin.isRecording) {
          await plugin.stopRecording();
        } else {
          final path = await plugin.startRecording();
          if (path.isNotEmpty && mounted) {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(
                content: Text('Recording started: $path'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
      onToggleBroadcast: () {
        final bs = BroadcastService.instance;
        if (bs.isParticipant(plugin)) {
          bs.deregister(plugin);
        } else {
          bs.register(plugin);
        }
      },
    );
    context.contextMenuOverlay.show(menu);
  }
}

class _FindBar extends StatelessWidget {
  const _FindBar({
    required this.controller,
    required this.focusNode,
    required this.matchCount,
    required this.currentMatch,
    required this.onNext,
    required this.onPrevious,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int matchCount;
  final int currentMatch;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned(
      top: 0,
      right: 0,
      child: Material(
        elevation: 4,
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Find...',
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onSubmitted: (_) => onNext(),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                matchCount == 0
                    ? 'No results'
                    : '${currentMatch + 1} / $matchCount',
                style: const TextStyle(fontSize: 12),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                onPressed: matchCount > 0 ? onPrevious : null,
                tooltip: 'Previous',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                onPressed: matchCount > 0 ? onNext : null,
                tooltip: 'Next',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClose,
                tooltip: 'Close',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReconnectOverlay extends ConsumerWidget {
  const _ReconnectOverlay({required this.plugin});

  final TerminalPlugin plugin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: Colors.black45,
      child: Center(
        child: Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link_off, size: 40),
                const SizedBox(height: 12),
                const Text('Session disconnected',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reconnect'),
                  onPressed: () {
                    ref.read(connectorProvider(plugin.hostSpec)).connect();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineImageOverlay extends StatelessWidget {
  const _InlineImageOverlay({
    required this.terminal,
    required this.images,
    required this.padding,
  });

  final Terminal terminal;
  final ValueNotifier<List<InlineImageEntry>> images;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: images,
      builder: (context, entries, _) {
        if (entries.isEmpty) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            final viewWidth = terminal.viewWidth;
            final viewHeight = terminal.viewHeight;
            final innerWidth = constraints.maxWidth - padding * 2;
            final innerHeight = constraints.maxHeight - padding * 2;
            final cellWidth = innerWidth / viewWidth;
            final cellHeight = innerHeight / viewHeight;

            return Stack(
              children: [
                for (final entry in entries)
                  Positioned(
                    left: padding + entry.col * cellWidth,
                    top: padding + entry.row * cellHeight,
                    width: (entry.widthCells ?? (viewWidth - entry.col)) *
                        cellWidth,
                    height: (entry.heightCells ?? (viewHeight - entry.row)) *
                        cellHeight,
                    child: Image.memory(
                      entry.bytes,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
