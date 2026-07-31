import 'dart:convert';
import 'package:open_term/src/shared/models/cloudflared_event.dart';

class CloudflaredLogParser {
  static final _textLogRegex = RegExp(
      r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\s+(INF|WRN|ERR|DBG)\s+(.*)$');

  static CloudflaredEvent? parseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    try {
      // 1. Try JSON format
      if (trimmed.startsWith('{')) {
        final Map<String, dynamic> json = jsonDecode(trimmed);
        return CloudflaredEvent.fromJson(json);
      }

      // 2. Try standard text format
      final match = _textLogRegex.firstMatch(trimmed);
      if (match != null) {
        final level = match.group(1);
        final message = match.group(2) ?? '';

        return CloudflaredEvent.fromText(message, level);
      }

      // 3. Fallback to raw text if it looks like a URL or something important (loose match)
      if (trimmed.contains('https://') &&
          trimmed.contains('.trycloudflare.com')) {
        final urlMatch = RegExp(r'https://[a-zA-Z0-9-]+\.trycloudflare\.com')
            .firstMatch(trimmed);
        if (urlMatch != null) {
          return QuickTunnelEvent(url: urlMatch.group(0)!);
        }
      }
    } catch (_) {
      // Ignore parsing errors
    }
    return null;
  }
}
