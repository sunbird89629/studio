sealed class CloudflaredEvent {
  const CloudflaredEvent();

  factory CloudflaredEvent.fromJson(Map<String, dynamic> json) {
    final msg = json['message'] as String? ?? '';

    if (msg.contains('Registered tunnel connection')) {
      return RegisteredEvent(
        id: json['connectionID']?.toString() ?? '',
        name: json['tunnelID']?.toString(),
      );
    } else if (msg.contains('Your quick tunnel has been created')) {
      final urlMatch =
          RegExp(r'https://[a-zA-Z0-9-]+\.trycloudflare\.com').firstMatch(msg);
      return QuickTunnelEvent(
        url: urlMatch?.group(0) ?? '',
      );
    } else if (msg.contains('Connected to')) {
      return ConnectedEvent(
        id: json['connectionID']?.toString() ?? '',
        ip: json['ip']?.toString(),
        location: json['location']?.toString(),
      );
    } else if (msg.contains('Connection closed')) {
      return DisconnectedEvent(
        id: json['connectionID']?.toString() ?? '',
        reason: json['reason']?.toString(),
      );
    } else if (json['level'] == 'error' || json['level'] == 'fatal') {
      return ErrorEvent(
        message: msg,
        level: json['level']?.toString(),
      );
    }

    return LogEvent(
      message: msg,
      level: json['level']?.toString(),
      raw: json,
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
