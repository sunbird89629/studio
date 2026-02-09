import 'dart:convert';

/// 日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error;

  String get shortName {
    switch (this) {
      case LogLevel.debug:
        return 'DBG';
      case LogLevel.info:
        return 'INF';
      case LogLevel.warning:
        return 'WRN';
      case LogLevel.error:
        return 'ERR';
    }
  }

  static LogLevel fromShortName(String name) {
    switch (name.toUpperCase()) {
      case 'DBG':
        return LogLevel.debug;
      case 'INF':
        return LogLevel.info;
      case 'WRN':
        return LogLevel.warning;
      case 'ERR':
        return LogLevel.error;
      default:
        return LogLevel.info;
    }
  }
}

/// 日志条目
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String channel;
  final String sessionId;
  final int? pid;
  final String message;
  final Map<String, dynamic>? meta;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.channel,
    required this.sessionId,
    this.pid,
    required this.message,
    this.meta,
  });

  /// 序列化为 JSON Lines 格式的单行
  String toJsonLine() {
    final data = <String, dynamic>{
      'ts': timestamp.toUtc().toIso8601String(),
      'lv': level.shortName,
      'ch': channel,
      'sid': sessionId,
      'msg': message,
    };

    if (pid != null) {
      data['pid'] = pid;
    }

    if (meta != null && meta!.isNotEmpty) {
      data['meta'] = meta;
    }

    return jsonEncode(data);
  }

  /// 从 JSON 反序列化
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['ts'] as String),
      level: LogLevel.fromShortName(json['lv'] as String),
      channel: json['ch'] as String,
      sessionId: json['sid'] as String,
      pid: json['pid'] as int?,
      message: json['msg'] as String,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  /// 从 JSON Lines 单行解析
  static LogEntry? fromJsonLine(String line) {
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      return LogEntry.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => '[${level.shortName}] $channel: $message';
}
