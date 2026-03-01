import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'log_entry.dart';




/// 日志文件输出，JSON Lines 格式
class LogFileOutput {
  IOSink? _sink;
  DateTime? _currentDate;
  Future<void> _pending = Future.value();

  /// 获取日志目录
  Future<Directory> get logDirectory async {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        return Directory('$home/Library/Logs/OpenTerm');
      }
      final support = await getApplicationSupportDirectory();
      return Directory('${support.path}/Logs');
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      return Directory('$appData/OpenTerm/Logs');
    } else {
      // Linux 或其他平台
      final docDir = await getApplicationDocumentsDirectory();
      return Directory('${docDir.path}/OpenTerm/Logs');
    }
  }

  /// 获取指定日期的日志文件
  Future<File> getLogFile(DateTime date) async {
    final dir = await logDirectory;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return File('${dir.path}/openterm-$dateStr.jsonl');
  }

  /// 写入日志条目（通过 Future chain 串行化所有写入）
  void write(LogEntry entry) {
    _pending = _pending.then((_) => _doWrite(entry)).catchError((_) {});
  }

  Future<void> _doWrite(LogEntry entry) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // 如果日期变化，切换文件
    if (_currentDate == null || _currentDate != todayDate) {
      await _closeSink();
      await _openSink(todayDate);
    }

    _sink?.writeln(entry.toJsonLine());
  }

  Future<void> _openSink(DateTime date) async {
    final file = await getLogFile(date);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    _sink = file.openWrite(mode: FileMode.append);
    _currentDate = date;
  }

  Future<void> _closeSink() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
  }

  /// 读取指定日期的日志
  Stream<LogEntry> read(DateTime date) async* {
    final file = await getLogFile(date);
    if (!await file.exists()) return;

    await for (final line in file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      final entry = LogEntry.fromJsonLine(line);
      if (entry != null) {
        yield entry;
      }
    }
  }

  /// 列出所有日志文件
  Future<List<File>> listLogFiles() async {
    final dir = await logDirectory;
    if (!await dir.exists()) return [];

    return dir
        .list()
        .where((f) => f is File && f.path.endsWith('.jsonl'))
        .cast<File>()
        .toList();
  }

  /// 刷新并关闭
  Future<void> dispose() async {
    await _pending;
    await _closeSink();
  }
}
