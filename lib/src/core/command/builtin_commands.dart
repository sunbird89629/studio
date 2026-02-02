import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/command/command.dart';
import 'package:terminal_studio/src/core/service/active_tab_service.dart';
import 'package:terminal_studio/src/core/service/tabs_service.dart';
import 'package:terminal_studio/src/core/service/window_service.dart';
import 'package:terminal_studio/src/hosts/local_spec.dart';
import 'package:terminal_studio/src/ui/shortcuts.dart' as shortcuts;
import 'package:terminal_studio/src/ui/tabs/devtools_tab.dart';
import 'package:terminal_studio/src/ui/tabs/settings_tab/settings_tab.dart';
import 'package:terminal_studio/src/util/tabs_extension.dart';
import 'package:terminal_studio/src/core/service/vim_edit_service.dart';

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
  SingleActivator? get shortcut => shortcuts.openNewWindow;

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
  SingleActivator? get shortcut => shortcuts.openNewTab;

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
  SingleActivator? get shortcut => shortcuts.tabClose;

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
  SingleActivator? get shortcut => shortcuts.previousTab;

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
  SingleActivator? get shortcut => shortcuts.nextTab;

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
  SingleActivator? get shortcut => shortcuts.openSettings;

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
  SingleActivator? get shortcut => shortcuts.openDevTools;

  @override
  void execute(BuildContext context, WidgetRef ref) {
    ref.openTab(DevToolsTab());
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
  void execute(BuildContext context, WidgetRef ref) {
    ref.read(vimEditServiceProvider.notifier).open();
  }
}
