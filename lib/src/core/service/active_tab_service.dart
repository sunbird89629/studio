import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/service/window_service.dart';
import 'package:terminal_studio/src/core/state/tabs.dart';

class ActiveTabService {
  final Ref ref;

  ActiveTabService(this.ref);

  Tabs? getActiveTabGroup() {
    return getActiveTab()?.parent;
  }

  TabItem? getActiveTab() {
    return ref.read(tabsProvider).activeTab.value;
  }

  void selectPreviousTab() {
    final tabs = getActiveTabGroup();
    if (tabs == null) return;

    final children = tabs.children;
    if (children.isEmpty) return;
    final currentTab = getActiveTab();
    if (currentTab == null) return;

    final currentIndex = children.indexOf(currentTab);
    if (currentIndex <= 0) {
      // Wrap to last tab
      children.last.activate();
    } else {
      children[currentIndex - 1].activate();
    }
  }

  void selectNextTab() {
    final tabs = getActiveTabGroup();
    if (tabs == null) return;

    final children = tabs.children;
    if (children.isEmpty) return;
    final currentTab = getActiveTab();
    if (currentTab == null) return;

    final currentIndex = children.indexOf(currentTab);
    if (currentIndex >= children.length - 1) {
      // Wrap to first tab
      children.first.activate();
    } else {
      children[currentIndex + 1].activate();
    }
  }

  void closeCurrentTabOrWindow() {
    final activeGroup = getActiveTabGroup();
    final activeTab = getActiveTab();
    if (activeGroup == null || activeTab == null) return;

    if (activeGroup.children.length > 1) {
      activeTab.detach();
    } else {
      // Single tab in this group.
      bool isOnlyGroup = false;
      final doc = ref.read(tabsProvider);

      // If doc.children has 1 item, and that item IS our activeGroup, then we are the only group.
      if (doc.children.length == 1 && doc.children.first == activeGroup) {
        isOnlyGroup = true;
      }

      if (isOnlyGroup) {
        ref.read(windowServiceProvider).closeWindow();
      } else {
        // Just a split pane, close it.
        activeTab.detach();
      }
    }
  }
}

final activeTabServiceProvider = Provider<ActiveTabService>(
  name: 'activeTabServiceProvider',
  (ref) => ActiveTabService(ref),
);
