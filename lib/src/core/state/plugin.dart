import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/conn.dart';
import 'package:terminal_studio/src/core/plugin.dart';
import 'package:terminal_studio/src/core/state/host.dart';

final pluginManagerProvider = Provider.family<PluginManager, HostSpec>(
  name: 'pluginManagerProvider',
  (ref, spec) {
    final manager = PluginManager(spec, ref);

    // hostProvider handles connect/disconnect lifecycle
    ref.listen(
      hostProvider(spec),
      (last, current) {
        if (last == null && current != null) manager.didConnected(current);
        if (last != null && current == null) manager.didDisconnected();
      },
      fireImmediately: true,
    );

    // connectorStatusProvider handles status change notifications only
    ref.listen(
      connectorStatusProvider(spec),
      (_, current) {
        current.whenData((data) => manager.didConnectionStatusChanged(data.status));
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
