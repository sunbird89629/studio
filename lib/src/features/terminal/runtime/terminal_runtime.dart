import 'package:flutter/foundation.dart';
import 'package:open_term/src/platform/hosts/host.dart';
import 'package:open_term/src/shared/state/terminal_activity_provider.dart';

/// Write-only capability used by non-terminal features (e.g. remote control).
abstract class TerminalInputSink {
  Future<void> writeInput(String text);
}

/// Read-only capability consumed by integrations (e.g. OpenTerm API).
abstract class TerminalReadModel {
  String get currentInput;

  List<String> get commandHistory;

  int get viewWidth;

  int get viewHeight;

  String get terminalTitle;

  ValueListenable<TerminalActivityState> get activity;
}

/// Broadcast write endpoint used by [BroadcastService].
abstract class TerminalBroadcastParticipant {
  void writeBroadcast(Uint8List bytes);
}

/// Full runtime capability surface exposed by terminal-like plugins.
abstract class TerminalRuntimeAccess
    implements
        TerminalInputSink,
        TerminalReadModel,
        TerminalBroadcastParticipant {
  ExecutionSession? get session;
}
