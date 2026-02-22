import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/record/profile_record.dart';
import 'package:terminal_studio/src/core/record/ssh_host_record.dart';
import 'package:terminal_studio/src/core/service/config_file_service.dart';
import 'package:terminal_studio/src/core/service/ssh_storage_service.dart';
import 'package:terminal_studio/src/core/state/database.dart';
import 'package:terminal_studio/src/core/state/settings.dart';

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
    final settings = _ref.read(settingsProvider).value;
    if (settings != null) {
      result['settings'] = settings.toFlatMap();
    }

    // Profiles
    final profiles = _ref.read(profilesProvider).value ?? [];
    if (profiles.isNotEmpty) {
      result['profiles'] = profiles.map((p) {
        final map = p.toJson();
        map['id'] = p.id;
        return map;
      }).toList();
    }

    // Keymaps
    final config = _ref.read(configFileServiceProvider);
    final keymaps = await config.loadKeymaps();
    if (keymaps.isNotEmpty) {
      result['keymaps'] = keymaps;
    }

    // SSH Hosts (without passwords)
    final hosts = await _ref.read(sshStorageServiceProvider).loadHosts();
    if (hosts.isNotEmpty) {
      result['ssh_hosts'] = hosts.map(_sshHostToMap).toList();
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
    final settings = _ref.read(settingsProvider).value;
    if (json['settings'] is Map<String, dynamic> && settings != null) {
      settings.applyFlatMap(json['settings'] as Map<String, dynamic>);
      imported++;
    }

    // Profiles
    final newProfiles = <ProfileRecord>[];
    if (json['profiles'] is List) {
      for (final p in json['profiles'] as List) {
        if (p is Map<String, dynamic>) {
          final id = p['id'] as String? ?? p['name'] as String? ?? '';
          newProfiles.add(ProfileRecord.fromJson(id, p));
          imported++;
        }
      }
    }

    // Keymaps
    Map<String, String>? newKeymaps;
    if (json['keymaps'] is Map<String, dynamic>) {
      newKeymaps = (json['keymaps'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v.toString()));
      imported++;
    }

    // Persist settings + profiles + keymaps together
    if (settings != null) {
      final existingProfiles = _ref.read(profilesProvider).value ?? [];
      final mergedProfiles = [...existingProfiles, ...newProfiles];
      final config = _ref.read(configFileServiceProvider);
      await config.saveToFile(settings,
          profiles: mergedProfiles, keymaps: newKeymaps);
      _ref.invalidate(settingsProvider);
    }

    // SSH Hosts
    if (json['ssh_hosts'] is List) {
      final sshService = _ref.read(sshStorageServiceProvider);
      final existingHosts = await sshService.loadHosts();
      for (final h in json['ssh_hosts'] as List) {
        if (h is Map<String, dynamic>) {
          existingHosts.add(SSHHostRecord.fromJson(h));
          imported++;
        }
      }
      await sshService.saveHosts(existingHosts);
      _ref.invalidate(sshHostsProvider);
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
