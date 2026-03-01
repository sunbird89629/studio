import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/platform/hosts/host_connector.dart';
import 'package:terminal_studio/src/platform/plugins/plugin_runtime.dart';
import 'package:terminal_studio/src/platform/hosts/host_providers.dart';

final pluginManagerProvider = Provider.family<PluginManager, HostSpec>(
  name: 'pluginManagerProvider',
  (ref, spec) {
    final manager = PluginManager(spec, ref);

    // hostProvider handles connect/disconnect lifecycle
    ref.listen(
      hostProvider(spec),
      (last, current) {
        if (last == null && current != null) manager.onConnected(current);
        if (last != null && current == null) manager.onDisconnected();
      },
      fireImmediately: true,
    );

    // connectorStatusProvider handles status change notifications only
    ref.listen(
      connectorStatusProvider(spec),
      (_, current) {
        current.whenData((data) => manager.onConnectionStatusChanged(data.status));
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
