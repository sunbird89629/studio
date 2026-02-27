import 'dart:async';
import 'dart:convert';
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
        TextField,
        Theme;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/conn.dart';
import 'package:terminal_studio/src/core/host.dart';
import 'package:terminal_studio/src/core/model/shell_command_event.dart';
import 'package:terminal_studio/src/core/model/terminal_session.dart';
import 'package:terminal_studio/src/core/plugin.dart';
import 'package:terminal_studio/src/core/service/broadcast_service.dart';
import 'package:terminal_studio/src/core/service/launcher_service.dart';
import 'package:terminal_studio/src/core/service/terminal_event_bus.dart';
import 'package:terminal_studio/src/core/state/host.dart';
import 'package:terminal_studio/src/core/state/keymap.dart';
import 'package:terminal_studio/src/core/state/settings.dart';
import 'package:terminal_studio/src/core/state/terminal_activity.dart';
import 'package:terminal_studio/src/core/utils/link_detector.dart';
import 'package:terminal_studio/src/core/utils/osc_parser.dart';
import 'package:terminal_studio/src/plugins/terminal/inline_image.dart';
import 'package:terminal_studio/src/plugins/terminal/terminal_input_tracker.dart';
import 'package:terminal_studio/src/plugins/terminal/terminal_menu.dart';
import 'package:terminal_studio/src/plugins/terminal/xterm_fixes.dart';
import 'package:terminal_studio/src/ui/shortcut/intents.dart';
import 'package:terminal_studio/src/ui/shortcuts.dart';
import 'package:terminal_studio/src/util/uuid.dart';
import 'package:xterm/xterm.dart';

import '../../core/log/app_logger.dart';

class TerminalPlugin extends Plugin {
  late final Terminal terminal;
  late final String sessionId;

  final terminalController = TerminalController();

  final _logger = AppLogger.forComponent('TerminalPlugin');

  var terminalTitle = '';

  /// Inline images received via OSC 1337 (iTerm2 Inline Image Protocol).
  final inlineImages = ValueNotifier<List<InlineImageEntry>>([]);

  /// Current activity state of this terminal session.
  /// Observed by the vertical tab rail to show per-tab status.
  final activityState = ValueNotifier<TerminalActivityState>(
    TerminalActivityState.disconnected,
  );

  /// The last command that started executing (captured at CommandExecute).
  /// Shown in the tab rail while the terminal is in [TerminalActivityState.running]
  /// or [TerminalActivityState.attention] state.
  String lastCommand = '';

  bool _wasUsingAltBuffer = false;

  /// True after [notifyListeners] has fired at least once since the last image
  /// was stored. Used to avoid clearing an image the moment it arrives.
  bool _imageFullyRendered = false;

  ExecutionSession? session;
  StreamSubscription<String>? _outputSubscription;

  final _inputTracker = TerminalInputTracker();

  String get currentInput => _inputTracker.currentInput;
  List<String> get commandHistory => _inputTracker.commandHistory;

  // ── Asciinema recording ────────────────────────────────────────────────────
  io.IOSink? _castSink;
  DateTime? _recordingStart;

  Timer? _titleDebounce;

  bool get isRecording => _castSink != null;

  Future<String> startRecording() async {
    if (isRecording) return '';
    final dir = io.Directory(
      io.Platform.isWindows
          ? '${io.Platform.environment['USERPROFILE']}\\Documents\\TerminalStudio'
          : '${io.Platform.environment['HOME']}/Documents/TerminalStudio',
    );
    if (!await dir.exists()) await dir.create(recursive: true);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/recording_$timestamp.cast';
    final sink = io.File(path).openWrite();
    try {
      _recordingStart = DateTime.now();
      // Write asciinema v2 header
      sink.writeln(jsonEncode({
        'version': 2,
        'width': terminal.viewWidth,
        'height': terminal.viewHeight,
        'timestamp': _recordingStart!.millisecondsSinceEpoch ~/ 1000,
        'title': terminalTitle.isEmpty ? 'Terminal Recording' : terminalTitle,
      }));
      _castSink = sink;
    } catch (e) {
      await sink.close();
      _recordingStart = null;
      rethrow;
    }

    _logger.i('Asciinema recording started: $path');
    return path;
  }

  Future<void> stopRecording() async {
    if (!isRecording) return;
    await _castSink!.flush();
    await _castSink!.close();
    _castSink = null;
    _recordingStart = null;
    _logger.i('Asciinema recording stopped');
  }

  void _cleanupSession() {
    _outputSubscription?.cancel();
    _outputSubscription = null;
    session = null;
    activityState.value = TerminalActivityState.disconnected;
  }

  void _recordOutput(String data) {
    if (!isRecording) return;
    final elapsed =
        DateTime.now().difference(_recordingStart!).inMicroseconds / 1e6;
    _castSink!.writeln(jsonEncode([elapsed, 'o', data]));
  }

  void _updateTitle() {
    _titleDebounce?.cancel();
    _titleDebounce = Timer(const Duration(milliseconds: 100), () {
      if (session != null) {
        title.value =
            '$terminalTitle — ${terminal.viewWidth}x${terminal.viewHeight}';
      }
    });
  }

  @override
  void onMounted() {
    sessionId = uuidV4();
    title.addListener(() {
      _logger.d("title:${title.value}");
    });
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

    terminal.onPrivateOSC = _handlePrivateOSC;
    terminal.onEraseDisplay = _onEraseDisplay;
    terminal.onWriteChar = _onWriteChar;
    terminal.addListener(_onTerminalChange);

    terminal.onOutput = (data) {
      _logger.d('Terminal input (user typed): ${data.length} chars');
      session?.write(const Utf8Encoder().convert(data));
      _trackInput(data);
      BroadcastService.instance.broadcast(this, data);
    };

    terminal.onResize = (w, h, pw, ph) {
      session?.resize(w, h);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _updateTitle();
      });
    };

    super.onMounted();
  }

  @override
  void onConnected() async {
    title.value = 'Terminal';
    _logger.i('TerminalPlugin connected. requesting shell...');

    // Cancel any subscription from a previous connection (reconnect scenario).
    _cleanupSession();

    // Read user settings for shell configuration
    final settings = ref.read(settingsProvider).value;

    // Inject TERM_PROGRAM=iTerm.app so apps like yazi detect iTerm2 inline
    // image support. User env takes precedence over this default.
    final environment = {
      'TERM_PROGRAM': 'iTerm.app',
      ...?settings?.env,
    };

    session = await host.shell(
      width: terminal.viewWidth,
      height: terminal.viewHeight,
      command: settings?.shell,
      args: settings?.shellArgs,
      workingDirectory: settings?.workingDirectory,
      environment: environment,
    );

    _logger.i('Shell session created: $session');
    activityState.value = TerminalActivityState.idle;

    _outputSubscription =
        session!.output.cast<List<int>>().transform(const Utf8Decoder()).listen(
      (raw) {
        _logger.d('Terminal received output: ${raw.length} chars');

        // Detect BEL character — signals that a process is requesting attention
        // (e.g. Claude Code waiting for user confirmation).
        if (raw.contains('\x07')) {
          activityState.value = TerminalActivityState.attention;
        }

        // 1. Strip OSC 133 sequences and extract shell lifecycle events.
        final result = OscParser.parse(raw);

        // 2. Write clean data to xterm for rendering.
        terminal.write(result.cleanData);

        // 3. Broadcast clean data with session context to all consumers.
        ref.read(terminalEventBusProvider).emitOutput(
              sessionId: sessionId,
              data: result.cleanData,
            );

        // 4. Record output for Asciinema if recording.
        _recordOutput(result.cleanData);

        // 5. Handle shell integration events (e.g. command done).
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
      _cleanupSession();
      if (mounted) {
        manager.remove(this);
      }
    });
  }

  void _handleShellEvent(ShellCommandEvent event) {
    switch (event) {
      case CommandExecute():
        lastCommand = _inputTracker.currentInput.trim();
        activityState.value = TerminalActivityState.running;
      case CommandStart():
        activityState.value = TerminalActivityState.idle;
      case CommandDone(:final exitCode):
        _logger.d('Shell command done, exitCode=$exitCode');
        activityState.value = TerminalActivityState.idle;
      case PromptStart():
        break;
    }
  }

  void _trackInput(String data) {
    _inputTracker.track(data);
  }

  /// Handles the iTerm2 Inline Image Protocol (OSC 1337).
  ///
  /// Format: `ESC ] 1337 ; File=[inline=1;width=N;height=N;...] : <base64> BEL`
  void _handlePrivateOSC(String code, List<String> args) {
    if (code != '1337') return;

    // Reconstruct full arg string from semicolon-split parts.
    final fullArgs = args.join(';');

    // Strip "File=" prefix if present (iTerm2 convention).
    final argsPart =
        fullArgs.startsWith('File=') ? fullArgs.substring(5) : fullArgs;

    // Split params from base64 data on the first ':'.
    final colonIdx = argsPart.indexOf(':');
    if (colonIdx == -1) return;

    final paramsStr = argsPart.substring(0, colonIdx);
    final base64Str = argsPart.substring(colonIdx + 1);
    if (base64Str.isEmpty) return;

    // Parse key=value pairs.
    final params = <String, String>{};
    for (final kv in paramsStr.split(';')) {
      final eqIdx = kv.indexOf('=');
      if (eqIdx == -1) continue;
      params[kv.substring(0, eqIdx)] = kv.substring(eqIdx + 1);
    }

    if (params['inline'] != '1') return;

    // Decode image bytes.
    final Uint8List bytes;
    try {
      bytes = base64Decode(base64Str);
    } catch (e) {
      _logger.w('OSC 1337: failed to decode base64 image', error: e);
      return;
    }

    final widthCells = int.tryParse(params['width'] ?? '');
    final heightCells = int.tryParse(params['height'] ?? '');

    // Cursor position at the time of the OSC is where the image should appear.
    final col = terminal.buffer.cursorX;
    final row = terminal.buffer.cursorY;

    // Replace any existing image — each yazi preview frame is a single image.
    _imageFullyRendered = false;
    inlineImages.value = [
      InlineImageEntry(
        bytes: bytes,
        col: col,
        row: row,
        widthCells: widthCells,
        heightCells: heightCells,
      ),
    ];
  }

  /// Clears inline images triggered by `ESC[2J` (full screen erase).
  void _onEraseDisplay() {
    if (inlineImages.value.isNotEmpty) {
      inlineImages.value = [];
    }
  }

  /// Clears inline images on alt → main buffer switch (TUI app exited).
  /// Also marks the image as fully rendered so [_onWriteChar] can start
  /// watching for overwrites.
  void _onTerminalChange() {
    final isAlt = terminal.isUsingAltBuffer;

    if (_wasUsingAltBuffer && !isAlt) {
      inlineImages.value = [];
      _imageFullyRendered = false;
      _wasUsingAltBuffer = isAlt;
      return;
    }
    _wasUsingAltBuffer = isAlt;

    // After notifyListeners fires, the image is displayed — allow onWriteChar
    // to start watching for overwrites.
    if (inlineImages.value.isNotEmpty) {
      _imageFullyRendered = true;
    }
  }

  /// Clears the image overlay when Ratatui overwrites any cell inside the
  /// image's bounding box. This handles the common case where yazi navigates
  /// to a file without a new image (e.g. a directory) — Ratatui writes new
  /// text characters into the preview pane, overwriting the image area.
  void _onWriteChar(int col, int row) {
    if (inlineImages.value.isEmpty || !_imageFullyRendered) return;

    for (final img in inlineImages.value) {
      final imgWidth = img.widthCells ?? (terminal.viewWidth - img.col);
      final imgHeight = img.heightCells ?? (terminal.viewHeight - img.row);
      if (row >= img.row &&
          row < img.row + imgHeight &&
          col >= img.col &&
          col < img.col + imgWidth) {
        inlineImages.value = [];
        _imageFullyRendered = false;
        return;
      }
    }
  }

  @override
  void onDisconnected() {
    _logger.i('TerminalPlugin disconnected');
    _cleanupSession();
    _inputTracker.reset();
    inlineImages.value = [];
    _imageFullyRendered = false;
    title.value = 'Disconnected';
    BroadcastService.instance.deregister(this);
    SessionManager.instance.get(sessionId)?.status = SessionStatus.disconnected;
  }

  @override
  void onUnmounted() {
    _titleDebounce?.cancel();
    terminal.removeListener(_onTerminalChange);
    _cleanupSession();
    inlineImages.dispose();
    activityState.dispose();
    BroadcastService.instance.deregister(this);
    SessionManager.instance.remove(sessionId);
    super.onUnmounted();
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

  final _logger = AppLogger.forComponent('TerminalTabView');

  Map<String, SingleActivator> _currentKeymap = defaultKeymaps;

  /// True while the Cmd (macOS) or Ctrl (Win/Linux) key is held.
  bool _openModifierActive = false;

  // ── Find bar state ──────────────────────────────────────────────────────────
  bool _findVisible = false;
  final _findController = TextEditingController();
  final _findFocus = FocusNode();
  List<int> _findMatchLines = [];
  int _findCurrentMatch = 0;

  /// Passed to [TerminalView] so we can programmatically scroll to matches.
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    _findController.addListener(_onFindQueryChanged);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
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

    // Compute pixel offset so that [bufferLine] is visible at the top.
    final targetPixels = (bufferLine / scrollableLines) * maxExtent;
    _scrollController.jumpTo(targetPixels.clamp(0.0, maxExtent));
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (!mounted) return false;

    // Track Cmd (macOS) / Ctrl (Win/Linux) for link-opening cursor and click.
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

    // Find shortcut: open find bar
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

    // Escape closes find bar
    if (_findVisible &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        event is KeyDownEvent) {
      _closeFind();
      return true;
    }

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

  void _handleTapUp(TapUpDetails _, CellOffset cellOffset) {
    _logger.d(
      'onTapUp cell=(${cellOffset.x},${cellOffset.y}) modActive=$_openModifierActive',
    );
    if (!_openModifierActive) return;

    final plugin = widget.plugin;
    final buffer = plugin.terminal.buffer;
    // CellOffset.y from onTapUp is buffer-absolute (accounts for scroll).
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
                  textStyle: style,
                  controller: widget.plugin.terminalController,
                  scrollController: _scrollController,
                  onTapUp: _handleTapUp,
                  onSecondaryTapDown: (_, __) => showMenu(),
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

/// Find bar overlaid at the top of the terminal view.
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

/// Semi-transparent overlay shown when the terminal session is disconnected.
/// Provides a button to reconnect without closing and reopening the tab.
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

/// Overlays inline images (from OSC 1337) on top of the terminal view.
///
/// Images are positioned by converting the cursor (col, row) at the time
/// of the OSC sequence into pixel coordinates based on cell size.
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
