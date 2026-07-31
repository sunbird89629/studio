import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_term/src/platform/hosts/connection_pool.dart';

// ---------------------------------------------------------------------------
// Fake connection handle – stands in for SSHClient in unit tests.
// Only needs the two properties ConnectionPool actually touches:
//   • done  – completes when the connection closes
//   • close – marks the handle as closed
// ---------------------------------------------------------------------------

class _FakeHandle {
  final _done = Completer<void>();
  bool closed = false;

  Future<void> get done => _done.future;

  void close() {
    closed = true;
    if (!_done.isCompleted) _done.complete();
  }
}

ConnectionPool<_FakeHandle> _makePool() => ConnectionPool<_FakeHandle>(
      getDone: (h) => h.done,
      doClose: (h) => h.close(),
    );

void main() {
  group('ConnectionPool ref-counting', () {
    test('connect factory called once for a fresh key', () async {
      final pool = _makePool();
      int calls = 0;
      final handle = _FakeHandle();

      await pool.acquire(
        key: 'alice@host:22',
        connect: () async {
          calls++;
          return handle;
        },
      );

      expect(calls, 1);
      expect(pool.hasEntry('alice@host:22'), isTrue);
      expect(pool.refCountForKey('alice@host:22'), 1);
    });

    test('connect factory NOT called on second acquire for same key', () async {
      final pool = _makePool();
      int calls = 0;
      final handle = _FakeHandle();

      Future<_FakeHandle> factory() async {
        calls++;
        return handle;
      }

      await pool.acquire(key: 'alice@host:22', connect: factory);
      await pool.acquire(key: 'alice@host:22', connect: factory);

      expect(calls, 1, reason: 'factory should only run once');
      expect(pool.refCountForKey('alice@host:22'), 2);
    });

    test('different keys each call the factory', () async {
      final pool = _makePool();
      int calls = 0;

      Future<_FakeHandle> factory() async {
        calls++;
        return _FakeHandle();
      }

      await pool.acquire(key: 'alice@host1:22', connect: factory);
      await pool.acquire(key: 'alice@host2:22', connect: factory);

      expect(calls, 2);
      expect(pool.hasEntry('alice@host1:22'), isTrue);
      expect(pool.hasEntry('alice@host2:22'), isTrue);
    });

    test('release decrements ref count without removing entry', () async {
      final pool = _makePool();
      final handle = _FakeHandle();

      await pool.acquire(key: 'bob@host:22', connect: () async => handle);
      await pool.acquire(key: 'bob@host:22', connect: () async => handle);
      expect(pool.refCountForKey('bob@host:22'), 2);

      pool.release('bob@host:22');

      expect(pool.refCountForKey('bob@host:22'), 1);
      expect(pool.hasEntry('bob@host:22'), isTrue);
    });

    test('release removes entry and calls close when ref count reaches zero',
        () async {
      final pool = _makePool();
      final handle = _FakeHandle();

      await pool.acquire(key: 'carol@host:22', connect: () async => handle);
      pool.release('carol@host:22');

      expect(pool.hasEntry('carol@host:22'), isFalse);
      expect(handle.closed, isTrue);
    });

    test('release on unknown key is a safe no-op', () {
      final pool = _makePool();
      expect(() => pool.release('nobody@ghost:22'), returnsNormally);
    });

    test('acquire after full release creates a new connection', () async {
      final pool = _makePool();
      int calls = 0;

      Future<_FakeHandle> factory() async {
        calls++;
        return _FakeHandle();
      }

      await pool.acquire(key: 'dave@host:22', connect: factory);
      pool.release('dave@host:22'); // refCount → 0, entry removed

      await pool.acquire(key: 'dave@host:22', connect: factory);

      expect(calls, 2, reason: 'factory must run again after entry is evicted');
    });

    test('remote disconnect invalidates pool entry', () async {
      final pool = _makePool();
      final handle = _FakeHandle();

      await pool.acquire(key: 'eve@host:22', connect: () async => handle);
      expect(pool.hasEntry('eve@host:22'), isTrue);

      // Simulate the remote side closing the connection.
      handle.close();
      // Allow the done Future callback to propagate.
      await Future.delayed(Duration.zero);

      expect(pool.hasEntry('eve@host:22'), isFalse);
    });
  });
}
