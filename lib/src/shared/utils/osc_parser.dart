import 'package:open_term/src/shared/models/shell_command_event.dart';

/// Result of parsing a raw terminal output chunk through [OscParser].
class OscParseResult {
  /// The input string with all OSC 133 sequences stripped out.
  final String cleanData;

  /// Shell lifecycle events extracted from OSC 133 sequences in the input.
  final List<ShellCommandEvent> events;

  const OscParseResult({required this.cleanData, required this.events});

  bool get hasEvents => events.isNotEmpty;
}

/// Stateless parser for OSC 133 shell-integration sequences.
///
/// OSC 133 format: `ESC ] 133 ; <param> ST`
/// where ST is either BEL (0x07) or ESC \ (0x1B 0x5C).
///
/// Recognised params:
/// - `A` — prompt start
/// - `B` — command start (cursor in input area)
/// - `C` — command execute (Enter pressed)
/// - `D;exitCode` — command done
///
/// Sequences are stripped from the output before writing to xterm, so the
/// terminal screen never shows raw escape bytes. If no OSC 133 sequences are
/// present (e.g. the user has not added the shell integration snippet), [parse]
/// returns the input unchanged with an empty event list.
///
/// **Known limitation**: If an OSC sequence is split across two output chunks
/// (rare with short OSC 133 sequences, typically ~10 bytes), the partial
/// sequence passes through to xterm unchanged. xterm's own parser handles
/// incomplete sequences gracefully.
class OscParser {
  OscParser._();

  // Matches: ESC ] 133 ; <param> (BEL | ESC \)
  static final _osc133Pattern = RegExp(
    r'\x1b\]133;([^\x07\x1b]*?)(?:\x07|\x1b\\)',
  );

  /// Parse [raw] terminal output, strip OSC 133 sequences, and extract events.
  static OscParseResult parse(String raw) {
    final events = <ShellCommandEvent>[];
    final clean = raw.replaceAllMapped(_osc133Pattern, (match) {
      final param = match.group(1) ?? '';
      final event = _parseParam(param);
      if (event != null) events.add(event);
      return '';
    });
    return OscParseResult(cleanData: clean, events: events);
  }

  static ShellCommandEvent? _parseParam(String param) {
    switch (param) {
      case 'A':
        return const PromptStart();
      case 'B':
        return const CommandStart();
      case 'C':
        return const CommandExecute();
      default:
        if (param.startsWith('D')) {
          // D  or  D;exitCode
          final semi = param.indexOf(';');
          final codeStr = semi == -1 ? '' : param.substring(semi + 1);
          return CommandDone(exitCode: int.tryParse(codeStr) ?? 0);
        }
        return null;
    }
  }
}
