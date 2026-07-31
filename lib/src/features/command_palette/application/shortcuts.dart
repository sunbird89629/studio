import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:open_term/src/shared/utils/target_platform.dart';

// ── Action IDs ─────────────────────────────────────

/// All recognized shortcut action IDs.
class ShortcutId {
  static const openSettings = 'open_settings';
  static const openDevTools = 'open_dev_tools';
  static const newWindow = 'new_window';
  static const newTab = 'new_tab';
  static const previousTab = 'previous_tab';
  static const nextTab = 'next_tab';
  static const closeTab = 'close_tab';
  static const terminalCopy = 'terminal_copy';
  static const terminalPaste = 'terminal_paste';
  static const terminalSelectAll = 'terminal_select_all';
  static const commandPalette = 'command_palette';
  static const vimEdit = 'vim_edit';
  static const findInTerminal = 'find_in_terminal';

  /// Human-readable label for each action ID.
  static const labels = <String, String>{
    openSettings: 'Open Settings',
    openDevTools: 'Open DevTools',
    newWindow: 'New Window',
    newTab: 'New Tab',
    previousTab: 'Previous Tab',
    nextTab: 'Next Tab',
    closeTab: 'Close Tab',
    terminalCopy: 'Copy',
    terminalPaste: 'Paste',
    terminalSelectAll: 'Select All',
    commandPalette: 'Command Palette',
    vimEdit: 'Vim Edit',
    findInTerminal: 'Find in Terminal',
  };

  static String label(String id) => labels[id] ?? id;
}

// ── Default Keymaps (Platform-aware) ───────────────

/// Platform-specific default keybindings.
Map<String, SingleActivator> get defaultKeymaps {
  final apple = defaultTargetPlatform.isApple;
  return <String, SingleActivator>{
    ShortcutId.openSettings: SingleActivator(
      LogicalKeyboardKey.comma,
      meta: apple,
      control: !apple,
    ),
    ShortcutId.openDevTools: const SingleActivator(LogicalKeyboardKey.f12),
    ShortcutId.newWindow: SingleActivator(
      LogicalKeyboardKey.keyN,
      meta: apple,
      control: !apple,
    ),
    ShortcutId.newTab: SingleActivator(
      LogicalKeyboardKey.keyT,
      meta: apple,
      control: !apple,
    ),
    ShortcutId.previousTab: apple
        ? const SingleActivator(LogicalKeyboardKey.bracketLeft, meta: true)
        : const SingleActivator(LogicalKeyboardKey.pageUp, control: true),
    ShortcutId.nextTab: apple
        ? const SingleActivator(LogicalKeyboardKey.bracketRight, meta: true)
        : const SingleActivator(LogicalKeyboardKey.pageDown, control: true),
    ShortcutId.closeTab: SingleActivator(
      LogicalKeyboardKey.keyW,
      meta: apple,
      control: !apple,
    ),
    ShortcutId.terminalCopy: SingleActivator(
      LogicalKeyboardKey.keyC,
      meta: apple,
      control: !apple,
      shift: !apple,
    ),
    ShortcutId.terminalPaste: SingleActivator(
      LogicalKeyboardKey.keyV,
      meta: apple,
      control: !apple,
      shift: !apple,
    ),
    ShortcutId.terminalSelectAll: SingleActivator(
      LogicalKeyboardKey.keyA,
      meta: apple,
      control: !apple,
      shift: !apple,
    ),
    ShortcutId.commandPalette: SingleActivator(
      LogicalKeyboardKey.keyP,
      meta: apple,
      control: !apple,
      shift: true,
    ),
    ShortcutId.vimEdit: SingleActivator(
      LogicalKeyboardKey.keyE,
      meta: apple,
      control: !apple,
      shift: true,
    ),
    ShortcutId.findInTerminal: SingleActivator(
      LogicalKeyboardKey.keyF,
      meta: apple,
      control: !apple,
    ),
  };
}

// ── String ↔ SingleActivator Parsing ───────────────

/// Key name → LogicalKeyboardKey lookup.
final _keyLookup = <String, LogicalKeyboardKey>{
  // Letters
  for (var i = 0; i < 26; i++)
    String.fromCharCode(0x61 + i): LogicalKeyboardKey(0x00000000061 + i),
  // Digits
  for (var i = 0; i < 10; i++) '$i': LogicalKeyboardKey(0x00000000030 + i),
  // Special keys
  ',': LogicalKeyboardKey.comma,
  '.': LogicalKeyboardKey.period,
  '/': LogicalKeyboardKey.slash,
  ';': LogicalKeyboardKey.semicolon,
  "'": LogicalKeyboardKey.quote,
  '[': LogicalKeyboardKey.bracketLeft,
  ']': LogicalKeyboardKey.bracketRight,
  '\\': LogicalKeyboardKey.backslash,
  '-': LogicalKeyboardKey.minus,
  '=': LogicalKeyboardKey.equal,
  '`': LogicalKeyboardKey.backquote,
  'space': LogicalKeyboardKey.space,
  'enter': LogicalKeyboardKey.enter,
  'tab': LogicalKeyboardKey.tab,
  'escape': LogicalKeyboardKey.escape,
  'esc': LogicalKeyboardKey.escape,
  'backspace': LogicalKeyboardKey.backspace,
  'delete': LogicalKeyboardKey.delete,
  'up': LogicalKeyboardKey.arrowUp,
  'down': LogicalKeyboardKey.arrowDown,
  'left': LogicalKeyboardKey.arrowLeft,
  'right': LogicalKeyboardKey.arrowRight,
  'home': LogicalKeyboardKey.home,
  'end': LogicalKeyboardKey.end,
  'pageup': LogicalKeyboardKey.pageUp,
  'pagedown': LogicalKeyboardKey.pageDown,
  'f1': LogicalKeyboardKey.f1,
  'f2': LogicalKeyboardKey.f2,
  'f3': LogicalKeyboardKey.f3,
  'f4': LogicalKeyboardKey.f4,
  'f5': LogicalKeyboardKey.f5,
  'f6': LogicalKeyboardKey.f6,
  'f7': LogicalKeyboardKey.f7,
  'f8': LogicalKeyboardKey.f8,
  'f9': LogicalKeyboardKey.f9,
  'f10': LogicalKeyboardKey.f10,
  'f11': LogicalKeyboardKey.f11,
  'f12': LogicalKeyboardKey.f12,
};

/// Reverse lookup: LogicalKeyboardKey → string name.
final _keyReverseLookup = <int, String>{
  for (final e in _keyLookup.entries) e.value.keyId: e.key,
};

/// Parse a string like "cmd+shift+t" into a [SingleActivator].
/// Returns null if the string is malformed.
SingleActivator? parseShortcutString(String shortcut) {
  final parts = shortcut.toLowerCase().split('+').map((s) => s.trim()).toList();
  if (parts.isEmpty) return null;

  var meta = false;
  var control = false;
  var shift = false;
  var alt = false;
  LogicalKeyboardKey? key;

  for (final part in parts) {
    switch (part) {
      case 'cmd':
      case 'meta':
      case 'command':
      case '⌘':
        meta = true;
      case 'ctrl':
      case 'control':
        control = true;
      case 'shift':
      case '⇧':
        shift = true;
      case 'alt':
      case 'option':
      case 'opt':
      case '⌥':
        alt = true;
      default:
        key = _keyLookup[part];
        if (key == null) return null; // Unknown key
    }
  }

  if (key == null) return null;

  return SingleActivator(
    key,
    meta: meta,
    control: control,
    shift: shift,
    alt: alt,
  );
}

/// Serialize a [SingleActivator] to a human-readable string.
String activatorToString(SingleActivator activator) {
  final parts = <String>[];
  if (activator.meta) parts.add('cmd');
  if (activator.control) parts.add('ctrl');
  if (activator.alt) parts.add('alt');
  if (activator.shift) parts.add('shift');

  final keyName =
      _keyReverseLookup[activator.trigger.keyId] ?? activator.trigger.keyLabel;
  parts.add(keyName);
  return parts.join('+');
}

/// Parse user keymap overrides from string map to SingleActivator map.
Map<String, SingleActivator> parseUserKeymaps(Map<String, String> bindings) {
  final result = <String, SingleActivator>{};
  for (final entry in bindings.entries) {
    final activator = parseShortcutString(entry.value);
    if (activator != null) {
      result[entry.key] = activator;
    }
  }
  return result;
}

// ── Display Formatting ────────────────────────────

/// Format a [SingleActivator] as a human-readable string with symbols (⌘/Ctrl/⌥/⇧).
String formatActivator(SingleActivator a) {
  final parts = <String>[];
  if (a.meta) parts.add('⌘');
  if (a.control) parts.add('Ctrl');
  if (a.alt) parts.add('⌥');
  if (a.shift) parts.add('⇧');
  parts.add(a.trigger.keyLabel);
  return parts.join(' + ');
}
