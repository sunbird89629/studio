/// Activity state for a terminal session, used by the vertical tab rail to
/// show at-a-glance status for background tabs.
enum TerminalActivityState {
  /// The terminal is not connected (session ended or not yet started).
  disconnected,

  /// The terminal is at a shell prompt, waiting for user input.
  idle,

  /// A command is currently executing.
  running,

  /// The terminal is waiting for the user to respond (e.g. a confirmation
  /// prompt). Triggered by a BEL character in the output.
  attention,
}
