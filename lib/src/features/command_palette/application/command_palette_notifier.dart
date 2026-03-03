import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/features/command_palette/application/command.dart';
import 'package:terminal_studio/src/features/command_palette/application/builtin_commands.dart';
import 'package:terminal_studio/src/features/command_palette/application/command_registry.dart';
import 'package:terminal_studio/src/features/command_palette/application/snippet_commands.dart';
import 'package:terminal_studio/src/features/command_palette/application/theme_commands.dart';
import 'package:terminal_studio/src/shared/theme/theme_providers.dart';

/// Builds the full command list consumed by the command palette widget.
final commandPaletteCommandsProvider = Provider<List<Command>>((ref) {
  final registry = CommandRegistry();

  registry.registerAll(builtinCommands);

  final themeRegistry = ref.watch(themeRegistryProvider);
  registry.register(ToggleThemeCommand());
  for (final theme in themeRegistry.all) {
    registry.register(SelectThemeCommand(
      themeId: theme.id,
      themeName: theme.displayName,
    ));
  }

  registry.registerAll(buildSnippetCommands(ref));
  return registry.all;
});
