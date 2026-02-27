import 'dart:async';

import 'package:flutter/material.dart';
import 'package:terminal_studio/src/core/host.dart';
import 'package:terminal_studio/src/core/log/app_logger.dart';

abstract class HostSpec {
  String get name;

  HostConnector createConnector();
}

enum HostConnectorStatus {
  initialized,
  connecting,
  connected,
  disconnected,
  aborted,
}

/// Manages the connection lifecycle for a [Host].
///
/// State changes are broadcast on [stream] — a broadcast [StreamController]
/// that replaces the previous [ChangeNotifier] integration. Consumers should
/// use [connectorStatusProvider] (a Riverpod [StreamProvider]) rather than
/// listening directly.
///
/// Call [dispose] (wired via `ref.onDispose` in [connectorProvider]) to close
/// the underlying stream when the provider is torn down.
abstract class HostConnector<T extends Host> {
  T? _host;

  T? get host => _host;

  final _logger = AppLogger.forComponent('HostConnector');

  final _controller =
      StreamController<({HostConnectorStatus status, Host? host})>.broadcast();

  /// Stream of status+host snapshots emitted on every state change.
  Stream<({HostConnectorStatus status, Host? host})> get stream =>
      _controller.stream;

  HostConnectorStatus _state = HostConnectorStatus.initialized;
  HostConnectorStatus get state => _state;

  set state(HostConnectorStatus value) {
    if (_state != value) {
      _state = value;
      _notify();
    }
  }

  void _notify() {
    if (!_controller.isClosed) {
      _controller.add((status: _state, host: _host));
    }
  }

  @protected
  Future<T> createHost();

  Future<void> connect() async {
    _logger
        .i('HostConnector: connect() called for $this. Current state: $state');
    if (state == HostConnectorStatus.connected ||
        state == HostConnectorStatus.connecting) {
      _logger.i('HostConnector: already connecting/connected. Aborting.');
      return;
    }

    state = HostConnectorStatus.connecting;
    _logger.i('HostConnector: state set to connecting. Notified stream.');

    try {
      _logger.i('HostConnector: calling createHost()...');
      _host = await createHost();
      _logger
          .i('HostConnector: createHost returned $_host. Notifying stream.');
      _notify(); // emit new host before setting state to connected

      _host!.done.then((_) => _onDone(), onError: _onError);

      state = HostConnectorStatus.connected;
      _logger.i('HostConnector: state set to connected. Notified stream.');
    } catch (e, st) {
      _logger.e('HostConnector: error during connect',
          error: e, stackTrace: st);
      state = HostConnectorStatus.disconnected;
    }
  }

  Future<void> disconnect() async {
    await _host?.disconnect();
    _host = null;
    state = HostConnectorStatus.disconnected;
  }

  /// Closes the broadcast stream. Called by [connectorProvider] via
  /// `ref.onDispose` when the provider is torn down.
  void dispose() {
    _controller.close();
  }

  void _onDone() {
    _host = null;
    state = HostConnectorStatus.disconnected;
  }

  void _onError(Object error) {
    _host = null;
    state = HostConnectorStatus.aborted;
  }
}
