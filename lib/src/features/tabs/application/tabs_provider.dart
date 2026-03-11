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
    document.activeTab.addListener(_onActiveTabChanged);
  }

  void _onActiveTabChanged() {
    notifyListeners();
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
    document.activeTab.removeListener(_onActiveTabChanged);
    for (final g in _watchedGroups) {
      g.removeListener(_onChanged);
    }
    document.dispose();
    super.dispose();
  }
}

// ─── State ────────────────────────────────────────────────────────────────────

/// Immutable snapshot of the tab tree, recomputed on every change.
typedef TabsState = ({
  List<(TabItem, Tabs)> allTabs,
  TabItem? activeTab,
});

// ─── Riverpod Notifier ────────────────────────────────────────────────────────

/// Single data source for all tab state. Bridges [_TabsDocumentBridge] into
/// Riverpod 3.x reactivity: each tab-tree change recomputes [TabsState] so
/// all `ref.watch(tabsProvider)` consumers receive a fresh snapshot.
class TabsNotifier extends Notifier<TabsState> {
  late final _TabsDocumentBridge _bridge;

  @override
  TabsState build() {
    _bridge = _TabsDocumentBridge();
    _bridge.addListener(_onChanged);
    ref.onDispose(_bridge.dispose);
    return _computeState();
  }

  void _onChanged() => state = _computeState();

  TabsState _computeState() {
    final result = <(TabItem, Tabs)>[];
    final root = _bridge.document.root;
    if (root != null) _collectTabs(root, result);
    return (
      allTabs: result,
      activeTab: _bridge.document.activeTab.value,
    );
  }

  // ─── Mutations ─────────────────────────────────────────────────────────────

  void setRoot(TabsContainer<TabsNode> root) => _bridge.document.setRoot(root);

  void openTab(TabItem tab) {
    _bridge.document.root?.add(tab);
    tab.activate();
  }

  /// Returns true when [group] is the only top-level tab group in the document.
  bool isOnlyGroup(Tabs group) {
    final children = _bridge.document.children;
    return children.length == 1 && children.first == group;
  }

  // ─── Internal document access ───────────────────────────────────────────────

  /// Direct access to [TabsDocument] — only for [tabsDocumentProvider] and
  /// the two-level lifecycle listener in [_tabsLifecycleProvider].
  TabsDocument get document => _bridge.document;
}

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

/// Primary tabs provider. [ref.watch] returns a [TabsState] snapshot;
/// access [tabsProvider.notifier.document] for mutations.
final tabsProvider = NotifierProvider<TabsNotifier, TabsState>(TabsNotifier.new);

// ─── Derived providers (projections) ─────────────────────────────────────────

/// Stable [TabsDocument] reference for widgets like [TabsView] that manage
/// their own internal reactivity.
final tabsDocumentProvider = Provider<TabsDocument>((ref) {
  return ref.read(tabsProvider.notifier).document;
});

/// Flattened list of all (TabItem, owning Tabs group) pairs in tree order.
final allTabsProvider = Provider<List<(TabItem, Tabs)>>((ref) {
  return ref.watch(tabsProvider).allTabs;
});

/// The currently active [TabItem].
final activeTabProvider = Provider<TabItem?>((ref) {
  return ref.watch(tabsProvider).activeTab;
});
