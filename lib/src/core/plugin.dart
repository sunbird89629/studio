import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/conn.dart';
import 'package:terminal_studio/src/core/exceptions.dart';
import 'package:terminal_studio/src/core/host.dart';
import 'package:terminal_studio/src/core/utils/app_logger.dart';

abstract class Plugin {
  PluginManager? _manager;

  /// The plugin manager that manages the lifecycle of this plugin.
  PluginManager get manager {
    if (_manager == null) {
      throw PluginException('Plugin is not attached to a manager');
    }

    return _manager!;
  }

  Ref get ref => manager.ref;

  HostSpec? _hostSpec;

  /// The interface through which the plugin can read information about the host.
  /// This is available after [onMounted] is called.
  HostSpec get hostSpec {
    if (_hostSpec == null) {
      throw PluginException('Plugin has not been mounted');
    }
    return _hostSpec!;
  }

  Host? _host;

  /// The interface through which the plugin can interact with the host. Access
  /// to this property will throw an exception if the host has not been connected.
  Host get host {
    if (_host == null) {
      throw PluginException('Plugin has not been connected to a host.');
    }
    return _host!;
  }

  /// Whether the plugin is currently mounted.
  bool get mounted => _manager != null;

  /// Whether the plugin is connected to a host.
  bool get connected => _host != null;

  /// The title of the plugin. Usually displayed as the tab title.
  final title = ValueNotifier<String?>(null);

  /// Called when the plugin is mounted to a host. After this method is called,
  /// the [hostSpec] property will be available.
  void onMounted() {}

  /// Called when the plugin is unmounted from a host. After this method is
  /// called, the [hostSpec] property will no longer be available.
  void onUnmounted() {}

  /// Called when the host that this plugin is mounted to is connected. This
  /// method may be called multiple times if the host is disconnected and
  /// reconnected.
  void onConnected() {}

  /// Called when the host that this plugin is mounted to is disconnected. This
  /// method may be called multiple times if the host is disconnected and
  /// reconnected.
  void onDisconnected() {}

  /// Called when the state of the host that this plugin is mounted to changes.
  void onConnectionStatus(HostConnectorStatus status) {}

  /// Builds the UI for this plugin. This may be called multiple times during
  /// the lifetime of the plugin, for example when the plugin is moved to a new
  /// tab group.
  Widget build(BuildContext context);
}

class PluginManager with ChangeNotifier {
  final HostSpec hostSpec;
  final Ref ref;

  PluginManager(this.hostSpec, this.ref);

  final _logger = AppLogger.forComponent('PluginManager');

  final _plugins = <Plugin>[];

  List<Plugin> get plugins => List.unmodifiable(_plugins);

  Host? _host;

  void add(Plugin plugin) {
    if (plugin._manager != null) {
      throw PluginException('Plugin is already mounted');
    }

    // Assign manager and spec BEFORE calling lifecycle methods so that
    // onMounted() / onConnected() can safely access [manager] and [hostSpec].
    plugin._manager = this;
    plugin._hostSpec = hostSpec;
    plugin.onMounted();

    if (_host != null) {
      plugin._host = _host;
      plugin.onConnected();
    }

    _plugins.add(plugin);
    notifyListeners();
  }

  void remove(Plugin plugin) {
    if (plugin._manager != this) {
      throw PluginException('Plugin is not mounted');
    }
    _plugins.remove(plugin);

    // Use try/finally so the plugin is always fully detached from this manager
    // even if onUnmounted() throws, preventing a dangling _manager reference.
    try {
      plugin.onUnmounted();
    } finally {
      plugin._manager = null;
      plugin._hostSpec = null;
      plugin._host = null;
      notifyListeners();
    }
  }

  void onConnected(Host host) {
    _logger.i(
        'PluginManager.onConnected called with host: $host. Current plugins: ${_plugins.length}');
    if (_host != null) {
      _logger.w(
          'PluginManager: Warning - already connected to $_host. Replacing with $host.');
    }

    _host = host;

    for (final plugin in _plugins) {
      _logger.i(
          'PluginManager: notifying plugin ${plugin.runtimeType} of connection.');
      plugin._host = host;
      plugin.onConnected();
      _logger.i(
          'PluginManager: plugin ${plugin.runtimeType} onConnected completed.');
    }
  }

  void onDisconnected() {
    if (_host == null) {
      throw PluginException('plugin manager is not connected');
    }

    _host = null;

    for (final plugin in _plugins) {
      plugin._host = null;
      plugin.onDisconnected();
    }
  }

  void onConnectionStatusChanged(HostConnectorStatus status) {
    for (final plugin in _plugins) {
      plugin.onConnectionStatus(status);
    }
  }
}
