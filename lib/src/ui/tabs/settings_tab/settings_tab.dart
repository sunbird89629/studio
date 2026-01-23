import 'package:flex_tabs/flex_tabs.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/state/settings.dart';
import 'package:terminal_studio/src/ui/tabs/settings_tab/settings_tab_hosts.dart';

class SettingsTab extends TabItem {
  SettingsTab() {
    title.value = const Text('Settings');
    content.value = const SettingsView();
  }
}

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoTabView(
      builder: (context) => NavigationView(
        pane: NavigationPane(
          selected: _selectedIndex,
          onChanged: (index) {
            setState(() => _selectedIndex = index);
          },
          displayMode: PaneDisplayMode.open,
          size: const NavigationPaneSize(
            openWidth: 200,
            openMinWidth: 200,
          ),
          items: [
            PaneItemHeader(header: const Text('Settings')),
            PaneItemSeparator(),
            PaneItem(
              icon: const Icon(FluentIcons.settings),
              title: const Text('General'),
              body: const GeneralSettingsView(),
            ),
            PaneItem(
              icon: const Icon(FluentIcons.server),
              title: const Text('Hosts'),
              body: const HostsSettingView(),
            ),
            PaneItem(
              icon: const Icon(FluentIcons.key_phrase_extraction),
              title: const Text('SSH keys'),
              body: const SizedBox.expand(),
            ),
          ],
        ),
      ),
    );
  }
}

class GeneralSettingsView extends ConsumerWidget {
  const GeneralSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    return settingsAsync.when(
      data: (settings) => ScaffoldPage(
        header: const PageHeader(title: Text('General')),
        content: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Terminal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'Font Size: ${settings.terminalFontSize.toInt()}',
                child: Slider(
                  value: settings.terminalFontSize,
                  min: 8,
                  max: 32,
                  onChanged: (v) {
                    settings.terminalFontSize = v;
                    settings.save();
                  },
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'Font Family',
                child: TextFormBox(
                  initialValue: settings.terminalFontFamily,
                  placeholder: 'Default',
                  onChanged: (v) {
                    settings.terminalFontFamily = v;
                    settings.save();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: ProgressRing()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}
