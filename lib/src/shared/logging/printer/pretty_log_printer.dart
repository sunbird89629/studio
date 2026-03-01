import 'package:logger/logger.dart';

/// Printer that outputs logs in a human-readable format for development.
class PrettyLogPrinter extends PrettyPrinter {
  PrettyLogPrinter()
      : super(
          methodCount: 1,
          errorMethodCount: 8,
          lineLength: 120,
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        );
}
