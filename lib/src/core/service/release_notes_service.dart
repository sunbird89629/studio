import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:terminal_studio/src/core/utils/ai_logger.dart';

final releaseNotesServiceProvider = Provider<ReleaseNotesService>((ref) {
  return ReleaseNotesService();
});

class ReleaseNotesService {
  static const String _boxName = 'release_notes';
  static const String _lastSeenVersionKey = 'last_seen_version';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }

  Future<String?> getLastSeenVersion() async {
    final box = await _getBox();
    return box.get(_lastSeenVersionKey) as String?;
  }

  Future<void> markVersionAsSeen(String version) async {
    final box = await _getBox();
    await box.put(_lastSeenVersionKey, version);
  }

  /// Checks if the current version is newer than the last seen version.
  Future<bool> checkNewVersion() async {
    final currentVersion = await getAppVersion();
    final lastSeenVersion = await getLastSeenVersion();

    if (lastSeenVersion == null) {
      // First run or no version stored yet.
      // We might want to show release notes on fresh install too,
      // or assume it's a "new version" if we want to show welcome notes.
      // For now, let's treat it as new.
      return true;
    }

    return currentVersion != lastSeenVersion;
  }

  Future<String> loadReleaseNotes() async {
    try {
      // By default, load from assets/release_notes.md
      // You need to ensure this file exists in your assets and is declared in pubspec.yaml
      return await rootBundle.loadString('assets/release_notes.md');
    } catch (e, stack) {
      AILogger().w('Error loading release notes: $e',
          error: e,
          stackTrace: stack,
          context: const LogContext(component: 'ReleaseNotesService'));
      return 'Release notes not found.';
    }
  }
}
