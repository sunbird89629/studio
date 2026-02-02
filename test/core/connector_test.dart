import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_studio/src/core/conn.dart';
import 'package:terminal_studio/src/core/fs.dart';
import 'package:terminal_studio/src/core/host.dart';
import 'package:terminal_studio/src/core/state/host.dart';

class MockHost extends Host {
  final _doneCompleter = Completer<void>();

  @override
  Future<FileSystem> connectFileSystem() async {
    throw UnimplementedError();
  }

  @override
  Future<ExecutionResult> execute(String executable,
      {List<String> args = const [],
      bool root = false,
      Map<String, String>? environment}) {
    throw UnimplementedError();
  }

  @override
  Future<ExecutionSession> shell({
    Map<String, String>? environment,
    int height = 25,
    int width = 80,
    String? command,
    List<String>? args,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> disconnect() async {
    _doneCompleter.complete();
  }

  @override
  Future<void> get done => _doneCompleter.future;
}

class MockConnector extends HostConnector<MockHost> {
  @override
  Future<MockHost> createHost() async {
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 50));
    return MockHost();
  }
}

class MockHostSpec extends HostSpec {
  @override
  HostConnector createConnector() => MockConnector();

  @override
  String get name => 'Mock';
}

void main() {
  test('HostConnector updates state and notifies provider', () async {
    final container = ProviderContainer();
    final spec = MockHostSpec();

    // Listen to status provider
    AsyncValue<({HostConnectorStatus status, Host? host})>? status;
    container.listen<AsyncValue<({HostConnectorStatus status, Host? host})>>(
      connectorStatusProvider(spec),
      (previous, next) {
        status = next;
      },
      fireImmediately: true,
    );

    // Initial state might be loading or data depending on how StreamProvider behaves initially
    // StreamProvider emits AsyncLoading first usually.
    // But our implementation yields initial state immediately?
    // Actually strictly speaking StreamProvider is async.

    final connector = container.read(connectorProvider(spec));
    final connectFuture = connector.connect();

    // After calling connect, it should be connecting
    expect(connector.state, HostConnectorStatus.connecting);

    // We expect the provider to eventually emit the connecting state
    // fast forward?
    await Future.delayed(Duration.zero);

    expect(container.read(connectorStatusProvider(spec)).value?.status,
        HostConnectorStatus.connecting);

    await connectFuture;

    await Future.delayed(Duration.zero);

    expect(connector.state, HostConnectorStatus.connected);
    expect(container.read(connectorStatusProvider(spec)).value?.status,
        HostConnectorStatus.connected);
    expect(status?.value?.status, HostConnectorStatus.connected);
  });

  test('hostProvider updates when connector emits notification', () async {
    final container = ProviderContainer();
    final spec = MockHostSpec();

    // Listen to host provider
    Host? host;
    container.listen<Host?>(
      hostProvider(spec),
      (previous, next) {
        host = next;
      },
      fireImmediately: true,
    );

    expect(host, isNull);

    final connector = container.read(connectorProvider(spec));
    final connectFuture = connector.connect();

    // After connect starts, host might still be null briefly until createHost completes
    // But createHost calls notifyListeners immediately after host creation.

    await connectFuture;
    // Allow time for Stream events to propagate through Riverpod
    await Future.delayed(const Duration(milliseconds: 100));

    expect(host, isNotNull);
    expect(container.read(hostProvider(spec)), isNotNull);
  });
}
