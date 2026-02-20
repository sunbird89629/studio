import 'dart:io' as io;

import 'package:terminal_studio/src/core/utils/app_logger.dart';

/// Opens URLs and file paths with the system's default application.
///
/// Uses platform-native commands — no external package required.
class LauncherService {
  LauncherService._();

  static final _logger = AppLogger.forComponent('LauncherService');

  /// Opens [target] (a URL or absolute file path) with the system default app.
  static Future<void> open(String target) async {
    try {
      if (io.Platform.isMacOS) {
        await io.Process.run('open', [target]);
      } else if (io.Platform.isLinux) {
        await io.Process.run('xdg-open', [target]);
      } else if (io.Platform.isWindows) {
        await io.Process.run('start', [target], runInShell: true);
      }
    } catch (e) {
      _logger.e('Failed to open "$target"', error: e);
    }
  }
}
