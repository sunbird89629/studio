import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_studio/src/plugins/terminal/terminal_input_tracker.dart';

// Convenience alias
String process(String current, String data, [List<String>? history]) =>
    TerminalInputTracker.processInput(current, data, history ?? []);

void main() {
  group('TerminalInputTracker.processInput – printable characters', () {
    test('appends printable ASCII', () {
      expect(process('', 'hello'), 'hello');
    });

    test('appends to existing input', () {
      expect(process('foo', ' bar'), 'foo bar');
    });

    test('DEL (0x7F) acts as backspace, removing the preceding character', () {
      // 0x7F triggers the backspace branch: 'a' added, then 'a' removed, then 'b' added
      expect(process('', 'a\x7Fb'), 'b');
    });

    test('ignores control chars below 0x20 (not otherwise handled)', () {
      // 0x01 (SOH) should be silently dropped
      expect(process('ab', '\x01'), 'ab');
    });
  });

  group('TerminalInputTracker.processInput – backspace', () {
    test('removes last character (DEL 0x7F)', () {
      expect(process('hello', '\x7F'), 'hell');
    });

    test('removes last character (BS 0x08)', () {
      expect(process('hello', '\x08'), 'hell');
    });

    test('backspace on empty string is a no-op', () {
      expect(process('', '\x7F'), '');
    });

    test('multiple backspaces', () {
      expect(process('abc', '\x7F\x7F'), 'a');
    });
  });

  group('TerminalInputTracker.processInput – line clear (Ctrl-C / Ctrl-U / ESC)', () {
    test('Ctrl-C clears current input', () {
      expect(process('hello', '\x03'), '');
    });

    test('Ctrl-U clears current input', () {
      expect(process('hello', '\x15'), '');
    });

    test('ESC clears current input', () {
      expect(process('hello', '\x1B'), '');
    });

    test('clear on empty input is a no-op', () {
      expect(process('', '\x03'), '');
    });
  });

  group('TerminalInputTracker.processInput – Ctrl-W (delete last word)', () {
    test('removes last word', () {
      expect(process('foo bar', '\x17'), 'foo ');
    });

    test('removes only word when there is no space', () {
      expect(process('hello', '\x17'), '');
    });

    test('handles trailing spaces before deleting word', () {
      expect(process('foo   ', '\x17'), '');
    });

    test('on empty input is a no-op', () {
      expect(process('', '\x17'), '');
    });
  });

  group('TerminalInputTracker.processInput – Enter (LF / CR)', () {
    test('LF clears input', () {
      expect(process('hello', '\n'), '');
    });

    test('CR clears input', () {
      expect(process('hello', '\r'), '');
    });

    test('Enter adds trimmed input to history', () {
      final history = <String>[];
      process('  git status  ', '\n', history);
      expect(history, ['git status']);
    });

    test('Enter with whitespace-only input does not add to history', () {
      final history = <String>[];
      process('   ', '\n', history);
      expect(history, isEmpty);
    });

    test('Enter on empty string does not add to history', () {
      final history = <String>[];
      process('', '\n', history);
      expect(history, isEmpty);
    });

    test('history is capped at 500 entries', () {
      final history = List.generate(500, (i) => 'cmd$i');
      process('extra', '\n', history);
      expect(history.length, 500);
      expect(history.last, 'extra');
      expect(history.first, 'cmd1'); // first entry dropped
    });
  });

  group('TerminalInputTracker.processInput – mixed sequences', () {
    test('type, backspace, type', () {
      var input = process('', 'helo');
      input = process(input, '\x7F'); // remove 'o'
      input = process(input, 'lo');
      expect(input, 'hello');
    });

    test('type command then Enter clears and records', () {
      final history = <String>[];
      var input = process('', 'ls -la', history);
      input = process(input, '\n', history);
      expect(input, '');
      expect(history, ['ls -la']);
    });

    test('Ctrl-C mid-word clears, subsequent typing works', () {
      var input = process('', 'git sta');
      input = process(input, '\x03');
      input = process(input, 'ls');
      expect(input, 'ls');
    });
  });
}
