/// Shell integration scripts that emit OSC 133 sequences.
///
/// Users add the appropriate snippet to their shell RC file to enable
/// command-level semantic awareness in Terminal Studio. The app parses
/// these sequences via [OscParser] — nothing is injected automatically.
///
/// Usage (zsh): append [ShellIntegration.zsh] to `~/.zshrc`
/// Usage (bash): append [ShellIntegration.bash] to `~/.bashrc`
/// Usage (fish): append [ShellIntegration.fish] to `~/.config/fish/config.fish`
class ShellIntegration {
  ShellIntegration._();

  /// Snippet for **zsh** — add to `~/.zshrc`.
  static const String zsh = r'''
# Terminal Studio shell integration (OSC 133)
__ts_precmd() {
  printf '\033]133;D;%d\007' "$?"  # command done with exit code
  printf '\033]133;A\007'          # prompt start
}
__ts_preexec() {
  printf '\033]133;C\007'          # command execute
}
precmd_functions+=(__ts_precmd)
preexec_functions+=(__ts_preexec)
printf '\033]133;B\007'            # initial command start
''';

  /// Snippet for **bash** — add to `~/.bashrc` or `~/.bash_profile`.
  static const String bash = r'''
# Terminal Studio shell integration (OSC 133)
__ts_prompt_command() {
  local code=$?
  printf '\033]133;D;%d\007' "$code"  # command done with exit code
  printf '\033]133;A\007'             # prompt start
}
PROMPT_COMMAND="__ts_prompt_command${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
trap 'printf "\033]133;C\007"' DEBUG  # command execute
printf '\033]133;B\007'               # initial command start
''';

  /// Snippet for **fish** — add to `~/.config/fish/config.fish`.
  static const String fish = r'''
# Terminal Studio shell integration (OSC 133)
function __ts_fish_prompt --on-event fish_prompt
    printf '\033]133;D;%d\007' $status  # command done with exit code
    printf '\033]133;A\007'             # prompt start
    printf '\033]133;B\007'             # command start
end
function __ts_fish_preexec --on-event fish_preexec
    printf '\033]133;C\007'             # command execute
end
''';
}
