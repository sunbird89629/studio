import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/command/command.dart';
import 'package:terminal_studio/src/core/state/theme.dart';

/// Command to select a specific theme.
class SelectThemeCommand extends Command {
  final String themeId;
  final String themeName;

  SelectThemeCommand({
    required this.themeId,
    required this.themeName,
  });

  @override
  String get id => 'theme.select.$themeId';

  @override
  String get label => 'Theme: $themeName';

  @override
  String get category => 'Preferences';

  @override
  void execute(BuildContext context, WidgetRef ref) {
    ref.read(themeServiceProvider).setTheme(themeId);
  }
}

/// Command to toggle between light and dark themes.
class ToggleThemeCommand extends Command {
  @override
  String get id => 'theme.toggle';

  @override
  String get label => 'Toggle Theme';

  @override
  String get category => 'Preferences';

  @override
  void execute(BuildContext context, WidgetRef ref) {
    ref.read(themeServiceProvider).toggleTheme();
  }
}

/// Returns a list of all theme-related commands.
List<Command> getThemeCommands(WidgetRef ref) {
  final registry = ref.read(themeRegistryProvider);
  final commands = <Command>[
    ToggleThemeCommand(),
  ];

  for (final theme in registry.all) {
    commands.add(SelectThemeCommand(
      themeId: theme.id,
      themeName: theme.displayName,
    ));
  }

  return commands;
}
