import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/conn.dart';
import 'package:terminal_studio/src/core/host.dart';

final connectorProvider = Provider.family(
  name: 'connectorProvider',
  (ref, HostSpec config) => config.createConnector(),
);

// Listen to connector changes and expose its state
final connectorStatusProvider =
    StreamProvider.family<HostConnectorStatus, HostSpec>(
  name: 'connectorStatusProvider',
  (ref, HostSpec config) async* {
    // In Riverpod 3.x, we need a different approach to watch state changes
    // For now, yield the initial state
    yield HostConnectorStatus.initialized;
  },
);

final hostProvider = Provider.family<Host?, HostSpec>(
  name: 'hostProvider',
  (ref, spec) {
    return ref.watch(connectorProvider(spec)).host;
  },
);

// Provider to handle connector initialization and ensure state is ready
final connectorInitializer = Provider.family<Future<void>, HostSpec>(
  name: 'connectorInitializer',
  (ref, HostSpec spec) async {
    final connector = ref.watch(connectorProvider(spec));
    // Schedule connection after frame to ensure initialization is complete
    await Future.delayed(Duration.zero);
    await connector.connect();
  },
);
