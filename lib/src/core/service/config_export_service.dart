import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/record/keymap_record.dart';
import 'package:terminal_studio/src/core/record/profile_record.dart';
import 'package:terminal_studio/src/core/record/settings_record.dart';
import 'package:terminal_studio/src/core/record/ssh_host_record.dart';
import 'package:terminal_studio/src/core/state/database.dart';
import 'package:terminal_studio/src/core/state/keymap.dart';

final configExportServiceProvider = Provider(ConfigExportService.new);

class ConfigExportService {
  final Ref _ref;

  ConfigExportService(this._ref);

  static const _version = 1;

  // ── Export ────────────────────────────────────────

  /// Export all configuration as a JSON-serializable map.
  Future<Map<String, dynamic>> exportAll() async {
    final result = <String, dynamic>{'version': _version};

    // Settings
    final settingsBox = await _ref.read(settingsBoxProvider.future);
    if (settingsBox.isNotEmpty) {
      result['settings'] = _settingsToMap(settingsBox.getAt(0)!);
    }

    // Profiles
    final profileBox = await _ref.read(profileBoxProvider.future);
    if (profileBox.isNotEmpty) {
      result['profiles'] = profileBox.values.map((p) {
        final map = p.toJson();
        map['id'] = p.id;
        return map;
      }).toList();
    }

    // Keymaps
    final keymapBox = await _ref.read(keymapBoxProvider.future);
    if (keymapBox.isNotEmpty) {
      result['keymaps'] = keymapBox.getAt(0)!.bindings;
    }

    // SSH Hosts (without passwords)
    final sshBox = await _ref.read(sshHostBoxProvider.future);
    if (sshBox.isNotEmpty) {
      result['ssh_hosts'] = sshBox.values.map(_sshHostToMap).toList();
    }

    return result;
  }

  /// Export as a pretty-printed JSON string.
  Future<String> exportAsJson() async {
    final data = await exportAll();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // ── Import ───────────────────────────────────────

  /// Import configuration from a JSON map. Returns an [ImportResult].
  Future<ImportResult> importConfig(Map<String, dynamic> json) async {
    final version = json['version'] as int?;
    if (version == null || version > _version) {
      return ImportResult(
        success: false,
        message: 'Unsupported config version: $version (expected: $_version)',
      );
    }

    var imported = 0;

    // Settings
    if (json['settings'] is Map<String, dynamic>) {
      final settingsBox = await _ref.read(settingsBoxProvider.future);
      final settings =
          settingsBox.isNotEmpty ? settingsBox.getAt(0)! : SettingsRecord();
      _applySettings(settings, json['settings'] as Map<String, dynamic>);
      if (settingsBox.isEmpty) {
        await settingsBox.add(settings);
      } else {
        await settings.save();
      }
      imported++;
    }

    // Profiles
    if (json['profiles'] is List) {
      final profileBox = await _ref.read(profileBoxProvider.future);
      for (final p in json['profiles'] as List) {
        if (p is Map<String, dynamic>) {
          final id = p['id'] as String? ?? p['name'] as String? ?? '';
          final profile = ProfileRecord.fromJson(id, p);
          await profileBox.add(profile);
          imported++;
        }
      }
    }

    // Keymaps
    if (json['keymaps'] is Map<String, dynamic>) {
      final keymapBox = await _ref.read(keymapBoxProvider.future);
      final bindings = (json['keymaps'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v.toString()));

      if (keymapBox.isNotEmpty) {
        final record = keymapBox.getAt(0)!;
        record.bindings.addAll(bindings);
        await record.save();
      } else {
        await keymapBox.add(KeymapRecord(bindings: bindings));
      }
      imported++;
    }

    // SSH Hosts
    if (json['ssh_hosts'] is List) {
      final sshBox = await _ref.read(sshHostBoxProvider.future);
      for (final h in json['ssh_hosts'] as List) {
        if (h is Map<String, dynamic>) {
          final host = SSHHostRecord(
            uuid: h['uuid'] as String?,
            name: h['name'] as String? ?? '',
            host: h['host'] as String? ?? '',
            port: h['port'] as int? ?? 22,
            username: h['username'] as String?,
          );
          await sshBox.add(host);
          imported++;
        }
      }
    }

    return ImportResult(
      success: true,
      message: 'Imported $imported items successfully.',
    );
  }

  /// Import from a JSON string.
  Future<ImportResult> importFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      return importConfig(data);
    } on FormatException catch (e) {
      return ImportResult(success: false, message: 'Invalid JSON: $e');
    }
  }

  // ── Helpers ──────────────────────────────────────

  Map<String, dynamic> _settingsToMap(SettingsRecord s) => {
        'terminal_font_size': s.terminalFontSize,
        'terminal_font_family': s.terminalFontFamily,
        'theme_id': s.themeId,
        'cursor_shape': s.cursorShape,
        'cursor_blink': s.cursorBlink,
        'cursor_color': s.cursorColor,
        'shell': s.shell,
        'shell_args': s.shellArgs,
        'working_directory': s.workingDirectory,
        'scrollback': s.scrollback,
        'line_height': s.lineHeight,
        'letter_spacing': s.letterSpacing,
        'copy_on_select': s.copyOnSelect,
        'background_opacity': s.backgroundOpacity,
        'background_color': s.backgroundColor,
        'padding': s.padding,
        'env': s.env,
        'preserve_cwd': s.preserveCWD,
        'disable_underline': s.disableUnderline,
        'ai_provider': s.aiProvider,
        'ai_model': s.aiModel,
        'ai_api_key': s.aiApiKey,
      };

  void _applySettings(SettingsRecord s, Map<String, dynamic> map) {
    if (map['terminal_font_size'] is num) {
      s.terminalFontSize = (map['terminal_font_size'] as num).toDouble();
    }
    if (map['terminal_font_family'] is String) {
      s.terminalFontFamily = map['terminal_font_family'] as String;
    }
    if (map['theme_id'] is String) s.themeId = map['theme_id'] as String;
    if (map['cursor_shape'] is String) {
      s.cursorShape = map['cursor_shape'] as String;
    }
    if (map['cursor_blink'] is bool)
      s.cursorBlink = map['cursor_blink'] as bool;
    if (map['cursor_color'] is String) {
      s.cursorColor = map['cursor_color'] as String;
    }
    if (map['shell'] is String) s.shell = map['shell'] as String;
    if (map['shell_args'] is List) {
      s.shellArgs = (map['shell_args'] as List).cast<String>();
    }
    if (map['working_directory'] is String) {
      s.workingDirectory = map['working_directory'] as String;
    }
    if (map['scrollback'] is int) s.scrollback = map['scrollback'] as int;
    if (map['line_height'] is num) {
      s.lineHeight = (map['line_height'] as num).toDouble();
    }
    if (map['letter_spacing'] is num) {
      s.letterSpacing = (map['letter_spacing'] as num).toDouble();
    }
    if (map['copy_on_select'] is bool) {
      s.copyOnSelect = map['copy_on_select'] as bool;
    }
    if (map['background_opacity'] is num) {
      s.backgroundOpacity = (map['background_opacity'] as num).toDouble();
    }
    if (map['background_color'] is String) {
      s.backgroundColor = map['background_color'] as String;
    }
    if (map['padding'] is num) s.padding = (map['padding'] as num).toDouble();
    if (map['env'] is Map) {
      s.env = (map['env'] as Map).cast<String, String>();
    }
    if (map['preserve_cwd'] is bool) {
      s.preserveCWD = map['preserve_cwd'] as bool;
    }
    if (map['disable_underline'] is bool) {
      s.disableUnderline = map['disable_underline'] as bool;
    }
    if (map['ai_provider'] is String) {
      s.aiProvider = map['ai_provider'] as String;
    }
    if (map['ai_model'] is String) s.aiModel = map['ai_model'] as String;
    if (map['ai_api_key'] is String) s.aiApiKey = map['ai_api_key'] as String;
  }

  Map<String, dynamic> _sshHostToMap(SSHHostRecord h) => {
        'uuid': h.uuid,
        'name': h.name,
        'host': h.host,
        'port': h.port,
        'username': h.username,
        // Note: password is excluded from export for security
      };
}

class ImportResult {
  final bool success;
  final String message;

  ImportResult({required this.success, required this.message});
}
