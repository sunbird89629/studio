import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_term/src/platform/hosts/host_connector.dart';
import 'package:open_term/src/platform/hosts/host.dart';
import 'package:open_term/src/shared/logging/app_logger.dart';

final _logger = AppLogger.forComponent('HostState');

final connectorProvider = Provider.family<HostConnector, HostSpec>(
  name: 'connectorProvider',
  (ref, HostSpec config) {
    final connector = config.createConnector();
    ref.onDispose(connector.dispose);
    return connector;
  },
);

final connectorStatusProvider =
    StreamProvider.family<({HostConnectorStatus status, Host? host}), HostSpec>(
  name: 'connectorStatusProvider',
  (ref, HostSpec config) {
    final connector = ref.watch(connectorProvider(config));

    _logger.i('connectorStatusProvider: Stream created for $connector');

    // Yield the current state immediately, then follow the connector's stream.
    return Stream.multi((controller) {
      controller.add((status: connector.state, host: connector.host));

      final sub = connector.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );

      controller.onCancel = sub.cancel;
    });
  },
);

final hostProvider = Provider.family<Host?, HostSpec>(
  name: 'hostProvider',
  (ref, spec) {
    // Watch status to force rebuild when connector state/host changes
    final status = ref.watch(connectorStatusProvider(spec));
    _logger.i('hostProvider: rebuild triggered. StatusAsync: $status');
    return ref.watch(connectorProvider(spec)).host;
  },
);
