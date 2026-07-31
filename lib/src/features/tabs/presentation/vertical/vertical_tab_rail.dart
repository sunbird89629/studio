import 'dart:io';

import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/material.dart'
    show ReorderableDragStartListener, ReorderableListView;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_term/src/features/tabs/application/tabs_provider.dart';
import 'package:open_term/src/features/tabs/presentation/tab_title.dart';
import 'package:open_term/src/features/tabs/presentation/vertical/widgets/add_tab_button.dart';
import 'package:open_term/src/shared/widgets/macos_titlebar.dart';
import 'package:window_manager/window_manager.dart';

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
        if (Platform.isMacOS) const _TrafficLightHotZone(),
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

/// Hot zone at the top of the vertical tab rail that reveals the native macOS
/// traffic light buttons on hover and collapses when the cursor leaves.
class _TrafficLightHotZone extends StatefulWidget {
  const _TrafficLightHotZone();

  @override
  State<_TrafficLightHotZone> createState() => _TrafficLightHotZoneState();
}

class _TrafficLightHotZoneState extends State<_TrafficLightHotZone>
    with WindowListener {
  static const _hotZoneHeight = 8.0;

  bool _hovered = false;
  bool _fullScreen = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowEnterFullScreen() {
    setState(() => _fullScreen = true);
    super.onWindowEnterFullScreen();
  }

  @override
  void onWindowLeaveFullScreen() {
    setState(() => _fullScreen = false);
    super.onWindowLeaveFullScreen();
  }

  @override
  Widget build(BuildContext context) {
    if (_fullScreen) return const SizedBox.shrink();

    final height = _hovered ? kMacosTitlebarHeight : _hotZoneHeight;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        height: height,
      ),
    );
  }
}
