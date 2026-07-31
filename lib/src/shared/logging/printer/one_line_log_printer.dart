import 'dart:io';

import 'package:logger/logger.dart';

class StructuredLogMessage {
  final String moduleName;
  final String content;

  const StructuredLogMessage({
    required this.moduleName,
    required this.content,
  });
}

class OneLineLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final level = _levelTag(event.level);
    final message = _normalizeMessage(event.message);
    final frame = _findCallerFrame(event.stackTrace);
    final className = frame?.className ?? '-';
    final methodName = _sanitizeMethodName(frame?.methodName ?? '-');
    final codeLine = frame?.codeLine ?? '-';
    final logContent = _singleLine(_buildLogContent(event, message.content));

    return [
      '[$level] [${message.moduleName}]$className.$methodName<$codeLine>【$logContent】',
    ];
  }

  String _buildLogContent(LogEvent event, String content) {
    if (event.error == null) return content;
    return '$content | error=${event.error}';
  }

  String _singleLine(String text) {
    return text.replaceAll('\n', r'\n');
  }

  String _sanitizeMethodName(String methodName) {
    final sanitized = methodName
        .replaceAll('.<anonymous closure>', '')
        .replaceAll('<anonymous closure>.', '')
        .replaceAll('<anonymous closure>', '')
        .replaceAll('..', '.')
        .trim();
    if (sanitized.isEmpty) return '-';
    if (sanitized.startsWith('.')) return sanitized.substring(1);
    if (sanitized.endsWith('.')) {
      return sanitized.substring(0, sanitized.length - 1);
    }
    return sanitized;
  }

  StructuredLogMessage _normalizeMessage(dynamic message) {
    if (message is StructuredLogMessage) {
      return message;
    }
    return StructuredLogMessage(
      moduleName: 'app',
      content: '$message',
    );
  }

  _CallerFrame? _findCallerFrame(StackTrace? stackTrace) {
    if (stackTrace == null) return null;

    for (final line in stackTrace.toString().split('\n')) {
      final frame = _parseFrame(line.trim());
      if (frame == null) continue;
      if (_shouldSkipFrame(frame.sourceUri)) continue;
      return frame;
    }
    return null;
  }

  _CallerFrame? _parseFrame(String line) {
    final match = RegExp(
      r'^#\d+\s+(.+?)\s+\((.+?):(\d+):(\d+)\)$',
    ).firstMatch(line);
    if (match == null) return null;

    final member = match.group(1)!;
    final sourceUri = match.group(2)!;
    final lineNo = int.tryParse(match.group(3)!);
    final columnNo = int.tryParse(match.group(4)!);
    if (lineNo == null || columnNo == null) return null;

    final method = _splitMember(member);
    final path = _toClickablePath(sourceUri);

    return _CallerFrame(
      sourceUri: sourceUri,
      className: method.$1,
      methodName: method.$2,
      codeLine: '$path:$lineNo:$columnNo',
    );
  }

  (String, String) _splitMember(String member) {
    final normalized = member.trim();
    final parts = normalized.split('.');
    if (parts.length >= 2) {
      return (parts.first, parts.skip(1).join('.'));
    }
    return ('-', normalized);
  }

  bool _shouldSkipFrame(String sourceUri) {
    return sourceUri.contains('/shared/logging/app_logger.dart') ||
        sourceUri.contains('package:logger/');
  }

  String _toClickablePath(String sourceUri) {
    if (sourceUri.startsWith('package:open_term/')) {
      final rel = sourceUri.substring('package:open_term/'.length);
      return 'lib/$rel';
    }
    if (sourceUri.startsWith('file://')) {
      final absPath = Uri.parse(sourceUri).toFilePath();
      return _shortenWorkspacePath(absPath);
    }
    return _shortenWorkspacePath(sourceUri);
  }

  String _shortenWorkspacePath(String path) {
    final cwd = Directory.current.path;
    final prefix = '$cwd/';
    if (path.startsWith(prefix)) {
      return path.substring(prefix.length);
    }

    final libMarker = '/lib/';
    final libIndex = path.indexOf(libMarker);
    if (libIndex >= 0) {
      return path.substring(libIndex + 1);
    }

    return path;
  }

  String _levelTag(Level level) {
    switch (level) {
      case Level.trace:
        return 'T';
      case Level.debug:
        return 'D';
      case Level.info:
        return 'I';
      case Level.warning:
        return 'W';
      case Level.error:
        return 'E';
      case Level.fatal:
        return 'F';
      case Level.off:
        return 'O';
      case Level.all:
        return 'A';
      default:
        return 'T';
    }
  }
}

class _CallerFrame {
  final String sourceUri;
  final String className;
  final String methodName;
  final String codeLine;

  const _CallerFrame({
    required this.sourceUri,
    required this.className,
    required this.methodName,
    required this.codeLine,
  });
}
