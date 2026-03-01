import 'package:context_menus/context_menus.dart';
import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/features/tabs/application/tabs_service.dart';
import 'package:terminal_studio/src/features/settings/application/database_providers.dart';
import 'package:terminal_studio/src/platform/hosts/local_spec.dart';
import 'package:terminal_studio/src/features/tabs/presentation/add_host_tab.dart';
import 'package:terminal_studio/src/features/settings/presentation/settings_tab.dart';
import 'package:terminal_studio/src/shared/utils/tabs_extension.dart';
import 'package:terminal_studio/src/features/copilot/application/copilot_providers.dart';

class DropdownContextMenu extends ConsumerStatefulWidget {
  const DropdownContextMenu(this.tabs, {super.key});

  final Tabs tabs;

  @override
  DropdownContextMenuState createState() => DropdownContextMenuState();
}

class DropdownContextMenuState extends ConsumerState<DropdownContextMenu>
    with ContextMenuStateMixin {
  Tabs get tabs => widget.tabs;

  @override
  Widget build(BuildContext context) {
    return cardBuilder(
      context,
      [
        buttonBuilder(
          context,
          ContextMenuButtonConfig(
            'Local',
            icon: const Icon(Icons.laptop),
            onPressed: () => handlePressed(context, () {
              final tabsService = ref.read(tabsServiceProvider);
              tabsService.openTerminal(const LocalHostSpec());
            }),
          ),
        ),
        ...buildHosts(),
        buttonBuilder(
          context,
          ContextMenuButtonConfig(
            'Add New',
            icon: const Icon(Icons.add),
            onPressed: () => handlePressed(
              context,
              () => ref.openTab(AddHostTab()),
            ),
          ),
        ),
        buildDivider(),
        buttonBuilder(
          context,
          ContextMenuButtonConfig(
            'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => handlePressed(
              context,
              () => ref.openTab(SettingsTab()),
            ),
          ),
        ),
        buildDivider(),
        buttonBuilder(
          context,
          ContextMenuButtonConfig(
            'AI Copilot',
            icon: const Icon(Icons.smart_toy_outlined),
            onPressed: () => handlePressed(
              context,
              () => ref
                  .read(copilotVisibleProvider.notifier)
                  .update((state) => !state),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> buildHosts() {
    final sshHosts = ref.watch(sshHostsProvider).asData;

    if (sshHosts == null || sshHosts.value.isEmpty) {
      return [];
    }

    final items = <Widget>[];

    for (final host in sshHosts.value) {
      items.add(
        buttonBuilder(
          context,
          ContextMenuButtonConfig(
            host.name,
            icon: const Icon(Icons.cloud_outlined),
            onPressed: () => handlePressed(context, () async {
              final tabsService = ref.read(tabsServiceProvider);
              tabsService.openTerminal(host, tabs: tabs);
            }),
          ),
        ),
      );
    }

    return items;
  }
}
