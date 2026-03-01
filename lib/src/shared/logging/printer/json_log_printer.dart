import 'dart:convert';
import 'package:logger/logger.dart';

/// Printer that outputs logs in a compressed JSON format.
class JsonLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    var message = event.message;
    var error = event.error;
    var stack = event.stackTrace;

    Map<String, dynamic> logData = {
      'ts': event.time.toUtc().toIso8601String(),
      'lv': event.level.name.toUpperCase().substring(0, 3),
      'msg': message.toString(),
    };

    if (error != null) {
      logData['err'] = error.toString();
    }

    if (stack != null) {
      logData['stk'] = stack.toString();
    }

    try {
      return [jsonEncode(logData)];
    } catch (e) {
      return ['{"lv":"ERR","msg":"JSON encoding error: $e"}'];
    }
  }
}

