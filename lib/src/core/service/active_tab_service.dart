import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
}

final activeTabServiceProvider = Provider<ActiveTabService>(
  name: 'activeTabServiceProvider',
  (ref) => ActiveTabService(ref),
);
