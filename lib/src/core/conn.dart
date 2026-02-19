import 'package:flutter/material.dart';
import 'package:terminal_studio/src/core/host.dart';
import 'package:terminal_studio/src/core/utils/app_logger.dart';

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

abstract class HostConnector<T extends Host> with ChangeNotifier {
  T? _host;

  T? get host => _host;

  final _logger =
      AppLogger(context: const LogContext(component: 'HostConnector'));

  HostConnectorStatus _state = HostConnectorStatus.initialized;
  HostConnectorStatus get state => _state;

  set state(HostConnectorStatus value) {
    if (_state != value) {
      _state = value;
      notifyListeners();
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
    _logger.i('HostConnector: state set to connecting. Notify called.');

    try {
      _logger.i('HostConnector: calling createHost()...');
      _host = await createHost();
      _logger
          .i('HostConnector: createHost returned $_host. Notifying listeners.');
      notifyListeners();

      _host!.done.then((_) => _onDone(), onError: _onError);

      state = HostConnectorStatus.connected;
      _logger.i('HostConnector: state set to connected. Notify called.');
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

  void _onDone() {
    _host = null;
    state = HostConnectorStatus.disconnected;
  }

  void _onError(Object error) {
    _host = null;
    state = HostConnectorStatus.aborted;
  }
}
