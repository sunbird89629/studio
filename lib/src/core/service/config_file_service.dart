import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:terminal_studio/src/core/record/profile_record.dart';
import 'package:terminal_studio/src/core/record/settings_record.dart';
import 'package:terminal_studio/src/core/record/snippet_record.dart';
import '../utils/app_logger.dart';

/// Service for reading/writing `~/.config/openterm/config.jsonc`.
class ConfigFileService {
  ConfigFileService();

  final _logger = AppLogger.forComponent('ConfigFileService');

  StreamSubscription<FileSystemEvent>? _watcher;

  /// Guard to prevent re-entrant writes triggered by file watcher.
  bool _isSyncing = false;

  /// Config directory: `~/.config/openterm/` (cross-platform)
  String get configDir {
    if (Platform.isWindows) {
      // Windows: C:\Users\用户名\.config\openterm\
      final home = Platform.environment['USERPROFILE'] ?? '.';
      return p.join(home, '.config', 'openterm');
    }
    // macOS/Linux: ~/.config/openterm/
    final home = Platform.environment['HOME'] ?? '.';
    return p.join(home, '.config', 'openterm');
  }

  /// Config file: `~/.config/openterm/config.jsonc`
  String get configFilePath => p.join(configDir, 'config.jsonc');

  // ── JSONC Parsing ──────────────────────────────────

  /// Strip `//` single-line and `/* */` multi-line comments from JSONC.
  ///
  /// Uses a state-machine approach to avoid stripping `//` inside strings.
  static String stripJsoncComments(String input) {
    final buf = StringBuffer();
    var i = 0;
    var inString = false;
    var escape = false;

    while (i < input.length) {
      final c = input[i];

      if (inString) {
        buf.write(c);
        if (escape) {
          escape = false;
        } else if (c == '\\') {
          escape = true;
        } else if (c == '"') {
          inString = false;
        }
        i++;
        continue;
      }

      // Not inside a string
      if (c == '"') {
        inString = true;
        buf.write(c);
        i++;
      } else if (c == '/' && i + 1 < input.length) {
        final next = input[i + 1];
        if (next == '/') {
          // Single-line comment: skip to end of line
          i += 2;
          while (i < input.length && input[i] != '\n') {
            i++;
          }
        } else if (next == '*') {
          // Multi-line comment: skip to */
          i += 2;
          while (i + 1 < input.length &&
              !(input[i] == '*' && input[i + 1] == '/')) {
            i++;
          }
          i += 2; // skip */
        } else {
          buf.write(c);
          i++;
        }
      } else {
        buf.write(c);
        i++;
      }
    }

    return buf.toString();
  }

  /// Parse JSONC string → Map.
  static Map<String, dynamic> parseJsonc(String content) {
    final stripped = stripJsoncComments(content);
    // Handle trailing commas (common in JSONC): remove comma before } or ]
    final cleaned = stripped.replaceAllMapped(
      RegExp(r',\s*(?=[}\]])'),
      (m) => '',
    );
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  // ── Load from File → SettingsRecord ────────────────

  /// Load config from JSONC file and merge into the given [SettingsRecord].
  /// Returns true if file existed and was loaded.
  Future<bool> loadFromFile(SettingsRecord settings) async {
    final file = File(configFilePath);
    if (!await file.exists()) return false;

    try {
      _isSyncing = true;
      final content = await file.readAsString();
      final json = parseJsonc(content);
      _applyJsonToSettings(json, settings);
      return true;
    } catch (e) {
      // Malformed JSONC — don't crash, just skip
      _logger.e('Failed to parse config.jsonc', error: e);
      return false;
    } finally {
      Future.delayed(const Duration(milliseconds: 100), () {
        _isSyncing = false;
      });
    }
  }

  /// Load profiles from JSONC config file.
  Future<List<ProfileRecord>> loadProfiles() async {
    final file = File(configFilePath);
    if (!await file.exists()) return [];
    try {
      final content = await file.readAsString();
      final json = parseJsonc(content);
      return parseProfiles(json);
    } catch (e) {
      _logger.e('Failed to load profiles from config.jsonc', error: e);
      return [];
    }
  }

  /// Load keymap bindings from JSONC config file.
  Future<Map<String, String>> loadKeymaps() async {
    final file = File(configFilePath);
    if (!await file.exists()) return {};
    try {
      final content = await file.readAsString();
      final json = parseJsonc(content);
      return parseKeymaps(json);
    } catch (e) {
      _logger.e('Failed to load keymaps from config.jsonc', error: e);
      return {};
    }
  }

  /// Apply a parsed JSON map to a [SettingsRecord].
  void _applyJsonToSettings(Map<String, dynamic> json, SettingsRecord s) {
    final terminal = json['terminal'] as Map<String, dynamic>?;
    if (terminal != null) {
      if (terminal['font_size'] != null) {
        s.terminalFontSize = (terminal['font_size'] as num).toDouble();
      }
      if (terminal['font_family'] != null) {
        s.terminalFontFamily = terminal['font_family'] as String;
      }
      if (terminal['line_height'] != null) {
        s.lineHeight = (terminal['line_height'] as num).toDouble();
      }
      if (terminal['letter_spacing'] != null) {
        s.letterSpacing = (terminal['letter_spacing'] as num).toDouble();
      }
      if (terminal['scrollback'] != null) {
        s.scrollback = (terminal['scrollback'] as num).toInt();
      }
      if (terminal['disable_underline'] != null) {
        s.disableUnderline = terminal['disable_underline'] as bool;
      }

      final cursor = terminal['cursor'] as Map<String, dynamic>?;
      if (cursor != null) {
        if (cursor['shape'] != null) s.cursorShape = cursor['shape'] as String;
        if (cursor['blink'] != null) s.cursorBlink = cursor['blink'] as bool;
        if (cursor['color'] != null) s.cursorColor = cursor['color'] as String;
      }
    }

    final appearance = json['appearance'] as Map<String, dynamic>?;
    if (appearance != null) {
      if (appearance['theme'] != null) {
        s.themeId = appearance['theme'] as String;
      }
      if (appearance['background_opacity'] != null) {
        s.backgroundOpacity =
            (appearance['background_opacity'] as num).toDouble();
      }
      if (appearance['padding'] != null) {
        s.padding = (appearance['padding'] as num).toDouble();
      }
      if (appearance['background_color'] != null) {
        s.backgroundColor = appearance['background_color'] as String;
      }
    }

    final shell = json['shell'] as Map<String, dynamic>?;
    if (shell != null) {
      if (shell['path'] != null) s.shell = shell['path'] as String;
      if (shell['args'] != null) {
        s.shellArgs = (shell['args'] as List).cast<String>();
      }
      if (shell['working_directory'] != null) {
        s.workingDirectory = shell['working_directory'] as String;
      }
      if (shell['preserve_cwd'] != null) {
        s.preserveCWD = shell['preserve_cwd'] as bool;
      }
      if (shell['copy_on_select'] != null) {
        s.copyOnSelect = shell['copy_on_select'] as bool;
      }
      final envMap = shell['env'] as Map<String, dynamic>?;
      if (envMap != null) {
        s.env = envMap.map((k, v) => MapEntry(k, v.toString()));
      }
    }

    final ai = json['ai'] as Map<String, dynamic>?;
    if (ai != null) {
      if (ai['provider'] != null) s.aiProvider = ai['provider'] as String;
      if (ai['model'] != null) s.aiModel = ai['model'] as String;
      if (ai['api_key'] != null) s.aiApiKey = ai['api_key'] as String;
    }

    final snippetsMap = json['snippets'] as Map<String, dynamic>?;
    if (snippetsMap != null) {
      s.snippets = snippetsMap.entries
          .map((e) =>
              SnippetRecord.fromJson(e.key, e.value as Map<String, dynamic>))
          .toList();
    }
  }

  /// Parse snippets from the JSONC config map.
  static List<SnippetRecord> parseSnippets(Map<String, dynamic> json) {
    final snippetsMap = json['snippets'] as Map<String, dynamic>?;
    if (snippetsMap == null) return [];
    return snippetsMap.entries
        .map((e) =>
            SnippetRecord.fromJson(e.key, e.value as Map<String, dynamic>))
        .toList();
  }

  // ── Save SettingsRecord → JSONC File ──────────────

  /// Convert a [SettingsRecord] to the JSONC template string.
  /// If [profiles] is provided, they are included in the output.
  static String settingsToJsonc(
    SettingsRecord s, {
    List<ProfileRecord>? profiles,
    Map<String, String>? keymaps,
  }) {
    return '''
{
  // TerminalStudio Configuration
  // 修改后自动生效，无需重启

  "terminal": {
    "font_size": ${s.terminalFontSize},
    "font_family": ${jsonEncode(s.terminalFontFamily ?? 'Hack Nerd Font Mono')},
    "line_height": ${s.lineHeight},
    "letter_spacing": ${s.letterSpacing},
    "scrollback": ${s.scrollback},
    "disable_underline": ${s.disableUnderline ?? true},

    "cursor": {
      "shape": ${jsonEncode(s.cursorShape)},      // block | beam | underline
      "blink": ${s.cursorBlink}${s.cursorColor != null ? ',\n      "color": ${jsonEncode(s.cursorColor)}' : '\n      // "color": "#FFFFFF"  // 取消注释以自定义'}
    }
  },

  "appearance": {
    "theme": ${jsonEncode(s.themeId)},
    "background_opacity": ${s.backgroundOpacity},
    "padding": ${s.padding}${s.backgroundColor != null ? ',\n    "background_color": ${jsonEncode(s.backgroundColor)}' : '\n    // "background_color": "#1E1E2E"  // 取消注释以覆盖主题'}
  },

  "shell": {
    ${s.shell != null ? '"path": ${jsonEncode(s.shell)},' : '// "path": "/bin/zsh",           // 不设置则使用系统默认'}
    ${s.shellArgs != null ? '"args": ${jsonEncode(s.shellArgs)},' : '// "args": ["--login"],'}
    ${s.workingDirectory != null ? '"working_directory": ${jsonEncode(s.workingDirectory)},' : '// "working_directory": "~",'}
    "preserve_cwd": ${s.preserveCWD},
    "copy_on_select": ${s.copyOnSelect},

    "env": ${s.env != null && s.env!.isNotEmpty ? jsonEncode(s.env) : '{\n      // "LANG": "en_US.UTF-8"       // 自定义环境变量\n    }'}
  },

  "ai": {
    "provider": ${jsonEncode(s.aiProvider)},
    "model": ${jsonEncode(s.aiModel)}${s.aiApiKey != null && s.aiApiKey!.isNotEmpty ? ',\n    "api_key": ${jsonEncode(s.aiApiKey)}' : '\n    // "api_key": "sk-..."           // 建议使用 GUI 设置'}
  }${s.snippets.isNotEmpty ? ',\n\n  "snippets": ${_snippetsToJsonc(s.snippets)}' : ''}${profiles != null && profiles.isNotEmpty ? ',\n\n  "profiles": ${_profilesToJsonc(profiles)}' : ''}${keymaps != null && keymaps.isNotEmpty ? ',\n\n  "keymaps": ${_keymapsToJsonc(keymaps)}' : ''}
}
''';
  }

  /// Format profiles as a JSON object with comments.
  static String _profilesToJsonc(List<ProfileRecord> profiles) {
    final buf = StringBuffer('{\n');
    for (var i = 0; i < profiles.length; i++) {
      final p = profiles[i];
      // Pretty-print the profile JSON
      final encoder = const JsonEncoder.withIndent('      ');
      final pretty = encoder.convert(p.toJson());
      buf.write('    ${jsonEncode(p.id)}: $pretty');
      if (i < profiles.length - 1) buf.write(',');
      buf.write('\n');
    }
    buf.write('  }');
    return buf.toString();
  }

  // ── Profile Loading ───────────────────────────────

  /// Parse profiles from the JSONC config map.
  static List<ProfileRecord> parseProfiles(Map<String, dynamic> json) {
    final profilesMap = json['profiles'] as Map<String, dynamic>?;
    if (profilesMap == null) return [];

    return profilesMap.entries.map((entry) {
      final profileJson = entry.value as Map<String, dynamic>;
      return ProfileRecord.fromJson(entry.key, profileJson);
    }).toList();
  }

  // ── Keymap Serialization ──────────────────────────

  /// Format snippets as a JSON object.
  static String _snippetsToJsonc(List<SnippetRecord> snippets) {
    final buf = StringBuffer('{\n');
    for (var i = 0; i < snippets.length; i++) {
      final s = snippets[i];
      buf.write(
          '    ${jsonEncode(s.id)}: ${jsonEncode(s.toJson())}');
      if (i < snippets.length - 1) buf.write(',');
      buf.write('\n');
    }
    buf.write('  }');
    return buf.toString();
  }

  /// Format a keymaps map as a JSON object.
  static String _keymapsToJsonc(Map<String, String> keymaps) {
    final encoder = const JsonEncoder.withIndent('    ');
    return encoder.convert(keymaps);
  }

  /// Parse keymaps from the JSONC config map.
  static Map<String, String> parseKeymaps(Map<String, dynamic> json) {
    final keymapsMap = json['keymaps'] as Map<String, dynamic>?;
    if (keymapsMap == null) return {};
    return keymapsMap.map((k, v) => MapEntry(k, v.toString()));
  }

  /// Write the current settings to the JSONC file.
  Future<void> saveToFile(
    SettingsRecord settings, {
    List<ProfileRecord>? profiles,
    Map<String, String>? keymaps,
  }) async {
    if (_isSyncing) return; // Prevent re-entrant write
    try {
      _isSyncing = true;
      final dir = Directory(configDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final content = settingsToJsonc(
        settings,
        profiles: profiles,
        keymaps: keymaps,
      );
      await File(configFilePath).writeAsString(content);
    } finally {
      Future.delayed(const Duration(milliseconds: 100), () {
        _isSyncing = false;
      });
    }
  }

  // ── Default Config Generation ─────────────────────

  /// Generate the default config file if it doesn't exist.
  Future<void> generateDefaultConfig() async {
    final file = File(configFilePath);
    if (await file.exists()) return;

    final dir = Directory(configDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final content = settingsToJsonc(SettingsRecord());
    await file.writeAsString(content);
  }

  // ── File Watcher (Hot Reload) ─────────────────────

  /// Start watching the config file for external changes.
  ///
  /// When the file changes, [onChanged] is called so the caller can
  /// re-load settings and invalidate providers.
  void startWatching(void Function() onChanged) {
    stopWatching();

    final dir = Directory(configDir);
    if (!dir.existsSync()) return;

    _watcher = dir.watch(events: FileSystemEvent.modify).listen((event) {
      if (event.path == configFilePath && !_isSyncing) {
        onChanged();
      }
    });
  }

  /// Stop watching the config file.
  void stopWatching() {
    _watcher?.cancel();
    _watcher = null;
  }
}

/// Riverpod provider for ConfigFileService.
final configFileServiceProvider = Provider<ConfigFileService>((ref) {
  final service = ConfigFileService();
  ref.onDispose(() => service.stopWatching());
  return service;
});
