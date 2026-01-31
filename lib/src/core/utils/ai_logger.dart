import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Context associated with a log entry.
class LogContext {
  final String? traceId;
  final String? userId;
  final String? component;
  final Map<String, dynamic>? additional;

  const LogContext({
    this.traceId,
    this.userId,
    this.component,
    this.additional,
  });

  Map<String, dynamic> toJson() {
    return {
      if (traceId != null) 'tid': traceId,
      if (userId != null) 'uid': userId,
      if (component != null) 'cmp': component,
      if (additional != null) ...additional!,
    };
  }
}

/// A wrapper around [Logger] that provides AI-friendly structured logging.
class AILogger {
  final Logger _logger;
  final LogContext _globalContext;

  AILogger({
    Logger? logger,
    LogContext context = const LogContext(),
  })  : _logger = logger ??
            Logger(
              printer: kReleaseMode ? AIJsonPrinter() : AIPrettyPrinter(),
              output: MultiOutput([
                ConsoleOutput(),
              ]),
            ),
        _globalContext = context;

  // Create a child logger with additional context
  AILogger child({
    String? component,
    Map<String, dynamic>? additional,
  }) {
    return AILogger(
      logger: _logger,
      context: LogContext(
        traceId: _globalContext.traceId,
        userId: _globalContext.userId,
        component: component ?? _globalContext.component,
        additional: {
          ...?_globalContext.additional,
          ...?additional,
        },
      ),
    );
  }

  void d(String message,
      {LogContext? context, Object? error, StackTrace? stackTrace}) {
    _logger.d(message,
        error: error, stackTrace: stackTrace, time: DateTime.now());
  }

  void i(String message,
      {LogContext? context, Object? error, StackTrace? stackTrace}) {
    _logger.i(message,
        error: error, stackTrace: stackTrace, time: DateTime.now());
  }

  void w(String message,
      {LogContext? context, Object? error, StackTrace? stackTrace}) {
    _logger.w(message,
        error: error, stackTrace: stackTrace, time: DateTime.now());
  }

  void e(String message,
      {LogContext? context, Object? error, StackTrace? stackTrace}) {
    _logger.e(message,
        error: error, stackTrace: stackTrace, time: DateTime.now());
  }
}

/// Printer that outputs logs in a compressed JSON format suitable for AI ingestion.
class AIJsonPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    var message = event.message;
    var error = event.error;
    var stack = event.stackTrace;

    Map<String, dynamic> logData = {
      'ts': event.time.toUtc().toIso8601String(),
      'lv':
          event.level.name.toUpperCase().substring(0, 3), // ERR, WRN, INF, DBG
      'msg': message.toString(),
    };

    if (error != null) {
      logData['err'] = error.toString();
    }

    if (stack != null) {
      logData['stk'] = stack.toString();
    }

    // We can't access AILogger context here directly as LogEvent doesn't carry custom data easily
    // in the standard Logger package without wrapping the message.
    // For now, we rely on the message being the primary payload or injecting context into the message.
    // A more advanced implementation would wrap the LogEvent.

    try {
      return [jsonEncode(logData)];
    } catch (e) {
      return ['{"lv":"ERR","msg":"JSON encoding error: $e"}'];
    }
  }
}

/// Printer that outputs logs in a human-readable format for development.
class AIPrettyPrinter extends PrettyPrinter {
  AIPrettyPrinter()
      : super(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: true,
          printEmojis: true,
          printTime: true,
        );
}
