import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_term/src/features/tabs/application/tabs_provider.dart';
import 'package:open_term/src/features/terminal/runtime/terminal_runtime.dart';
import 'package:open_term/src/features/tabs/application/plugin_tab.dart';

ProviderContainer? _container;

/// Global accessor for the terminal state. Call [initOpenTerm] first.
OpenTerm get openTerm {
  assert(_container != null, 'Call initOpenTerm() before accessing openTerm.');
  return OpenTerm._(_container!);
}

/// Wire the global [openTerm] singleton to the app's [ProviderContainer].
void initOpenTerm(ProviderContainer container) {
  _container = container;
}

/// Top-level OO API for accessing tab and terminal state.
class OpenTerm {
  final ProviderContainer _container;

  OpenTerm._(this._container);

  List<(TabItem, Tabs)> _allTabs() => _container.read(tabsProvider).allTabs;

  int get tabCount => _allTabs().length;

  List<OpenTermTab> get tabs {
    final all = _allTabs();
    return [
      for (var i = 0; i < all.length; i++) OpenTermTab._(all[i].$1, i),
    ];
  }

  OpenTermTab? get activeTab {
    final active = _container.read(tabsProvider).activeTab;
    if (active == null) return null;
    final all = _allTabs();
    final index = all.indexWhere((t) => t.$1 == active);
    if (index == -1) return null;
    return OpenTermTab._(active, index);
  }

  OpenTermTab? operator [](int index) {
    final all = _allTabs();
    if (index < 0 || index >= all.length) return null;
    return OpenTermTab._(all[index].$1, index);
  }
}

/// Represents a single tab in the tab bar.
class OpenTermTab {
  final TabItem _item;
  final int index;

  OpenTermTab._(this._item, this.index);

  String get title {
    if (_item is PluginTab) {
      final pt = _item as PluginTab;
      final pluginTitle = pt.plugin.title.value ?? '';
      final hostName = pt.manager.hostSpec.name;
      return '$pluginTitle — $hostName';
    }
    return '(tab $index)';
  }

  bool get isActive => _item.isActivated;

  void activate() => _item.activate();

  /// Non-null only when this tab hosts a [TerminalPlugin].
  OpenTermTerminal? get terminal {
    if (_item is PluginTab) {
      final plugin = (_item as PluginTab).plugin;
      if (plugin is TerminalRuntimeAccess) {
        return OpenTermTerminal._(plugin as TerminalRuntimeAccess);
      }
    }
    return null;
  }
}

/// Provides programmatic access to a terminal tab's state.
class OpenTermTerminal {
  final TerminalRuntimeAccess _runtime;

  OpenTermTerminal._(this._runtime);

  /// Best-effort tracking of the text currently typed at the prompt.
  String get currentInput => _runtime.currentInput;

  /// Commands committed so far (on Enter), capped at 500 entries.
  List<String> get commandHistory => _runtime.commandHistory;

  int get viewWidth => _runtime.viewWidth;

  int get viewHeight => _runtime.viewHeight;

  /// Write [text] to the terminal as if the user typed it.
  void write(String text) => _runtime.writeInput(text);
}
