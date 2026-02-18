import 'dart:convert';

import 'package:context_menus/context_menus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/conn.dart';
import 'package:terminal_studio/src/core/host.dart';
import 'package:terminal_studio/src/core/plugin.dart';
import 'package:terminal_studio/src/core/service/remote_control_service.dart';
import 'package:terminal_studio/src/core/state/settings.dart';
import 'package:terminal_studio/src/plugins/terminal/terminal_menu.dart';
import 'package:terminal_studio/src/plugins/terminal/xterm_fixes.dart'; // NEW
import 'package:terminal_studio/src/ui/shortcut/intents.dart';
import 'package:terminal_studio/src/ui/shortcuts.dart' as shortcuts;
import 'package:xterm/xterm.dart';
import '../../core/utils/ai_logger.dart';

class TerminalPlugin extends Plugin {
  late final Terminal terminal;

  final terminalController = TerminalController();

  final _logger =
      AILogger(context: const LogContext(component: 'TerminalPlugin'));

  var terminalTitle = '';

  ExecutionSession? session;

  void _updateTitle() {
    if (session != null) {
      title.value =
          '$terminalTitle — ${terminal.viewWidth}x${terminal.viewHeight}';
    }
  }

  @override
  void didMounted() {
    // Read scrollback from settings (fallback to 10000)
    final settings = ref.read(settingsProvider).value;
    final scrollback = settings?.scrollback ?? 10000;
    terminal = Terminal(
      maxLines: scrollback,
      inputHandler: fixedDefaultInputHandler, // FIXED
      mouseHandler: fixedDefaultMouseHandler, // FIXED
    );

    title.value = 'Connecting';

    terminal.onTitleChange = (title) {
      terminalTitle = title;
      _updateTitle();
    };

    terminal.onOutput = (data) {
      _logger.d('Terminal input (user typed): ${data.length} chars');
      session?.write(const Utf8Encoder().convert(data));
    };

    terminal.onResize = (w, h, pw, ph) {
      session?.resize(w, h);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _updateTitle();
      });
    };

    super.didMounted();
  }

  @override
  void didConnected() async {
    title.value = 'Terminal';
    _logger.i('TerminalPlugin connected. requesting shell...');

    // Read user settings for shell configuration
    final settings = ref.read(settingsProvider).value;

    session = await host.shell(
      width: terminal.viewWidth,
      height: terminal.viewHeight,
      command: settings?.shell,
      args: settings?.shellArgs,
      workingDirectory: settings?.workingDirectory,
      environment: settings?.env,
    );

    _logger.i('Shell session created: $session');

    session!.output.cast<List<int>>().transform(const Utf8Decoder()).listen(
        (data) {
      _logger.d('Terminal received output: ${data.length} chars');
      terminal.write(data);

      // Broadcast to remote control clients
      ref
          .read(remoteControlServiceProvider.notifier)
          .broadcastTerminalOutput(data);
    }, onError: (e) {
      _logger.e('Terminal session error', error: e);
    }, onDone: () {
      _logger.i('Terminal session done');
    });

    session!.exitCode.then((code) {
      _logger.i('Terminal session exited with code: $code');
      session = null;
      if (mounted) {
        manager.remove(this);
      }
    });
  }

  @override
  void didDisconnected() {
    _logger.i('TerminalPlugin disconnected');
    session = null;
    title.value = 'Disconnected';
  }

  @override
  void onConnectionStatus(HostConnectorStatus status) {
    switch (status) {
      case HostConnectorStatus.connecting:
        title.value = 'Connecting';
        break;
      case HostConnectorStatus.connected:
        title.value = 'Terminal';
        break;
      case HostConnectorStatus.disconnected:
        title.value = 'Disconnected';
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return TerminalTabView(this);
  }
}

class TerminalTabView extends ConsumerStatefulWidget {
  const TerminalTabView(this.plugin, {super.key});

  final TerminalPlugin plugin;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _TerminalTabViewState();
}

class _TerminalTabViewState extends ConsumerState<TerminalTabView> {
  // Map of shortcut activators to their corresponding intents
  static final List<(SingleActivator, Intent)> _passthroughShortcuts = [
    (shortcuts.previousTab, const PreviousTabIntent()),
    (shortcuts.nextTab, const NextTabIntent()),
  ];

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    super.dispose();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return false;
    }

    // Only handle if this terminal tab is mounted and active
    if (!mounted) return false;

    // Check if any of our passthrough shortcuts match
    for (final (activator, intent) in _passthroughShortcuts) {
      if (activator.accepts(event, HardwareKeyboard.instance)) {
        // Invoke the action through the Actions widget
        Actions.invoke(context, intent);
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

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
            child:
                // ClipRect(
                //   child: AnimatedCursorTerminalView(
                //     terminal: widget.plugin.terminal,
                //     textStyle: style,
                //     controller: widget.plugin.terminalController,
                //     onSecondaryTapDown: (_, __) => showMenu(),
                //     backgroundOpacity: 0.8,
                //     autofocus: true,
                //   ),
                // ),
                TerminalView(
              widget.plugin.terminal,
              textStyle: style,
              controller: widget.plugin.terminalController,
              onSecondaryTapDown: (_, __) => showMenu(),
              backgroundOpacity: settings.backgroundOpacity,
              padding: EdgeInsets.all(settings.padding),
              autofocus: true,
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
    final menu = TerminalContextMenu(plugin: widget.plugin);
    context.contextMenuOverlay.show(menu);
  }
}
