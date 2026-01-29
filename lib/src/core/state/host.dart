import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/conn.dart';
import 'package:terminal_studio/src/core/host.dart';

final connectorProvider = Provider.family(
  name: 'connectorProvider',
  (ref, HostSpec config) => config.createConnector(),
);

final connectorStatusProvider = Provider.family<HostConnectorStatus, HostSpec>(
  name: 'connectorStatusProvider',
  (ref, HostSpec config) {
    final connector = ref.watch(connectorProvider(config));
    // Watch for manual state changes by accessing the connector's state
    // We can use a simple value notifier pattern if needed
    return connector.state;
  },
);

final hostProvider = Provider.family<Host?, HostSpec>(
  name: 'hostProvider',
  (ref, spec) {
    return ref.watch(connectorProvider(spec)).host;
  },
);
