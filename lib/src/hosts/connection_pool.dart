import 'package:flutter/foundation.dart';
import 'package:terminal_studio/src/core/log/app_logger.dart';

class _PoolEntry<T> {
  final T client;
  int refCount;

  _PoolEntry(this.client) : refCount = 1;
}

/// Generic reference-counted connection pool.
///
/// [T] is the connection object type (e.g. [SSHClient]).
/// Callers supply [getDone] and [doClose] callbacks so this class has no
/// dependency on any specific connection library.
///
/// This is the testable core used by [SSHConnectionPool].
class ConnectionPool<T extends Object> {
  final Future<void> Function(T) _getDone;
  final void Function(T) _doClose;
  final AppLogger _logger;

  final _pool = <String, _PoolEntry<T>>{};

  ConnectionPool({
    required Future<void> Function(T) getDone,
    required void Function(T) doClose,
    AppLogger? logger,
  })  : _getDone = getDone,
        _doClose = doClose,
        _logger = logger ?? AppLogger.forComponent('ConnectionPool');

  /// Acquire a connection for [key], calling [connect] only when no live entry
  /// exists. Increments the reference count on cache hits.
  Future<T> acquire({
    required String key,
    required Future<T> Function() connect,
  }) async {
    final existing = _pool[key];
    if (existing != null) {
      existing.refCount++;
      _logger.i('reusing connection for $key (refCount=${existing.refCount})');
      return existing.client;
    }

    _logger.i('creating new connection for $key');
    final client = await connect();

    _getDone(client)
        .then((_) => _invalidate(key))
        .onError((_, __) => _invalidate(key));

    _pool[key] = _PoolEntry<T>(client);
    return client;
  }

  /// Decrement reference count; close and remove the entry when it reaches 0.
  void release(String key) {
    final entry = _pool[key];
    if (entry == null) return;

    entry.refCount--;
    _logger.i('released $key (refCount=${entry.refCount})');

    if (entry.refCount <= 0) {
      _logger.i('closing connection for $key');
      _doClose(entry.client);
      _pool.remove(key);
    }
  }

  void _invalidate(String key) {
    if (_pool.containsKey(key)) {
      _logger.w('invalidating $key due to remote disconnect');
      _pool.remove(key);
    }
  }

  // ── Test helpers ────────────────────────────────────────────────────────────

  /// Current reference count for [key], or 0 if no active entry.
  @visibleForTesting
  int refCountForKey(String key) => _pool[key]?.refCount ?? 0;

  /// Whether the pool contains an active entry for [key].
  @visibleForTesting
  bool hasEntry(String key) => _pool.containsKey(key);

  /// Removes all pool entries without closing clients. Use only in tests.
  @visibleForTesting
  void clearForTesting() => _pool.clear();
}
