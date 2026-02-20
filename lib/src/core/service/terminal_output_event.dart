/// A terminal output event broadcast by [TerminalEventBus].
///
/// Carries [sessionId] so consumers can filter output per terminal session,
/// [data] as the decoded UTF-8 text (OSC sequences already stripped), and
/// [timestamp] for ordering and latency measurement.
class TerminalOutputEvent {
  final String sessionId;
  final String data;
  final DateTime timestamp;

  const TerminalOutputEvent({
    required this.sessionId,
    required this.data,
    required this.timestamp,
  });
}
