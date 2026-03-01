import 'package:logger/logger.dart';
import 'package:terminal_studio/src/shared/logging/log_entry.dart';
import 'package:terminal_studio/src/shared/logging/log_service.dart';

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
