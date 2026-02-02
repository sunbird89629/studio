import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:terminal_studio/src/core/host.dart';
import 'package:terminal_studio/src/hosts/local_host.dart';
import 'package:xterm/xterm.dart';

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

  @override
  VimEditState build() {
    return VimEditState.initial();
  }

  Future<void> open() async {
    if (state.isVisible) return;

    try {
      // 1. Create temp file
      final tempDir = Directory.systemTemp;
      _tempFile = File(p.join(tempDir.path,
          'vim_edit_${DateTime.now().millisecondsSinceEpoch}.txt'));
      await _tempFile!.create();

      // 2. Start nvim session
      final host = LocalHost(); // Use LocalHost directly for now
      // TODO: In the future, we might want to use the active tab's host if we want to run nvim on a remote server

      print('Starting nvim on ${_tempFile!.path}');

      // Reset terminal
      state.terminal.write('\r\nStarting nvim...\r\n');

      _session = await host.shell(
        width: 80, // Initial size, will be resized by TerminalView
        height: 24,
        command: 'nvim',
        args: [_tempFile!.path],
      );

      // 3. Connect session to terminal
      state.terminal.onOutput = (data) {
        _session?.write(const Utf8Encoder().convert(data));
      };

      state.terminal.onResize = (w, h, pw, ph) {
        _session?.resize(w, h);
      };

      _session!.output.cast<List<int>>().transform(const Utf8Decoder()).listen(
          (data) {
            state.terminal.write(data);
          },
          onDone: _onSessionExit,
          onError: (e) {
            print('Vim session error: $e');
            _onSessionExit();
          });

      _session!.exitCode.then((_) => _onSessionExit());

      state = state.copyWith(isVisible: true);
    } catch (e) {
      print('Failed to open vim edit mode: $e');
      // Show error handling?
    }
  }

  void _onSessionExit() async {
    if (!state.isVisible) return; // Already closed

    print('Vim session exited');

    // 1. Read file content
    if (_tempFile != null && await _tempFile!.exists()) {
      try {
        final content = await _tempFile!.readAsString();
        if (content.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: content));
          print('Content copied to clipboard (${content.length} chars)');
        }
      } catch (e) {
        print('Failed to read temp file: $e');
      } finally {
        // Cleanup
        try {
          await _tempFile!.delete();
        } catch (_) {}
        _tempFile = null;
      }
    }

    _session = null;

    // Clear terminal explicitly or re-create it?
    // state.terminal.buffer.clear(); // If xterm exposes this.
    // Simpler to just hide it. The next open will clear or append.

    state = state.copyWith(isVisible: false);
  }

  void close() {
    // Force close if needed, usually triggered by UI or session exit
    _session?.close();
  }
}

final vimEditServiceProvider =
    NotifierProvider<VimEditNotifier, VimEditState>(VimEditNotifier.new);
