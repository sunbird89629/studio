import 'package:flutter/material.dart';
import 'package:terminal_studio/src/core/host.dart';

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
    print('HostConnector: connect() called for $this. Current state: $state');
    if (state == HostConnectorStatus.connected ||
        state == HostConnectorStatus.connecting) {
      print('HostConnector: already connecting/connected. Aborting.');
      return;
    }

    state = HostConnectorStatus.connecting;
    print('HostConnector: state set to connecting. Notify called.');

    try {
      print('HostConnector: calling createHost()...');
      _host = await createHost();
      print('HostConnector: createHost returned $_host. Notifying listeners.');
      notifyListeners();

      _host!.done.then((_) => _onDone(), onError: _onError);

      state = HostConnectorStatus.connected;
      print('HostConnector: state set to connected. Notify called.');
    } catch (e, st) {
      print('HostConnector: error during connect: $e\n$st');
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
