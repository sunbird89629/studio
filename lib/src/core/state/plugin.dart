import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/conn.dart';
import 'package:terminal_studio/src/core/plugin.dart';
import 'package:terminal_studio/src/core/state/host.dart';

final pluginManagerProvider = Provider.family<PluginManager, HostSpec>(
  name: 'pluginManagerProvider',
  (ref, spec) {
    final manager = PluginManager(spec);

    ref.listen(
      hostProvider(spec),
      (last, current) {
        if (last == null && current != null) {
          manager.didConnected(current);
        }

        if (last != null && current == null) {
          manager.didDisconnected();
        }
      },
      fireImmediately: true,
    );

    ref.listen(
      connectorStatusProvider(spec),
      (last, current) {
        current.whenData((data) {
          manager.didConnectionStatusChanged(data.status);

          if (data.status == HostConnectorStatus.connected &&
              data.host != null) {
            try {
              manager.didConnected(data.host!);
            } catch (_) {}
          }
        });
      },
      fireImmediately: true,
    );

    // Check initial connection status and connect if needed
    final connector = ref.read(connectorProvider(spec));
    if (connector.state == HostConnectorStatus.disconnected ||
        connector.state == HostConnectorStatus.initialized) {
      connector.connect();
    }

    return manager;
  },
);
