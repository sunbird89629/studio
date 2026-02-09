import 'dart:io';

import 'log_file_output.dart';

/// 过期日志清理器
class LogCleaner {
  final LogFileOutput fileOutput;
  final int retentionDays;

  LogCleaner({
    required this.fileOutput,
    this.retentionDays = 7,
  });

  /// 清理过期日志文件
  Future<int> clean() async {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: retentionDays));
    final files = await fileOutput.listLogFiles();
    int deletedCount = 0;

    for (final file in files) {
      final date = _parseDateFromFilename(file.path);
      if (date != null && date.isBefore(cutoff)) {
        await file.delete();
        deletedCount++;
      }
    }

    return deletedCount;
  }

  /// 从文件名解析日期 (openterm-2026-02-09.jsonl)
  DateTime? _parseDateFromFilename(String path) {
    final filename = path.split(Platform.pathSeparator).last;
    final match =
        RegExp(r'openterm-(\d{4})-(\d{2})-(\d{2})\.jsonl').firstMatch(filename);
    if (match == null) return null;

    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }
}
