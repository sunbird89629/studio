import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Internal ChangeNotifier bridge ──────────────────────────────────────────

/// Wraps [TabsDocument] and propagates change notifications from all child
/// [Tabs] groups upward, giving a single listener surface for the whole tree.
class _TabsDocumentBridge extends ChangeNotifier {
  final TabsDocument document = TabsDocument();
  final Set<Tabs> _watchedGroups = {};

  _TabsDocumentBridge() {
    document.addListener(_onChanged);
  }

  void _onChanged() {
    _syncGroupListeners();
    notifyListeners();
  }

  void _syncGroupListeners() {
    for (final g in _watchedGroups) {
      g.removeListener(_onChanged);
    }
    _watchedGroups.clear();

    final root = document.root;
    if (root != null) _collectGroups(root);

    for (final g in _watchedGroups) {
      g.addListener(_onChanged);
    }
  }

  void _collectGroups(TabsContainer node) {
    if (node is Tabs) {
      _watchedGroups.add(node);
    } else {
      for (final child in node.children) {
        if (child is TabsContainer) _collectGroups(child);
      }
    }
  }

  @override
  void dispose() {
    document.removeListener(_onChanged);
    for (final g in _watchedGroups) {
      g.removeListener(_onChanged);
    }
    document.dispose();
    super.dispose();
  }
}

// ─── Riverpod Notifier ────────────────────────────────────────────────────────

/// Bridges [_TabsDocumentBridge] into Riverpod 3.x reactivity via a version
/// counter. Increment [state] on every tab-tree change so that
/// `ref.watch(tabsProvider)` consumers rebuild correctly.
class TabsNotifier extends Notifier<int> {
  late final _TabsDocumentBridge _bridge;

  @override
  int build() {
    _bridge = _TabsDocumentBridge();
    _bridge.addListener(_onChanged);
    ref.onDispose(_bridge.dispose);
    return 0;
  }

  void _onChanged() => state++;

  TabsDocument get document => _bridge.document;
}

/// Primary tabs provider. [ref.watch] to subscribe to any tab-tree change;
/// access [tabsProvider.notifier.document] for the underlying [TabsDocument].
final tabsProvider = NotifierProvider<TabsNotifier, int>(TabsNotifier.new);

// ─── Derived providers ────────────────────────────────────────────────────────

/// Stable [TabsDocument] reference for widgets like [TabsView] that manage
/// their own internal reactivity.
final tabsDocumentProvider = Provider<TabsDocument>((ref) {
  return ref.read(tabsProvider.notifier).document;
});

/// Flattened list of all (TabItem, owning Tabs group) pairs in tree order.
/// Recomputes whenever the tab tree changes.
final allTabsProvider = Provider<List<(TabItem, Tabs)>>((ref) {
  ref.watch(tabsProvider);
  final result = <(TabItem, Tabs)>[];
  final root = ref.read(tabsProvider.notifier).document.root;
  if (root != null) _collectTabs(root, result);
  return result;
});

void _collectTabs(TabsContainer node, List<(TabItem, Tabs)> result) {
  if (node is Tabs) {
    for (final item in node.children) {
      result.add((item, node));
    }
  } else {
    for (final child in node.children) {
      if (child is TabsContainer) _collectTabs(child, result);
    }
  }
}

/// The currently active [TabItem], recomputes whenever the tab tree changes.
final activeTabProvider = Provider<TabItem?>((ref) {
  ref.watch(tabsProvider);
  return ref.read(tabsProvider.notifier).document.activeTab.value;
});
