/// Shell integration events extracted from OSC 133 sequences in terminal output.
///
/// Shells emit these sequences when the user has added the Terminal Studio
/// shell integration snippet to their RC file. See [ShellIntegration] for the
/// scripts. The terminal parses them via [OscParser] to gain command-level
/// semantic awareness.
sealed class ShellCommandEvent {
  const ShellCommandEvent();
}

/// OSC 133 ; A — the shell is about to draw a prompt.
class PromptStart extends ShellCommandEvent {
  const PromptStart();
}

/// OSC 133 ; B — the shell has drawn the prompt; cursor is in command-input area.
class CommandStart extends ShellCommandEvent {
  const CommandStart();
}

/// OSC 133 ; C — the user pressed Enter; the command is now executing.
class CommandExecute extends ShellCommandEvent {
  const CommandExecute();
}

/// OSC 133 ; D ; `exitCode` — the command finished with [exitCode].
class CommandDone extends ShellCommandEvent {
  final int exitCode;
  const CommandDone({required this.exitCode});
}
