import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/material.dart'
    show ReorderableDragStartListener, ReorderableListView;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/features/tabs/application/tabs_provider.dart';
import 'package:terminal_studio/src/features/tabs/presentation/tab_title.dart';
import 'package:terminal_studio/src/features/tabs/presentation/vertical/widgets/add_tab_button.dart';

/// A vertical left-side tab rail showing all open tabs as status-aware tiles.
///
/// Each 200px-wide tile displays:
/// - Plugin icon + title
/// - Secondary line: host name (idle) or current command (running/attention)
/// - Animated activity badge for running / attention states
class VerticalTabRail extends ConsumerWidget {
  const VerticalTabRail({super.key});

  void _onReorder(List<(TabItem, Tabs)> allTabs, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final (srcTab, srcGroup) = allTabs[oldIndex];
    final (dstTab, dstGroup) = allTabs[newIndex];

    if (srcGroup != dstGroup) return;

    srcGroup.move(srcTab, dstGroup.children.indexOf(dstTab));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTabs = ref.watch(allTabsProvider);
    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(top: 24),
            buildDefaultDragHandles: false,
            itemCount: allTabs.length,
            onReorder: (oldIndex, newIndex) => _onReorder(
              allTabs,
              oldIndex,
              newIndex,
            ),
            itemBuilder: (context, index) {
              final (tabItem, tabs) = allTabs[index];
              return ReorderableDragStartListener(
                key: ObjectKey(tabItem),
                index: index,
                child: TabTitle(tabItem: tabItem, tabs: tabs),
              );
            },
          ),
        ),
        const AddTabButton(),
      ],
    );
  }
}
