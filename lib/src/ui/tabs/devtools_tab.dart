import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/service/ssh_storage_service.dart';
import 'package:terminal_studio/src/core/state/database.dart';
import 'package:terminal_studio/src/ui/tabs/playground.dart';
import 'package:xterm/xterm.dart';

class DevToolsTab extends TabItem {
  DevToolsTab() {
    title.value = const Text('DevTools');
    content.value = DevToolsTabView(this);
  }

  final terminal = Terminal();
}

class DevToolsTabView extends ConsumerStatefulWidget {
  const DevToolsTabView(this.tab, {super.key});

  final DevToolsTab tab;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DevToolsTabViewState();
}

class _DevToolsTabViewState extends ConsumerState<DevToolsTabView> {
  DevToolsTab get tab => widget.tab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: const BoxConstraints.expand(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: _openAddHostTab,
                  child: const Text('Add SSH host'),
                ),
                OutlinedButton(
                  onPressed: _clearHosts,
                  child: const Text('Clear SSH hosts'),
                ),
                TextButton.icon(
                  onPressed: () => tab.replace(PlaygroundTab()),
                  label: const Text('Playground'),
                  icon: const Icon(Icons.rocket_launch_outlined),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TerminalView(tab.terminal),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddHostTab() {
    // ref.openTab(AddHostTab());
  }

  void _clearHosts() async {
    await ref.read(sshStorageServiceProvider).saveHosts([]);
    ref.invalidate(sshHostsProvider);
    tab.terminal.write('Cleared SSH hosts\r\n');
  }
}
