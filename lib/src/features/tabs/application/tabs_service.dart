import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/platform/hosts/host_connector.dart';
import 'package:terminal_studio/src/platform/hosts/fs.dart';
import 'package:terminal_studio/src/platform/plugins/plugin_runtime.dart';
import 'package:terminal_studio/src/features/tabs/application/active_tab_service.dart';
import 'package:terminal_studio/src/platform/plugins/plugin_manager_provider.dart';
import 'package:terminal_studio/src/features/terminal/application/terminal_plugin.dart';
import 'package:terminal_studio/src/features/tabs/application/code_editor_tab.dart';
import 'package:terminal_studio/src/features/tabs/application/plugin_tab.dart';

class TabsService {
  final Ref ref;

  TabsService(this.ref);

  void openTerminal(HostSpec hostSpec, {Tabs? tabs, bool activate = true}) {
    return openPlugin(hostSpec, TerminalPlugin(),
        tabs: tabs, activate: activate);
  }

  void openPlugin(
    HostSpec host,
    Plugin plugin, {
    Tabs? tabs,
    bool activate = true,
  }) {
    openTab(
      PluginTab(plugin, ref.read(pluginManagerProvider(host))),
      tabs: tabs,
      activate: activate,
    );
  }

  void openFile(File file, {Tabs? tabs, bool activate = true}) {
    openTab(CodeEditorTab(file), tabs: tabs, activate: activate);
  }

  void openTab(TabItem tab, {Tabs? tabs, bool activate = true}) {
    final targetTabGroup =
        tabs ?? ref.read(activeTabServiceProvider).getActiveTabGroup();

    if (targetTabGroup == null) {
      return;
    }

    targetTabGroup.add(tab);

    if (activate) {
      tab.activate();
    }
  }
}

final tabsServiceProvider = Provider(
  name: 'tabsServiceProvider',
  (ref) => TabsService(ref),
);
