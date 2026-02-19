import 'dart:async';
import 'dart:collection';

import 'log_entry.dart';

/// 环形缓冲区，保留最近的日志条目
class LogBuffer {
  final int maxSize;
  final Queue<LogEntry> _entries = Queue<LogEntry>();
  final StreamController<LogEntry> _controller =
      StreamController<LogEntry>.broadcast();

  LogBuffer({this.maxSize = 2000});

  /// 实时日志流
  Stream<LogEntry> get stream => _controller.stream;

  /// 当前缓冲区中的所有条目
  List<LogEntry> get entries => _entries.toList();

  /// 条目数量
  int get length => _entries.length;

  /// 添加日志条目
  void add(LogEntry entry) {
    if (_entries.length >= maxSize) _entries.removeFirst();
    _entries.addLast(entry);
    _controller.add(entry);
  }

  /// 清空缓冲区
  void clear() {
    _entries.clear();
  }

  /// 按级别过滤
  List<LogEntry> filterByLevel(LogLevel level) {
    return _entries.where((e) => e.level == level).toList();
  }

  /// 按通道过滤
  List<LogEntry> filterByChannel(String channel) {
    return _entries.where((e) => e.channel == channel).toList();
  }

  /// 获取所有通道
  Set<String> get channels => _entries.map((e) => e.channel).toSet();

  /// 释放资源
  void dispose() {
    _controller.close();
  }
}
