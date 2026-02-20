import 'dart:async';
import 'dart:convert';

import 'package:context_menus/context_menus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/conn.dart';
import 'package:terminal_studio/src/core/host.dart';
import 'package:terminal_studio/src/core/model/shell_command_event.dart';
import 'package:terminal_studio/src/core/model/terminal_session.dart';
import 'package:terminal_studio/src/core/plugin.dart';
import 'package:terminal_studio/src/core/service/terminal_event_bus.dart';
import 'package:terminal_studio/src/core/state/settings.dart';
import 'package:terminal_studio/src/core/utils/osc_parser.dart';
import 'package:terminal_studio/src/plugins/terminal/terminal_menu.dart';
import 'package:terminal_studio/src/plugins/terminal/xterm_fixes.dart';
import 'package:terminal_studio/src/ui/shortcut/intents.dart';
import 'package:terminal_studio/src/core/state/keymap.dart';
import 'package:terminal_studio/src/ui/shortcuts.dart';
import 'package:terminal_studio/src/util/uuid.dart';
import 'package:xterm/xterm.dart';
import '../../core/utils/app_logger.dart';

class TerminalPlugin extends Plugin {
  late final Terminal terminal;
  late final String sessionId;

  final terminalController = TerminalController();

  final _logger = AppLogger.forComponent('TerminalPlugin');

  var terminalTitle = '';

  ExecutionSession? session;
  StreamSubscription<String>? _outputSubscription;

  String _currentInput = '';
  final List<String> _commandHistory = [];

  String get currentInput => _currentInput;
  List<String> get commandHistory => List.unmodifiable(_commandHistory);

  void _updateTitle() {
    if (session != null) {
      title.value =
          '$terminalTitle — ${terminal.viewWidth}x${terminal.viewHeight}';
    }
  }

  @override
  void didMounted() {
    sessionId = uuidV4();
    SessionManager.instance.register(TerminalSession(
      id: sessionId,
      hostSpec: hostSpec,
      createdAt: DateTime.now(),
    ));

    // Read scrollback from settings (fallback to 10000)
    final settings = ref.read(settingsProvider).value;
    final scrollback = settings?.scrollback ?? 10000;
    terminal = Terminal(
      maxLines: scrollback,
      inputHandler: fixedDefaultInputHandler,
      mouseHandler: fixedDefaultMouseHandler,
    );

    title.value = 'Connecting';

    terminal.onTitleChange = (title) {
      terminalTitle = title;
      _updateTitle();
    };

    terminal.onOutput = (data) {
      _logger.d('Terminal input (user typed): ${data.length} chars');
      session?.write(const Utf8Encoder().convert(data));
      _trackInput(data);
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

    // Cancel any subscription from a previous connection (reconnect scenario).
    _outputSubscription?.cancel();
    _outputSubscription = null;

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

    _outputSubscription = session!.output
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .listen(
      (raw) {
        _logger.d('Terminal received output: ${raw.length} chars');

        // 1. Strip OSC 133 sequences and extract shell lifecycle events.
        final result = OscParser.parse(raw);

        // 2. Write clean data to xterm for rendering.
        terminal.write(result.cleanData);

        // 3. Broadcast clean data with session context to all consumers.
        ref.read(terminalEventBusProvider).emitOutput(
          sessionId: sessionId,
          data: result.cleanData,
        );

        // 4. Handle shell integration events (e.g. command done).
        for (final event in result.events) {
          _handleShellEvent(event);
        }
      },
      onError: (e) => _logger.e('Terminal session error', error: e),
      onDone: () => _logger.i('Terminal session done'),
    );

    session!.exitCode.then((code) {
      _logger.i('Terminal session exited with code: $code');
      SessionManager.instance.markExited(sessionId, code);
      session = null;
      _outputSubscription = null;
      if (mounted) {
        manager.remove(this);
      }
    });
  }

  void _handleShellEvent(ShellCommandEvent event) {
    switch (event) {
      case CommandDone(:final exitCode):
        _logger.d('Shell command done, exitCode=$exitCode');
      default:
        break;
    }
  }

  void _trackInput(String data) {
    _currentInput = processInput(_currentInput, data, _commandHistory);
  }

  /// Pure function that advances the terminal input state machine for [data].
  ///
  /// [history] is mutated in-place when Enter is pressed (same as the instance
  /// method). Exposed as [visibleForTesting] so unit tests can exercise every
  /// control character without instantiating a full [TerminalPlugin].
  @visibleForTesting
  static String processInput(
      String current, String data, List<String> history) {
    var input = current;
    for (final char in data.runes) {
      if (char == 0x0D || char == 0x0A) {
        // Enter: commit current input to history
        final trimmed = input.trim();
        if (trimmed.isNotEmpty) {
          history.add(trimmed);
          if (history.length > 500) history.removeAt(0);
        }
        input = '';
      } else if (char == 0x7F || char == 0x08) {
        // Backspace / DEL
        if (input.isNotEmpty) {
          input = input.substring(0, input.length - 1);
        }
      } else if (char == 0x03 || char == 0x15 || char == 0x1B) {
        // Ctrl-C, Ctrl-U, ESC: clear line
        input = '';
      } else if (char == 0x17) {
        // Ctrl-W: remove last word
        input = input.trimRight();
        final lastSpace = input.lastIndexOf(' ');
        input = lastSpace == -1 ? '' : input.substring(0, lastSpace + 1);
      } else if (char >= 0x20 && char != 0x7F) {
        // Printable character
        input += String.fromCharCode(char);
      }
    }
    return input;
  }

  @override
  void didDisconnected() {
    _logger.i('TerminalPlugin disconnected');
    _outputSubscription?.cancel();
    _outputSubscription = null;
    session = null;
    _currentInput = '';
    title.value = 'Disconnected';
    SessionManager.instance.get(sessionId)?.status = SessionStatus.disconnected;
  }

  @override
  void didUnmounted() {
    _outputSubscription?.cancel();
    _outputSubscription = null;
    SessionManager.instance.remove(sessionId);
    super.didUnmounted();
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
  // ShortcutId → Intent mapping for shortcuts that should pass through xterm
  static const _passthroughIntents = <String, Intent>{
    ShortcutId.previousTab: PreviousTabIntent(),
    ShortcutId.nextTab: NextTabIntent(),
  };

  Map<String, SingleActivator> _currentKeymap = defaultKeymaps;

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

    // Check if any of our passthrough shortcuts match using current keymap
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

  @override
  Widget build(BuildContext context) {
    _currentKeymap = ref.watch(keymapProvider).value ?? defaultKeymaps;
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
            child: TerminalView(
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
