import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:terminal_studio/src/core/host.dart';
import 'package:terminal_studio/src/hosts/local_host.dart';
import 'package:xterm/xterm.dart';
import '../utils/ai_logger.dart';

class VimEditState {
  final bool isVisible;
  final Terminal terminal;
  final TerminalController terminalController;

  const VimEditState({
    required this.isVisible,
    required this.terminal,
    required this.terminalController,
  });

  factory VimEditState.initial() {
    return VimEditState(
      isVisible: false,
      terminal: Terminal(maxLines: 10000),
      terminalController: TerminalController(),
    );
  }

  VimEditState copyWith({
    bool? isVisible,
    Terminal? terminal,
    TerminalController? terminalController,
  }) {
    return VimEditState(
      isVisible: isVisible ?? this.isVisible,
      terminal: terminal ?? this.terminal,
      terminalController: terminalController ?? this.terminalController,
    );
  }
}

class VimEditNotifier extends Notifier<VimEditState> {
  ExecutionSession? _session;
  File? _tempFile;
  bool _isExiting = false;

  final _logger =
      AILogger(context: const LogContext(component: 'VimEditNotifier'));

  @override
  VimEditState build() {
    return VimEditState.initial();
  }

  Future<void> open() async {
    if (state.isVisible) return;

    _isExiting = false;

    try {
      // 1. Create fresh terminal for each session
      final terminal = Terminal(maxLines: 10000);
      final controller = TerminalController();
      state = state.copyWith(terminal: terminal, terminalController: controller);

      // 2. Create temp file
      final tempDir = Directory.systemTemp;
      _tempFile = File(
        p.join(
          tempDir.path,
          'vim_edit_${DateTime.now().millisecondsSinceEpoch}.txt',
        ),
      );
      await _tempFile!.create();

      // 3. Start nvim session
      final host = LocalHost();
      // TODO: In the future, we might want to use the active tab's host if we want to run nvim on a remote server

      _logger.i('Starting nvim on ${_tempFile!.path}');

      _session = await host.shell(
        width: 80,
        height: 24,
        command: 'nvim',
        args: [_tempFile!.path],
      );

      // 4. Connect session to terminal
      terminal.onOutput = (data) {
        _session?.write(const Utf8Encoder().convert(data));
      };

      terminal.onResize = (w, h, pw, ph) {
        _session?.resize(w, h);
      };

      _session!.output.cast<List<int>>().transform(const Utf8Decoder()).listen(
          (data) {
            terminal.write(data);
          },
          onDone: _onSessionExit,
          onError: (e) {
            _logger.e('Vim session error', error: e);
            _onSessionExit();
          });

      _session!.exitCode.then((_) => _onSessionExit());

      state = state.copyWith(isVisible: true);
    } catch (e) {
      _logger.e('Failed to open vim edit mode', error: e);
    }
  }

  void _onSessionExit() async {
    if (_isExiting) return;
    _isExiting = true;

    _logger.i('Vim session exited');

    // 1. Clean up terminal callbacks
    state.terminal.onOutput = null;
    state.terminal.onResize = null;

    // 2. Read file content and copy to clipboard
    if (_tempFile != null && await _tempFile!.exists()) {
      try {
        final content = await _tempFile!.readAsString();
        if (content.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: content));
          _logger.i('Content copied to clipboard (${content.length} chars)');
        }
      } catch (e) {
        _logger.e('Failed to read temp file', error: e);
      } finally {
        try {
          await _tempFile!.delete();
        } catch (_) {}
        _tempFile = null;
      }
    }

    _session = null;

    // Setting isVisible to false triggers the dialog to pop via ref.listen in _VimEditDialog.
    // Navigator handles focus restoration automatically.
    state = state.copyWith(isVisible: false);
  }

  void close() {
    _session?.close();
  }
}

final vimEditServiceProvider =
    NotifierProvider<VimEditNotifier, VimEditState>(VimEditNotifier.new);
