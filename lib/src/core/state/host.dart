import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/conn.dart';
import 'package:terminal_studio/src/core/host.dart';

final connectorProvider = Provider.family(
  name: 'connectorProvider',
  (ref, HostSpec config) => config.createConnector(),
);

// Since HostConnector is a Notifier, we wrap it in a FamilyNotifier
class _HostConnectorNotifier extends FamilyNotifier<HostConnectorStatus, HostSpec> {
  late HostConnector _connector;

  @override
  HostConnectorStatus build(HostSpec arg) {
    _connector = ref.watch(connectorProvider(arg));
    // Need to watch for state changes
    return _connector.state;
  }
}

final connectorStatusProvider = FamilyNotifierProvider<_HostConnectorNotifier, HostConnectorStatus, HostSpec>(
  name: 'connectorStatusProvider',
);

final hostProvider = Provider.family<Host?, HostSpec>(
  name: 'hostProvider',
  (ref, spec) {
    ref.watch(connectorStatusProvider(spec));
    return ref.watch(connectorProvider(spec)).host;
  },
);
