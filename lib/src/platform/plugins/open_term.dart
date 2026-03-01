import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/features/tabs/application/tabs_provider.dart';
import 'package:terminal_studio/src/features/terminal/presentation/terminal_plugin.dart';
import 'package:terminal_studio/src/features/tabs/presentation/plugin_tab.dart';

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

  List<TabItem> _allItems() {
    final root = _container.read(tabsProvider).root;
    if (root == null) return [];
    return _collectItems(root);
  }

  static List<TabItem> _collectItems(TabsContainer<dynamic> node) {
    if (node is Tabs) return List<TabItem>.from(node.children);
    return [
      for (final child in node.children)
        if (child is TabsContainer) ..._collectItems(child),
    ];
  }

  int get tabCount => _allItems().length;

  List<OpenTermTab> get tabs {
    final items = _allItems();
    return [
      for (var i = 0; i < items.length; i++) OpenTermTab._(items[i], i),
    ];
  }

  OpenTermTab? get activeTab {
    final active = _container.read(tabsProvider).activeTab.value;
    if (active == null) return null;
    final items = _allItems();
    final index = items.indexOf(active);
    if (index == -1) return null;
    return OpenTermTab._(active, index);
  }

  OpenTermTab? operator [](int index) {
    final items = _allItems();
    if (index < 0 || index >= items.length) return null;
    return OpenTermTab._(items[index], index);
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
      if (plugin is TerminalPlugin) {
        return OpenTermTerminal._(plugin);
      }
    }
    return null;
  }
}

/// Provides programmatic access to a terminal tab's state.
class OpenTermTerminal {
  final TerminalPlugin _plugin;

  OpenTermTerminal._(this._plugin);

  /// Best-effort tracking of the text currently typed at the prompt.
  String get currentInput => _plugin.currentInput;

  /// Commands committed so far (on Enter), capped at 500 entries.
  List<String> get commandHistory => _plugin.commandHistory;

  int get viewWidth => _plugin.terminal.viewWidth;

  int get viewHeight => _plugin.terminal.viewHeight;

  /// Write [text] to the terminal as if the user typed it.
  void write(String text) => _plugin.terminal.textInput(text);
}
