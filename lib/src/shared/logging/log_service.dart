import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:open_term/src/shared/logging/log_buffer.dart';
import 'package:open_term/src/shared/logging/log_cleaner.dart';
import 'package:open_term/src/shared/logging/log_entry.dart';
import 'package:open_term/src/shared/logging/log_file_output.dart';

/// 全局日志服务
class LogService {
  static final LogService instance = LogService._();

  LogService._();

  late final String sessionId;
  late final LogBuffer buffer;
  late final LogFileOutput fileOutput;
  late final LogCleaner cleaner;

  bool _initialized = false;

  /// 实时日志流
  Stream<LogEntry> get stream => buffer.stream;

  /// 初始化日志服务
  Future<void> initialize() async {
    if (_initialized) return;

    sessionId = const Uuid().v4().substring(0, 8);
    buffer = LogBuffer(maxSize: 2000);
    fileOutput = LogFileOutput();
    cleaner = LogCleaner(fileOutput: fileOutput, retentionDays: 7);

    _initialized = true;

    // 启动时清理过期日志
    await cleaner.clean();

    // 记录 session 开始
    log('system', LogLevel.info, 'Session started', meta: {'sid': sessionId});
  }

  /// 写入日志
  void log(
    String channel,
    LogLevel level,
    String message, {
    int? pid,
    Map<String, dynamic>? meta,
  }) {
    if (!_initialized) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      channel: channel,
      sessionId: sessionId,
      pid: pid,
      message: message,
      meta: meta,
    );

    buffer.add(entry);
    fileOutput.write(entry);
  }

  // 便捷方法
  void debug(
    String channel,
    String message, {
    int? pid,
    Map<String, dynamic>? meta,
  }) =>
      log(
        channel,
        LogLevel.debug,
        message,
        pid: pid,
        meta: meta,
      );

  void info(String channel, String message,
          {int? pid, Map<String, dynamic>? meta}) =>
      log(channel, LogLevel.info, message, pid: pid, meta: meta);

  void warning(String channel, String message,
          {int? pid, Map<String, dynamic>? meta}) =>
      log(channel, LogLevel.warning, message, pid: pid, meta: meta);

  void error(String channel, String message,
          {int? pid, Map<String, dynamic>? meta}) =>
      log(channel, LogLevel.error, message, pid: pid, meta: meta);

  /// 释放资源
  Future<void> dispose() async {
    buffer.dispose();
    await fileOutput.dispose();
  }
}

/// Riverpod Provider
final logServiceProvider = Provider<LogService>((ref) {
  return LogService.instance;
});
