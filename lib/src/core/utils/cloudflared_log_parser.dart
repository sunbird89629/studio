import 'dart:convert';
import 'package:terminal_studio/src/core/model/cloudflared_event.dart';

class CloudflaredLogParser {
  static CloudflaredEvent? parseLine(String line) {
    if (line.trim().isEmpty) return null;

    try {
      // cloudflared logs can be plain text or JSON.
      // We are interested in JSON logs.
      if (!line.startsWith('{')) return null;

      final Map<String, dynamic> json = jsonDecode(line);
      return CloudflaredEvent.fromJson(json);
    } catch (_) {
      // Not a valid JSON or doesn't match our expectations
      return null;
    }
  }
}
