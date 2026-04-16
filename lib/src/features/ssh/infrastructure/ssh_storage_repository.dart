import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:terminal_studio/src/shared/models/records/ssh_host_record.dart';
import 'package:terminal_studio/src/shared/models/records/ssh_key_record.dart';
import 'package:terminal_studio/src/shared/logging/app_logger.dart';
import 'package:terminal_studio/src/shared/utils/platform_utils.dart';

/// Service for persisting SSH hosts and keys to JSON files.
///
/// Files are stored in `~/.config/openterm/`:
///   - `hosts.json` — SSH host configurations
///   - `keys.json`  — SSH key pairs
class SshStorageService {
  /// Creates the service. [configDir] overrides the default config directory;
  /// useful for testing.
  SshStorageService({String? configDir}) : _configDirOverride = configDir;

  final String? _configDirOverride;
  final _logger = AppLogger.forComponent('SshStorageService');

  String get configDir =>
      _configDirOverride ?? p.join(platformHomeDirectory() ?? '.', '.config', 'openterm');

  String get _hostsFilePath => p.join(configDir, 'hosts.json');
  String get _keysFilePath => p.join(configDir, 'keys.json');

  Future<void> _ensureDir() async {
    final dir = Directory(configDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  // ── SSH Hosts ─────────────────────────────────────

  Future<List<SSHHostRecord>> loadHosts() async {
    final file = File(_hostsFilePath);
    if (!await file.exists()) return [];
    try {
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(SSHHostRecord.fromJson)
          .toList();
    } catch (e) {
      _logger.e('Failed to load hosts.json', error: e);
      return [];
    }
  }

  Future<void> saveHosts(List<SSHHostRecord> hosts) async {
    await _ensureDir();
    try {
      final list = hosts.map((h) => h.toJson()).toList();
      await File(_hostsFilePath)
          .writeAsString(const JsonEncoder.withIndent('  ').convert(list));
    } catch (e) {
      _logger.e('Failed to save hosts.json', error: e);
    }
  }

  Future<void> addHost(SSHHostRecord host, List<SSHHostRecord> current) async {
    current.add(host);
    await saveHosts(current);
  }

  Future<void> updateHost(
    SSHHostRecord host,
    List<SSHHostRecord> current,
  ) async {
    final idx = current.indexWhere((h) => h.uuid == host.uuid);
    if (idx >= 0) current[idx] = host;
    await saveHosts(current);
  }

  Future<void> deleteHost(String uuid, List<SSHHostRecord> current) async {
    current.removeWhere((h) => h.uuid == uuid);
    await saveHosts(current);
  }

  // ── SSH Keys ──────────────────────────────────────

  Future<List<SSHKeyRecord>> loadKeys() async {
    final file = File(_keysFilePath);
    if (!await file.exists()) return [];
    try {
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(SSHKeyRecord.fromJson)
          .toList();
    } catch (e) {
      _logger.e('Failed to load keys.json', error: e);
      return [];
    }
  }

  Future<void> saveKeys(List<SSHKeyRecord> keys) async {
    await _ensureDir();
    try {
      final list = keys.map((k) => k.toJson()).toList();
      await File(_keysFilePath)
          .writeAsString(const JsonEncoder.withIndent('  ').convert(list));
    } catch (e) {
      _logger.e('Failed to save keys.json', error: e);
    }
  }
}

final sshStorageServiceProvider = Provider<SshStorageService>((ref) {
  return SshStorageService();
});

