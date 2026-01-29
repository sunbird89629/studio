import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/conn.dart';
import 'package:terminal_studio/src/core/host.dart';

final connectorProvider = Provider.family(
  name: 'connectorProvider',
  (ref, HostSpec config) => config.createConnector(),
);

final connectorStatusProvider =
    StreamProvider.family<({HostConnectorStatus status, Host? host}), HostSpec>(
  name: 'connectorStatusProvider',
  (ref, HostSpec config) {
    final connector = ref.watch(connectorProvider(config));

    return Stream<({HostConnectorStatus status, Host? host})>.multi(
        (controller) {
      print('connectorStatusProvider: Stream created for $connector');
      controller.add((status: connector.state, host: connector.host));

      void listener() {
        print(
            'connectorStatusProvider: listener called. State: ${connector.state}, Host: ${connector.host}');
        controller.add((status: connector.state, host: connector.host));
      }

      connector.addListener(listener);

      controller.onCancel = () {
        print('connectorStatusProvider: Stream cancelled');
        connector.removeListener(listener);
      };
    });
  },
);

final hostProvider = Provider.family<Host?, HostSpec>(
  name: 'hostProvider',
  (ref, spec) {
    // Watch status to force rebuild when connector state/host changes
    final status = ref.watch(connectorStatusProvider(spec));
    print('hostProvider: rebuild triggered. StatusAsync: $status');
    return ref.watch(connectorProvider(spec)).host;
  },
);
