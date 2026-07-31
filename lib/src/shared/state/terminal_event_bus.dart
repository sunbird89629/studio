import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_term/src/shared/state/terminal_output_event.dart';

/// Broadcast stream of terminal output events, decoupling [TerminalPlugin]
/// from consumers such as [RemoteControlService].
///
/// Each event carries a [TerminalOutputEvent.sessionId] so consumers can
/// filter by session when multiple terminal tabs are open.
class TerminalEventBus {
  final _controller = StreamController<TerminalOutputEvent>.broadcast();

  Stream<TerminalOutputEvent> get outputStream => _controller.stream;

  void emitOutput({required String sessionId, required String data}) {
    _controller.add(TerminalOutputEvent(
      sessionId: sessionId,
      data: data,
      timestamp: DateTime.now(),
    ));
  }

  void dispose() => _controller.close();
}

final terminalEventBusProvider = Provider<TerminalEventBus>((ref) {
  final bus = TerminalEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});
