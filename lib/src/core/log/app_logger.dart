import 'package:logger/logger.dart';
import 'package:terminal_studio/src/core/log/log_entry.dart';
import 'package:terminal_studio/src/core/log/printer/one_line_log_printer.dart';
import 'package:terminal_studio/src/core/service/log_service.dart';

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

/// LogOutput that bridges logger events into [LogService].
class LogServiceOutput extends LogOutput {
  final String channel;

  LogServiceOutput(this.channel);

  @override
  void output(OutputEvent event) {
    final level = switch (event.level) {
      Level.trace || Level.debug => LogLevel.debug,
      Level.info => LogLevel.info,
      Level.warning => LogLevel.warning,
      Level.error || Level.fatal => LogLevel.error,
      _ => LogLevel.info,
    };
    LogService.instance.log(channel, level, event.lines.join('\n'));
  }
}

/// A wrapper around [Logger] that provides structured logging.
class AppLogger {
  final Logger _logger;
  final LogContext _globalContext;
  final bool enable;

  static final Map<String, AppLogger> _cache = {};

  /// Returns a cached [AppLogger] for [component], creating one if needed.
  ///
  /// Prefer this over the default constructor for class-level loggers to avoid
  /// allocating a new [Logger] per instance.
  static AppLogger forComponent(String component) {
    return _cache.putIfAbsent(
      component,
      () => AppLogger(context: LogContext(component: component)),
    );
  }

  AppLogger({
    Logger? logger,
    LogContext context = const LogContext(),
    this.enable = true,
  })  : _globalContext = context,
        _logger = logger ??
            Logger(
              // printer: kReleaseMode ? JsonLogPrinter() : PrettyLogPrinter(),
              printer: OneLineLogPrinter(),
              output: MultiOutput([
                ConsoleOutput(),
                LogServiceOutput(context.component ?? 'app'),
              ]),
            );

  // Create a child logger with additional context
  AppLogger child({
    String? component,
    Map<String, dynamic>? additional,
  }) {
    return AppLogger(
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

  void d(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.d(
      message,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

  void i(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.i(
      message,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

  void w(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.w(
      message,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

  void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.e(
      message,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }
}
