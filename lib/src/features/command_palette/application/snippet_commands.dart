import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/features/command_palette/application/command.dart';
import 'package:terminal_studio/src/platform/plugins/open_term.dart';
import 'package:terminal_studio/src/shared/models/records/snippet_record.dart';
import 'package:terminal_studio/src/features/settings/application/settings_providers.dart';

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
