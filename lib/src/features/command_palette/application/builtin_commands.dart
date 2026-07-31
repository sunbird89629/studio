import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_term/src/features/command_palette/application/command.dart';
import 'package:open_term/src/features/tabs/application/active_tab_service.dart';
import 'package:open_term/src/features/tabs/application/tabs_service.dart';
import 'package:open_term/src/features/tabs/application/window_service.dart';
import 'package:open_term/src/shared/state/log_visible_provider.dart';
import 'package:open_term/src/platform/hosts/local_spec.dart';
import 'package:open_term/src/features/command_palette/application/shortcuts.dart';
import 'package:open_term/src/features/tabs/application/devtools_tab.dart';
import 'package:open_term/src/features/settings/application/settings_tab.dart';
import 'package:open_term/src/shared/utils/tabs_extension.dart';
import 'package:open_term/src/features/command_palette/application/vim_edit_notifier.dart';

/// 内置命令列表
final builtinCommands = <Command>[
  // File 类命令
  _NewWindowCommand(),
  _NewTabCommand(),
  _CloseTabCommand(),
  _PreviousTabCommand(),
  _NextTabCommand(),

  // View 类命令
  _OpenSettingsCommand(),
  _OpenDevToolsCommand(),
  _ToggleLogPanelCommand(),

  // Tools
  _VimEditCommand(),
];

// ============================================================================
// File 类命令
// ============================================================================

class _NewWindowCommand extends Command {
  @override
  String get id => 'file.newWindow';

  @override
  String get label => 'New Window';

  @override
  String get category => 'File';

  @override
  String? get shortcutId => ShortcutId.newWindow;

  @override
  void execute(BuildContext context, WidgetRef ref) {
    ref.read(windowServiceProvider).createWindow();
  }
}

class _NewTabCommand extends Command {
  @override
  String get id => 'file.newTab';

  @override
  String get label => 'New Terminal Tab';

  @override
  String get category => 'File';

  @override
  String? get shortcutId => ShortcutId.newTab;

  @override
  void execute(BuildContext context, WidgetRef ref) {
    ref.read(tabsServiceProvider).openTerminal(const LocalHostSpec());
  }
}

class _CloseTabCommand extends Command {
  @override
  String get id => 'file.closeTab';

  @override
  String get label => 'Close Tab';

  @override
  String get category => 'File';

  @override
  String? get shortcutId => ShortcutId.closeTab;

  @override
  void execute(BuildContext context, WidgetRef ref) {
    ref.read(activeTabServiceProvider).closeCurrentTabOrWindow();
  }
}

class _PreviousTabCommand extends Command {
  @override
  String get id => 'file.previousTab';

  @override
  String get label => 'Previous Tab';

  @override
  String get category => 'File';

  @override
  String? get shortcutId => ShortcutId.previousTab;

  @override
  void execute(BuildContext context, WidgetRef ref) {
    ref.read(activeTabServiceProvider).selectPreviousTab();
  }
}

class _NextTabCommand extends Command {
  @override
  String get id => 'file.nextTab';

  @override
  String get label => 'Next Tab';

  @override
  String get category => 'File';

  @override
  String? get shortcutId => ShortcutId.nextTab;

  @override
  void execute(BuildContext context, WidgetRef ref) {
    ref.read(activeTabServiceProvider).selectNextTab();
  }
}

// ============================================================================
// View 类命令
// ============================================================================

class _OpenSettingsCommand extends Command {
  @override
  String get id => 'view.settings';

  @override
  String get label => 'Open Settings';

  @override
  String get category => 'View';

  @override
  String? get shortcutId => ShortcutId.openSettings;

  @override
  void execute(BuildContext context, WidgetRef ref) {
    ref.openTab(SettingsTab());
  }
}

class _OpenDevToolsCommand extends Command {
  @override
  String get id => 'view.devtools';

  @override
  String get label => 'Open DevTools';

  @override
  String get category => 'View';

  @override
  String? get shortcutId => ShortcutId.openDevTools;

  @override
  void execute(BuildContext context, WidgetRef ref) {
    ref.openTab(DevToolsTab());
  }
}

class _ToggleLogPanelCommand extends Command {
  @override
  String get id => 'view.toggleLogPanel';

  @override
  String get label => 'Toggle Log Panel';

  @override
  String get category => 'View';

  @override
  void execute(BuildContext context, WidgetRef ref) {
    final current = ref.read(logVisibleProvider);
    ref.read(logVisibleProvider.notifier).state = !current;
  }
}

// ============================================================================
// Tools 类命令
// ============================================================================

class _VimEditCommand extends Command {
  @override
  String get id => 'tools.vimEdit';

  @override
  String get label => 'Fast Vim Edit';

  @override
  String get category => 'Tools';

  @override
  String? get shortcutId => ShortcutId.vimEdit;

  @override
  void execute(BuildContext context, WidgetRef ref) {
    ref.read(vimEditServiceProvider.notifier).open();
  }
}
