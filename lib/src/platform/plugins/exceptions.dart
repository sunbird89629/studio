/// Base class for all Terminal Studio application exceptions.
abstract class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when an SSH socket connection cannot be established.
class SSHConnectionException extends AppException {
  const SSHConnectionException(super.message);
}

/// Thrown when SSH authentication fails.
class SSHAuthException extends AppException {
  const SSHAuthException(super.message);
}

/// Thrown on Plugin lifecycle violations (e.g. double-mount, not-mounted).
class PluginException extends AppException {
  const PluginException(super.message);
}

/// Thrown on configuration parse, load, or migration errors.
class ConfigException extends AppException {
  const ConfigException(super.message);
}
