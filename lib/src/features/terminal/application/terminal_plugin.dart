import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as p;
import 'package:super_clipboard/super_clipboard.dart';
import 'package:open_term/src/shared/utils/platform_utils.dart';
import 'package:open_term/src/platform/hosts/host_connector.dart';
import 'package:open_term/src/platform/hosts/host.dart';
import 'package:open_term/src/shared/models/shell_command_event.dart';
import 'package:open_term/src/shared/models/terminal_session.dart';
import 'package:open_term/src/platform/plugins/plugin_runtime.dart';
import 'package:open_term/src/features/terminal/presentation/terminal_tab_view.dart';
import 'package:open_term/src/features/terminal/runtime/terminal_runtime.dart';
import 'package:open_term/src/shared/state/broadcast_service.dart';
import 'package:open_term/src/shared/state/terminal_event_bus.dart';
import 'package:open_term/src/features/settings/application/settings_providers.dart';
import 'package:open_term/src/shared/state/terminal_activity_provider.dart';
import 'package:open_term/src/shared/utils/osc_parser.dart';
import 'package:open_term/src/features/terminal/application/inline_image.dart';
import 'package:open_term/src/features/terminal/application/terminal_input_tracker.dart';
import 'package:open_term/src/features/terminal/application/xterm_fixes.dart';
import 'package:open_term/src/shared/logging/app_logger.dart';
import 'package:open_term/src/shared/utils/uuid.dart';
import 'package:xterm/xterm.dart';

class TerminalPlugin extends Plugin implements TerminalRuntimeAccess {
  late final Terminal terminal;
  late final String sessionId;

  final terminalController = TerminalController();

  final _logger = AppLogger.forComponent('TerminalPlugin');

  @override
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

  @override
  ExecutionSession? session;
  StreamSubscription<String>? _outputSubscription;

  final _inputTracker = TerminalInputTracker();

  @override
  String get currentInput => _inputTracker.currentInput;

  @override
  List<String> get commandHistory => _inputTracker.commandHistory;

  // ── Clipboard paste ───────────────────────────────────────────────────────

  static const _imageFormats = [
    (Formats.png, 'png'),
    (Formats.jpeg, 'jpg'),
    (Formats.tiff, 'tiff'),
    (Formats.gif, 'gif'),
    (Formats.bmp, 'bmp'),
  ];

  Future<void> paste() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return;
    try {
      final reader = await clipboard.read();

      for (final (format, ext) in _imageFormats) {
        final bytes = await _readFileFormat(reader, format);
        if (bytes != null && bytes.isNotEmpty) {
          final path = await _saveImageBytes(bytes, ext);
          if (path != null) {
            terminal.paste(path);
            return;
          }
        }
      }

      final text = await reader.readValue(Formats.plainText);
      if (text != null) {
        terminal.paste(text);
      }
    } catch (e) {
      _logger.e('Failed to read clipboard', error: e);
    }
  }

  Future<Uint8List?> _readFileFormat(
      ClipboardReader reader, FileFormat format) {
    final c = Completer<Uint8List?>();
    final progress = reader.getFile(format, (file) async {
      try {
        c.complete(await file.readAll());
      } catch (e) {
        c.completeError(e);
      }
    }, onError: c.completeError);
    if (progress == null) c.complete(null);
    return c.future;
  }

  Future<String?> _saveImageBytes(Uint8List bytes, String ext) async {
    try {
      final home = platformHomeDirectory();
      if (home == null) return null;

      final dir = io.Directory(p.join(home, 'Pictures'));
      await dir.create(recursive: true);

      final now = DateTime.now();
      String pad(int v) => v.toString().padLeft(2, '0');
      final ts = '${now.year}${pad(now.month)}${pad(now.day)}'
          '_${pad(now.hour)}${pad(now.minute)}${pad(now.second)}';
      final file = io.File(p.join(dir.path, 'paste_$ts.$ext'));
      await file.writeAsBytes(bytes);

      _logger.i('Saved clipboard image: ${file.path}');
      return file.path;
    } catch (e) {
      _logger.e('Failed to save clipboard image', error: e);
      return null;
    }
  }

  // ── Asciinema recording ────────────────────────────────────────────────────
  io.IOSink? _castSink;
  DateTime? _recordingStart;

  Timer? _titleDebounce;

  bool get isRecording => _castSink != null;

  Future<String> startRecording() async {
    if (isRecording) return '';
    final home = platformHomeDirectory() ?? '.';
    final dir = io.Directory(
      io.Platform.isWindows
          ? '$home\\Documents\\OpenTerm'
          : '$home/Documents/OpenTerm',
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

  @override
  ValueListenable<TerminalActivityState> get activity => activityState;

  @override
  int get viewWidth => terminal.viewWidth;

  @override
  int get viewHeight => terminal.viewHeight;

  @override
  Future<void> writeInput(String text) async {
    terminal.textInput(text);
  }

  @override
  void writeBroadcast(Uint8List bytes) {
    session?.write(bytes);
  }
}
