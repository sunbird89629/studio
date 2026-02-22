import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:terminal_studio/src/core/utils/app_logger.dart';

final releaseNotesServiceProvider = Provider<ReleaseNotesService>((ref) {
  return ReleaseNotesService();
});

class ReleaseNotesService {
  static const String _lastSeenVersionKey = 'last_seen_version';

  final _logger = AppLogger.forComponent('ReleaseNotesService');

  String get _configDir {
    if (Platform.isWindows) {
      final home = Platform.environment['USERPROFILE'] ?? '.';
      return p.join(home, '.config', 'openterm');
    }
    final home = Platform.environment['HOME'] ?? '.';
    return p.join(home, '.config', 'openterm');
  }

  String get _stateFilePath => p.join(_configDir, 'state.json');

  Future<Map<String, dynamic>> _readState() async {
    final file = File(_stateFilePath);
    if (!await file.exists()) return {};
    try {
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      _logger.w('Failed to read state.json', error: e);
      return {};
    }
  }

  Future<void> _writeState(Map<String, dynamic> state) async {
    try {
      final dir = Directory(_configDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      await File(_stateFilePath)
          .writeAsString(const JsonEncoder.withIndent('  ').convert(state));
    } catch (e) {
      _logger.w('Failed to write state.json', error: e);
    }
  }

  Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }

  Future<String?> getLastSeenVersion() async {
    final state = await _readState();
    return state[_lastSeenVersionKey] as String?;
  }

  Future<void> markVersionAsSeen(String version) async {
    final state = await _readState();
    state[_lastSeenVersionKey] = version;
    await _writeState(state);
  }

  /// Checks if the current version is newer than the last seen version.
  Future<bool> checkNewVersion() async {
    final currentVersion = await getAppVersion();
    final lastSeenVersion = await getLastSeenVersion();

    if (lastSeenVersion == null) {
      return true;
    }

    return currentVersion != lastSeenVersion;
  }

  Future<String> loadReleaseNotes() async {
    try {
      return await rootBundle.loadString('assets/release_notes.md');
    } catch (e, stack) {
      _logger.w('Error loading release notes: $e', error: e, stackTrace: stack);
      return 'Release notes not found.';
    }
  }
}
