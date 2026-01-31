import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/utils/ai_logger.dart';

final logServiceProvider = Provider<AILogger>((ref) {
  return AILogger();
});
