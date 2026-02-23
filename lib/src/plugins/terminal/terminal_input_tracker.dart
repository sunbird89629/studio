import 'package:flutter/foundation.dart';

/// Tracks the current typed input and command history for a terminal session.
///
/// Parses raw byte-level input data (as Dart strings) and maintains:
/// - [currentInput]: best-effort snapshot of what the user is typing
/// - [commandHistory]: commands committed on Enter (capped at 500)
class TerminalInputTracker {
  String _currentInput = '';
  final List<String> _commandHistory = [];

  String get currentInput => _currentInput;
  List<String> get commandHistory => List.unmodifiable(_commandHistory);

  /// Process an incoming [data] string from the terminal's onOutput callback.
  void track(String data) {
    _currentInput = processInput(_currentInput, data, _commandHistory);
  }

  /// Reset current input (e.g. on disconnect).
  void reset() => _currentInput = '';

  /// Pure function that advances the terminal input state machine for [data].
  ///
  /// [history] is mutated in-place when Enter is pressed.
  /// Exposed as [visibleForTesting] so unit tests can exercise every
  /// control character without instantiating a full plugin.
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
}
