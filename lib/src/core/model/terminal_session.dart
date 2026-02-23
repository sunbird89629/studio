import 'package:terminal_studio/src/core/conn.dart';

enum SessionStatus { active, exited, disconnected }

/// Domain object representing a single terminal shell session.
///
/// Created when a [TerminalPlugin] mounts and registered with [SessionManager].
/// Removed when the plugin unmounts.
class TerminalSession {
  final String id;
  final HostSpec hostSpec;
  final DateTime createdAt;
  SessionStatus status;
  int? exitCode;

  TerminalSession({
    required this.id,
    required this.hostSpec,
    required this.createdAt,
    this.status = SessionStatus.active,
    this.exitCode,
  });
}

/// Singleton registry of all live [TerminalSession]s.
///
/// Uses a static singleton (same pattern as `LogService.instance`) because
/// session state does not need UI observation via Riverpod — it is queried
/// programmatically by components such as the OpenTerm public API.
class SessionManager {
  SessionManager._();

  static final instance = SessionManager._();

  final _sessions = <String, TerminalSession>{};

  /// All currently tracked sessions.
  Iterable<TerminalSession> get all => _sessions.values;

  /// Returns the session with [id], or `null` if not found.
  TerminalSession? get(String id) => _sessions[id];

  /// Register a newly created session. Called from `TerminalPlugin.onMounted`.
  void register(TerminalSession session) {
    _sessions[session.id] = session;
  }

  /// Mark a session as exited with [code]. Called when the shell process exits.
  void markExited(String id, int code) {
    final session = _sessions[id];
    if (session == null) return;
    session.status = SessionStatus.exited;
    session.exitCode = code;
  }

  /// Remove a session from the registry. Called from `TerminalPlugin.onUnmounted`.
  void remove(String id) {
    _sessions.remove(id);
  }
}
