import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/command/command.dart';
import 'package:terminal_studio/src/core/open_term.dart';
import 'package:terminal_studio/src/core/record/snippet_record.dart';
import 'package:terminal_studio/src/core/state/settings.dart';

/// Sends [snippet.command] to the active terminal as user input.
class SnippetCommand extends Command {
  final SnippetRecord snippet;

  SnippetCommand(this.snippet);

  @override
  String get id => 'snippet.${snippet.id}';

  @override
  String get label => snippet.name;

  @override
  String get category => 'Snippets';

  @override
  void execute(BuildContext context, WidgetRef ref) {
    openTerm.activeTab?.terminal?.write(snippet.command);
  }
}

/// Returns snippet commands derived from the current settings.
List<SnippetCommand> buildSnippetCommands(Ref ref) {
  final settings = ref.watch(settingsProvider).value;
  return (settings?.snippets ?? []).map(SnippetCommand.new).toList();
}
