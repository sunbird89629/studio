import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/service/tabs_service.dart';
import 'package:terminal_studio/src/core/state/tabs.dart';
import 'package:terminal_studio/src/hosts/local_spec.dart';
import 'package:terminal_studio/src/ui/tabs/tab_title.dart';
import 'package:terminal_studio/src/ui/tabs/vertical/widgets/add_tab_button.dart';

/// A vertical left-side tab rail showing all open tabs as status-aware tiles.
///
/// Each 200px-wide tile displays:
/// - Plugin icon + title
/// - Secondary line: host name (idle) or current command (running/attention)
/// - Animated activity badge for running / attention states
class VerticalTabRail extends ConsumerStatefulWidget {
  const VerticalTabRail({super.key});

  @override
  ConsumerState<VerticalTabRail> createState() => _VerticalTabRailState();
}

class _VerticalTabRailState extends ConsumerState<VerticalTabRail> {
  /// Flattened list of (tabItem, owningTabsGroup) pairs in tree order.
  List<(TabItem, Tabs)> _allTabs = [];

  /// Tabs groups we're currently listening to for child changes.
  final Set<Tabs> _listenedGroups = {};

  @override
  void initState() {
    super.initState();
    final doc = ref.read(tabsProvider);
    doc.addListener(_onDocumentChanged);
    _refreshTabs(doc);
  }

  @override
  void dispose() {
    ref.read(tabsProvider).removeListener(_onDocumentChanged);
    for (final g in _listenedGroups) {
      g.removeListener(_onGroupChanged);
    }
    super.dispose();
  }

  void _onDocumentChanged() => _refreshTabs(ref.read(tabsProvider));

  void _onGroupChanged() => _refreshTabs(ref.read(tabsProvider));

  void _refreshTabs(TabsDocument doc) {
    // Remove listeners from groups no longer in the tree.
    for (final g in _listenedGroups) {
      g.removeListener(_onGroupChanged);
    }
    _listenedGroups.clear();

    final result = <(TabItem, Tabs)>[];
    final root = doc.root;
    if (root != null) _collectFromNode(root, result);

    // Attach listeners to all current groups.
    for (final (_, tabs) in result) {
      if (_listenedGroups.add(tabs)) {
        tabs.addListener(_onGroupChanged);
      }
    }

    setState(() {
      _allTabs = result;
    });
  }

  void _collectFromNode(TabsContainer node, List<(TabItem, Tabs)> result) {
    if (node is Tabs) {
      for (final item in node.children) {
        result.add((item, node));
      }
    } else {
      for (final child in node.children) {
        if (child is TabsContainer) _collectFromNode(child, result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _allTabs.length,
            itemBuilder: (context, index) {
              final (tabItem, tabs) = _allTabs[index];
              return TabTitle(
                tabItem: tabItem,
                tabs: tabs,
                index: index + 1,
              );
            },
          ),
        ),
        AddTabButton(
          onPressed: () {
            ref.read(tabsServiceProvider).openTerminal(const LocalHostSpec());
          },
        ),
      ],
    );
  }
}
