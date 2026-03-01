/// Named log channels used across the app.
///
/// These correspond to the channel argument passed to [LogService.instance]
/// and to the `component` field in [LogContext] (used by [AppLogger]).
/// Use these constants when filtering or querying the in-app log viewer.
abstract final class LogChannels {
  static const app = 'app';
  static const tunnel = 'tunnel';
  static const remoteControl = 'RemoteControlService';
  static const terminal = 'TerminalPlugin';
  static const ssh = 'SSHConnectionPool';
  static const hostConnector = 'HostConnector';
  static const pluginManager = 'PluginManager';
}
