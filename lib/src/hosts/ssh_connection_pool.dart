import 'package:dartssh2/dartssh2.dart';
import 'package:terminal_studio/src/hosts/connection_pool.dart';

/// Singleton SSH connection pool.
///
/// Multiple [SSHConnector] instances targeting the same host reuse the same
/// underlying [SSHClient], opening additional SSH channels instead of new TCP
/// connections. This makes opening a second terminal tab to the same SSH host
/// nearly instant.
///
/// Reference counting manages lifetime: [acquire] increments the count,
/// [release] decrements it and closes the underlying client when it reaches 0.
///
/// Uses a static singleton (same pattern as `LogService.instance`) because SSH
/// connection state does not need UI observation via Riverpod.
class SSHConnectionPool {
  SSHConnectionPool._()
      : _pool = ConnectionPool<SSHClient>(
          getDone: (c) => c.done,
          doClose: (c) => c.close(),
        );

  static final instance = SSHConnectionPool._();

  final ConnectionPool<SSHClient> _pool;

  static String _key(String username, String host, int port) =>
      '$username@$host:$port';

  /// Acquire a connected [SSHClient] for the given coordinates.
  ///
  /// If a live entry already exists for `username@host:port`, its reference
  /// count is incremented and the cached client is returned immediately.
  /// Otherwise [connect] is called to create a fresh connection.
  Future<SSHClient> acquire({
    required String username,
    required String host,
    required int port,
    required Future<SSHClient> Function() connect,
  }) =>
      _pool.acquire(key: _key(username, host, port), connect: connect);

  /// Release one reference to the connection for `username@host:port`.
  ///
  /// When the reference count reaches zero the underlying [SSHClient] is
  /// closed and the pool entry is removed.
  void release(String username, String host, int port) =>
      _pool.release(_key(username, host, port));
}
