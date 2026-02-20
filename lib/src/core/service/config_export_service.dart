import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/record/keymap_record.dart';
import 'package:terminal_studio/src/core/record/profile_record.dart';
import 'package:terminal_studio/src/core/record/settings_record.dart';
import 'package:terminal_studio/src/core/record/ssh_host_record.dart';
import 'package:terminal_studio/src/core/state/database.dart';
import 'package:terminal_studio/src/core/state/keymap.dart';
import 'package:terminal_studio/src/util/hive_box_ext.dart';

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
      result['settings'] = settingsBox.getAt(0)!.toFlatMap();
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
      final settings = settingsBox.getOrCreate(SettingsRecord.new);
      settings.applyFlatMap(json['settings'] as Map<String, dynamic>);
      await settingsBox.saveOrAdd(settings);
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
