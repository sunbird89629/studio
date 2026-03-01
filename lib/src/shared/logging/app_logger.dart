import 'package:logger/logger.dart';
import 'package:terminal_studio/src/shared/logging/log_service_output.dart';
import 'package:terminal_studio/src/shared/logging/printer/one_line_log_printer.dart';

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
  static AppLogger forComponent(String component, {bool enable = false}) {
    return _cache.putIfAbsent(
      component,
      () => AppLogger(
        context: LogContext(component: component),
        enable: enable,
      ),
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
    _emit(
      Level.debug,
      message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void i(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _emit(
      Level.info,
      message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void w(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _emit(
      Level.warning,
      message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _emit(
      Level.error,
      message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _emit(
    Level level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!enable) return;

    _logger.log(
      level,
      StructuredLogMessage(
        moduleName: _globalContext.component ?? 'app',
        content: message,
      ),
      error: error,
      stackTrace: stackTrace ?? StackTrace.current,
      time: DateTime.now(),
    );
  }
}
