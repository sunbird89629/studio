import 'package:flex_tabs/flex_tabs.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/state/settings.dart';
import 'package:terminal_studio/src/ui/tabs/settings_tab/settings_profiles.dart';
import 'package:terminal_studio/src/ui/tabs/settings_tab/settings_remote_control.dart';
import 'package:terminal_studio/src/ui/tabs/settings_tab/settings_shortcuts.dart';
import 'package:terminal_studio/src/ui/tabs/settings_tab/settings_tab_hosts.dart';
import 'package:terminal_studio/src/ui/tabs/settings_tab/about_settings_view.dart';

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
              icon: const Icon(FluentIcons.contact),
              title: const Text('Profiles'),
              body: const ProfilesSettingsView(),
            ),
            PaneItem(
              icon: const Icon(FluentIcons.keyboard_classic),
              title: const Text('Keyboard Shortcuts'),
              body: const ShortcutsSettingsView(),
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
            PaneItem(
              icon: const Icon(FluentIcons.remote),
              title: const Text('Remote Control'),
              body: const RemoteControlSettingsView(),
            ),
            PaneItem(
              icon: const Icon(FluentIcons.info),
              title: const Text('About'),
              body: const AboutSettingsView(),
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
              // ── Terminal Section ──
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
                  placeholder: 'Hack Nerd Font Mono',
                  onChanged: (v) {
                    settings.terminalFontFamily = v;
                    settings.save();
                  },
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'Line Height: ${settings.lineHeight.toStringAsFixed(1)}',
                child: Slider(
                  value: settings.lineHeight,
                  min: 1.0,
                  max: 2.0,
                  divisions: 10,
                  onChanged: (v) {
                    settings.lineHeight = v;
                    settings.save();
                  },
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label:
                    'Letter Spacing: ${settings.letterSpacing.toStringAsFixed(1)}',
                child: Slider(
                  value: settings.letterSpacing,
                  min: -1.0,
                  max: 5.0,
                  divisions: 12,
                  onChanged: (v) {
                    settings.letterSpacing = v;
                    settings.save();
                  },
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'Scrollback Lines',
                child: NumberBox<int>(
                  value: settings.scrollback,
                  min: 100,
                  max: 100000,
                  onChanged: (v) {
                    if (v != null) {
                      settings.scrollback = v;
                      settings.save();
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'Cursor Shape',
                child: ComboBox<String>(
                  value: settings.cursorShape,
                  items: const [
                    ComboBoxItem(value: 'block', child: Text('Block █')),
                    ComboBoxItem(value: 'beam', child: Text('Beam |')),
                    ComboBoxItem(
                        value: 'underline', child: Text('Underline _')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      settings.cursorShape = v;
                      settings.save();
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              ToggleSwitch(
                checked: settings.cursorBlink,
                onChanged: (v) {
                  settings.cursorBlink = v;
                  settings.save();
                },
                content: const Text('Cursor Blink'),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label:
                    'Background Opacity: ${settings.backgroundOpacity.toStringAsFixed(2)}',
                child: Slider(
                  value: settings.backgroundOpacity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  onChanged: (v) {
                    settings.backgroundOpacity = v;
                    settings.save();
                  },
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'Padding: ${settings.padding.toInt()}',
                child: Slider(
                  value: settings.padding,
                  min: 0,
                  max: 32,
                  divisions: 32,
                  onChanged: (v) {
                    settings.padding = v;
                    settings.save();
                  },
                ),
              ),
              const SizedBox(height: 16),
              ToggleSwitch(
                checked: settings.copyOnSelect,
                onChanged: (v) {
                  settings.copyOnSelect = v;
                  settings.save();
                },
                content: const Text('Copy on Select'),
              ),

              // ── Shell Section ──
              const SizedBox(height: 32),
              const Text('Shell',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'Shell Path (empty = system default)',
                child: TextFormBox(
                  initialValue: settings.shell ?? '',
                  placeholder: '/bin/zsh',
                  onChanged: (v) {
                    settings.shell = v.isEmpty ? null : v;
                    settings.save();
                  },
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'Shell Arguments (comma-separated)',
                child: TextFormBox(
                  initialValue: settings.shellArgs?.join(', ') ?? '',
                  placeholder: '--login',
                  onChanged: (v) {
                    settings.shellArgs = v.isEmpty
                        ? null
                        : v.split(',').map((e) => e.trim()).toList();
                    settings.save();
                  },
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'Working Directory (empty = \$HOME)',
                child: TextFormBox(
                  initialValue: settings.workingDirectory ?? '',
                  placeholder: '~',
                  onChanged: (v) {
                    settings.workingDirectory = v.isEmpty ? null : v;
                    settings.save();
                  },
                ),
              ),
              const SizedBox(height: 16),
              ToggleSwitch(
                checked: settings.preserveCWD,
                onChanged: (v) {
                  settings.preserveCWD = v;
                  settings.save();
                },
                content: const Text('Preserve Working Directory on New Tab'),
              ),

              // ── AI Section ──
              const SizedBox(height: 32),
              const Text('AI Copilot',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'OpenRouter API Key',
                child: PasswordBox(
                  controller: TextEditingController(text: settings.aiApiKey),
                  placeholder: 'Enter your OpenRouter key here',
                  onChanged: (v) {
                    settings.aiApiKey = v;
                    settings.save();
                  },
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'Model (OpenRouter format)',
                child: TextFormBox(
                  initialValue: settings.aiModel,
                  placeholder: 'google/gemini-2.0-flash-exp:free',
                  onChanged: (v) {
                    settings.aiModel = v;
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
