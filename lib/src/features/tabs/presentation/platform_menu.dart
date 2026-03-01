import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/features/tabs/application/active_tab_service.dart';
import 'package:terminal_studio/src/features/command_palette/application/command_palette_notifier.dart';
import 'package:terminal_studio/src/features/tabs/application/tabs_service.dart';
import 'package:terminal_studio/src/features/command_palette/application/vim_edit_notifier.dart';
import 'package:terminal_studio/src/features/tabs/application/window_service.dart';
import 'package:terminal_studio/src/platform/hosts/local_spec.dart';
import 'package:terminal_studio/src/features/settings/application/keymap_providers.dart';
import 'package:terminal_studio/src/features/command_palette/application/shortcuts.dart';
import 'package:terminal_studio/src/features/tabs/application/devtools_tab.dart';
import 'package:terminal_studio/src/features/settings/application/settings_tab.dart';
import 'package:terminal_studio/src/shared/utils/tabs_extension.dart';

class GlobalPlatformMenu extends ConsumerStatefulWidget {
  const GlobalPlatformMenu({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GlobalPlatformMenu> createState() => _GlobalPlatformMenuState();
}

class _GlobalPlatformMenuState extends ConsumerState<GlobalPlatformMenu> {
  @override
  Widget build(BuildContext context) {
    final keymapAsync = ref.watch(keymapProvider);
    final keymap = keymapAsync.value ?? defaultKeymaps;

    return PlatformMenuBar(
      menus: <PlatformMenuItem>[
        PlatformMenu(
          label: 'TerminalStudio',
          menus: [
            if (PlatformProvidedMenuItem.hasMenu(
                PlatformProvidedMenuItemType.about))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.about,
              ),
            PlatformMenuItemGroup(
              members: [
                if (PlatformProvidedMenuItem.hasMenu(
                    PlatformProvidedMenuItemType.servicesSubmenu))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.servicesSubmenu,
                  ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                if (PlatformProvidedMenuItem.hasMenu(
                    PlatformProvidedMenuItemType.hide))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.hide,
                  ),
                if (PlatformProvidedMenuItem.hasMenu(
                    PlatformProvidedMenuItemType.hideOtherApplications))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.hideOtherApplications,
                  ),
              ],
            ),
            if (PlatformProvidedMenuItem.hasMenu(
                PlatformProvidedMenuItemType.quit))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.quit,
              ),
          ],
        ),
        PlatformMenu(
          label: 'File',
          menus: [
            PlatformMenuItem(
              label: 'New Window',
              shortcut: keymap[ShortcutId.newWindow]!,
              onSelected: () {
                ref.read(windowServiceProvider).createWindow();
              },
            ),
            PlatformMenuItem(
              label: 'New Tab',
              shortcut: keymap[ShortcutId.newTab]!,
              onSelected: () {
                ref
                    .read(tabsServiceProvider)
                    .openTerminal(const LocalHostSpec());
              },
            ),
            PlatformMenuItem(
              label: 'Close Tab',
              shortcut: keymap[ShortcutId.closeTab]!,
              onSelected: () {
                ref.read(activeTabServiceProvider).closeCurrentTabOrWindow();
              },
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Show Previous Tab',
                  shortcut: keymap[ShortcutId.previousTab]!,
                  onSelected: () {
                    ref.read(activeTabServiceProvider).selectPreviousTab();
                  },
                ),
                PlatformMenuItem(
                  label: 'Show Next Tab',
                  shortcut: keymap[ShortcutId.nextTab]!,
                  onSelected: () {
                    ref.read(activeTabServiceProvider).selectNextTab();
                  },
                ),
              ],
            ),
          ],
        ),
        PlatformMenu(
          label: 'Edit',
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Copy',
                  shortcut: keymap[ShortcutId.terminalCopy]!,
                  onSelected: () {
                    final primaryContext = primaryFocus?.context;
                    if (primaryContext == null) {
                      return;
                    }
                    Actions.invoke(
                      primaryContext,
                      CopySelectionTextIntent.copy,
                    );
                  },
                ),
                PlatformMenuItem(
                  label: 'Paste',
                  shortcut: keymap[ShortcutId.terminalPaste]!,
                  onSelected: () {
                    final primaryContext = primaryFocus?.context;
                    if (primaryContext == null) {
                      return;
                    }
                    Actions.invoke(
                      primaryContext,
                      const PasteTextIntent(SelectionChangedCause.keyboard),
                    );
                  },
                ),
                PlatformMenuItem(
                  label: 'Select All',
                  shortcut: keymap[ShortcutId.terminalSelectAll]!,
                  onSelected: () {
                    final primaryContext = primaryFocus?.context;
                    if (primaryContext == null) {
                      return;
                    }
                    try {
                      Actions.maybeFind<Intent>(
                        primaryContext,
                        intent: const SelectAllTextIntent(
                            SelectionChangedCause.keyboard),
                      );
                    } catch (e, st) {
                      debugPrint(e.toString());
                      debugPrint(st.toString());
                    }
                    Actions.invoke<Intent>(
                      primaryContext,
                      const SelectAllTextIntent(SelectionChangedCause.keyboard),
                    );
                  },
                ),
              ],
            ),
            if (PlatformProvidedMenuItem.hasMenu(
                PlatformProvidedMenuItemType.quit))
              const PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.quit),
          ],
        ),
        PlatformMenu(
          label: 'View',
          menus: [
            if (PlatformProvidedMenuItem.hasMenu(
                PlatformProvidedMenuItemType.toggleFullScreen))
              const PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.toggleFullScreen),
            PlatformMenuItem(
              label: 'Command Palette',
              shortcut: keymap[ShortcutId.commandPalette]!,
              onSelected: () {
                ref.read(commandPaletteServiceProvider.notifier).toggle();
              },
            ),
            PlatformMenuItem(
              label: 'Vim Edit',
              shortcut: keymap[ShortcutId.vimEdit]!,
              onSelected: () {
                ref.read(vimEditServiceProvider.notifier).open();
              },
            ),
            PlatformMenuItem(
              label: 'Settings',
              shortcut: keymap[ShortcutId.openSettings]!,
              onSelected: () => ref.openTab(SettingsTab()),
            ),
            PlatformMenuItem(
              label: 'DevTools',
              shortcut: keymap[ShortcutId.openDevTools]!,
              onSelected: () => ref.openTab(DevToolsTab()),
            ),
          ],
        ),
      ],
      child: widget.child,
    );
  }
}
