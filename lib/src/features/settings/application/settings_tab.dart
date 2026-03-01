import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/features/settings/application/settings_providers.dart';
import 'package:terminal_studio/src/shared/widgets/fluent_form.dart';
import 'package:terminal_studio/src/features/settings/application/settings_profiles.dart';
import 'package:terminal_studio/src/features/settings/application/settings_remote_control.dart';
import 'package:terminal_studio/src/features/settings/application/settings_shortcuts.dart';
import 'package:terminal_studio/src/features/settings/application/settings_tab_hosts.dart';
import 'package:terminal_studio/src/features/settings/application/about_settings_view.dart';

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
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('General'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person),
                label: Text('Profiles'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.keyboard),
                label: Text('Shortcuts'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.dns),
                label: Text('Hosts'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.key),
                label: Text('SSH keys'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_remote),
                label: Text('Remote'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.info),
                label: Text('About'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                GeneralSettingsView(),      // 0
                ProfilesSettingsView(),     // 1
                ShortcutsSettingsView(),    // 2
                HostsSettingView(),         // 3
                SizedBox.shrink(),          // 4 SSH Keys (TODO)
                RemoteControlSettingsView(), // 5
                AboutSettingsView(),        // 6
              ],
            ),
          ),
        ],
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
      data: (settings) => Scaffold(
        appBar: AppBar(
          title: const Text('General'),
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Terminal Section ──
              FluentFormHeader('Terminal',
                  style: Theme.of(context).textTheme.titleLarge),
              Text('Font Size: ${settings.terminalFontSize.toInt()}'),
              Slider(
                value: settings.terminalFontSize,
                min: 8,
                max: 32,
                onChanged: (v) {
                  settings.terminalFontSize = v;
                  persistSettings(ref, settings);
                },
              ),
              const FluentFormSeparator(),
              TextFormField(
                initialValue: settings.terminalFontFamily,
                decoration: const InputDecoration(
                  labelText: 'Font Family',
                  hintText: 'Hack Nerd Font Mono',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  settings.terminalFontFamily = v;
                  persistSettings(ref, settings);
                },
              ),
              const FluentFormSeparator(),
              Text('Line Height: ${settings.lineHeight.toStringAsFixed(1)}'),
              Slider(
                value: settings.lineHeight,
                min: 1.0,
                max: 2.0,
                divisions: 10,
                onChanged: (v) {
                  settings.lineHeight = v;
                  persistSettings(ref, settings);
                },
              ),
              const FluentFormSeparator(),
              Text(
                  'Letter Spacing: ${settings.letterSpacing.toStringAsFixed(1)}'),
              Slider(
                value: settings.letterSpacing,
                min: -1.0,
                max: 5.0,
                divisions: 12,
                onChanged: (v) {
                  settings.letterSpacing = v;
                  persistSettings(ref, settings);
                },
              ),
              const FluentFormSeparator(),
              TextFormField(
                initialValue: settings.scrollback.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Scrollback Lines',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  final val = int.tryParse(v);
                  if (val != null) {
                    settings.scrollback = val;
                    persistSettings(ref, settings);
                  }
                },
              ),
              const FluentFormSeparator(),
              DropdownButtonFormField<String>(
                initialValue: settings.cursorShape,
                decoration: const InputDecoration(
                  labelText: 'Cursor Shape',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'block', child: Text('Block █')),
                  DropdownMenuItem(value: 'beam', child: Text('Beam |')),
                  DropdownMenuItem(
                      value: 'underline', child: Text('Underline _')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    settings.cursorShape = v;
                    persistSettings(ref, settings);
                  }
                },
              ),
              const FluentFormSeparator(),
              SwitchListTile(
                title: const Text('Cursor Blink'),
                value: settings.cursorBlink,
                onChanged: (v) {
                  settings.cursorBlink = v;
                  persistSettings(ref, settings);
                },
              ),
              const FluentFormSeparator(),
              Text(
                  'Background Opacity: ${settings.backgroundOpacity.toStringAsFixed(2)}'),
              Slider(
                value: settings.backgroundOpacity,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                onChanged: (v) {
                  settings.backgroundOpacity = v;
                  persistSettings(ref, settings);
                },
              ),
              const FluentFormSeparator(),
              Text('Padding: ${settings.padding.toInt()}'),
              Slider(
                value: settings.padding,
                min: 0,
                max: 32,
                divisions: 32,
                onChanged: (v) {
                  settings.padding = v;
                  persistSettings(ref, settings);
                },
              ),
              const FluentFormSeparator(),
              SwitchListTile(
                title: const Text('Copy on Select'),
                value: settings.copyOnSelect,
                onChanged: (v) {
                  settings.copyOnSelect = v;
                  persistSettings(ref, settings);
                },
              ),

              // ── Shell Section ──
              const FluentFormDivider(),
              FluentFormHeader('Shell',
                  style: Theme.of(context).textTheme.titleLarge),
              TextFormField(
                initialValue: settings.shell ?? '',
                decoration: const InputDecoration(
                  labelText: 'Shell Path (empty = system default)',
                  hintText: '/bin/zsh',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  settings.shell = v.isEmpty ? null : v;
                  persistSettings(ref, settings);
                },
              ),
              const FluentFormSeparator(),
              TextFormField(
                initialValue: settings.shellArgs?.join(', ') ?? '',
                decoration: const InputDecoration(
                  labelText: 'Shell Arguments (comma-separated)',
                  hintText: '--login',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  settings.shellArgs = v.isEmpty
                      ? null
                      : v.split(',').map((e) => e.trim()).toList();
                  persistSettings(ref, settings);
                },
              ),
              const FluentFormSeparator(),
              TextFormField(
                initialValue: settings.workingDirectory ?? '',
                decoration: const InputDecoration(
                  labelText: 'Working Directory (empty = \$HOME)',
                  hintText: '~',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  settings.workingDirectory = v.isEmpty ? null : v;
                  persistSettings(ref, settings);
                },
              ),
              const FluentFormSeparator(),
              SwitchListTile(
                title: const Text('Preserve Working Directory on New Tab'),
                value: settings.preserveCWD,
                onChanged: (v) {
                  settings.preserveCWD = v;
                  persistSettings(ref, settings);
                },
              ),

              // ── AI Section ──
              const FluentFormDivider(),
              FluentFormHeader('AI Copilot',
                  style: Theme.of(context).textTheme.titleLarge),
              TextFormField(
                initialValue: settings.aiApiKey,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'OpenRouter API Key',
                  hintText: 'Enter your OpenRouter key here',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  settings.aiApiKey = v;
                  persistSettings(ref, settings);
                },
              ),
              const FluentFormSeparator(),
              TextFormField(
                initialValue: settings.aiModel,
                decoration: const InputDecoration(
                  labelText: 'Model (OpenRouter format)',
                  hintText: 'google/gemini-2.0-flash-exp:free',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  settings.aiModel = v;
                  persistSettings(ref, settings);
                },
              ),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}
