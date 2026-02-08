sealed class CloudflaredEvent {
  const CloudflaredEvent();

  factory CloudflaredEvent.fromJson(Map<String, dynamic> json) {
    final msg = json['message'] as String? ?? '';
    final level = json['level']?.toString();

    return _parseInternal(msg, level, json);
  }

  factory CloudflaredEvent.fromText(String message, String? level) {
    return _parseInternal(message, level, null);
  }

  static CloudflaredEvent _parseInternal(
      String msg, String? level, Map<String, dynamic>? raw) {
    if (msg.contains('Registered tunnel connection')) {
      // JSON: connectionID or connection, tunnelID
      // Text: connection=UUID
      final connIdMatch = RegExp(r'connection=([a-fA-F0-9-]+)').firstMatch(msg);
      return RegisteredEvent(
        id: connIdMatch?.group(1) ??
            (raw?['connectionID']?.toString() ??
                raw?['connection']?.toString() ??
                ''),
        name: raw?['tunnelID']?.toString(),
      );
    } else if (msg.contains('Your quick tunnel has been created') ||
        (msg.contains('https://') && msg.contains('.trycloudflare.com'))) {
      final urlMatch =
          RegExp(r'https://[a-zA-Z0-9-]+\.trycloudflare\.com').firstMatch(msg);
      if (urlMatch != null) {
        return QuickTunnelEvent(
          url: urlMatch.group(0)!,
        );
      }
    } else if (msg.contains('Connected to')) {
      final connIdMatch =
          RegExp(r'connection(ID)?=([a-fA-F0-9-]+)').firstMatch(msg);
      return ConnectedEvent(
        id: connIdMatch?.group(2) ?? (raw?['connectionID']?.toString() ?? ''),
        ip: raw?['ip']?.toString(),
        location: raw?['location']?.toString(),
      );
    } else if (msg.contains('Connection closed')) {
      final connIdMatch =
          RegExp(r'connection(ID)?=([a-fA-F0-9-]+)').firstMatch(msg);
      return DisconnectedEvent(
        id: connIdMatch?.group(2) ?? (raw?['connectionID']?.toString() ?? ''),
        reason: raw?['reason']?.toString(),
      );
    } else if (level == 'error' ||
        level == 'fatal' ||
        level == 'ERR' ||
        level == 'error') {
      return ErrorEvent(
        message: msg,
        level: level,
      );
    }

    return LogEvent(
      message: msg,
      level: level,
      raw: raw ?? {},
    );
  }
}

class RegisteredEvent extends CloudflaredEvent {
  final String id;
  final String? name;
  const RegisteredEvent({required this.id, this.name});
}

class QuickTunnelEvent extends CloudflaredEvent {
  final String url;
  const QuickTunnelEvent({required this.url});
}

class ConnectedEvent extends CloudflaredEvent {
  final String id;
  final String? ip;
  final String? location;
  const ConnectedEvent({required this.id, this.ip, this.location});
}

class DisconnectedEvent extends CloudflaredEvent {
  final String id;
  final String? reason;
  const DisconnectedEvent({required this.id, this.reason});
}

class ErrorEvent extends CloudflaredEvent {
  final String message;
  final String? level;
  const ErrorEvent({required this.message, this.level});
}

class LogEvent extends CloudflaredEvent {
  final String message;
  final String? level;
  final Map<String, dynamic> raw;
  const LogEvent({required this.message, this.level, required this.raw});
}
