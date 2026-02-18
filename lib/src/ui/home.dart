import 'dart:io';

import 'package:context_menus/context_menus.dart';
import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/service/release_notes_service.dart';
import 'package:terminal_studio/src/core/service/tabs_service.dart';
import 'package:terminal_studio/src/core/state/copilot.dart';
import 'package:terminal_studio/src/core/state/log_visible.dart';
import 'package:terminal_studio/src/core/state/tabs.dart';
import 'package:terminal_studio/src/core/state/theme.dart';
import 'package:terminal_studio/src/hosts/local_spec.dart';
import 'package:terminal_studio/src/ui/context_menu.dart';
import 'package:terminal_studio/src/ui/copilot_sidebar.dart';
import 'package:terminal_studio/src/ui/log_sidebar.dart';
import 'package:terminal_studio/src/ui/shared/debug_indicator.dart';
import 'package:terminal_studio/src/ui/shared/release_notes_dialog.dart';
import 'package:window_manager/window_manager.dart';

/// Manages the app exit lifecycle: exits when all tabs are closed.
/// Extracted from _HomeState to keep UI and side-effect logic separate.
final _tabsLifecycleProvider = Provider<void>((ref) {
  final document = ref.read(tabsProvider);
  TabsContainer<TabsNode>? watchedRoot;

  void onRootChanged() {
    if (document.root == null || document.root!.children.isEmpty) {
      exit(0);
    }
  }

  void onDocumentChanged() {
    if (watchedRoot != document.root) {
      watchedRoot?.removeListener(onRootChanged);
      watchedRoot = document.root;
      watchedRoot?.addListener(onRootChanged);
    }
  }

  document.addListener(onDocumentChanged);

  ref.onDispose(() {
    document.removeListener(onDocumentChanged);
    watchedRoot?.removeListener(onRootChanged);
  });
});

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTabs();
      _checkReleaseNotes();
    });
  }

  void _initTabs() {
    final root = Tabs();
    ref.read(tabsServiceProvider).openTerminal(const LocalHostSpec(), tabs: root);
    ref.read(tabsProvider).setRoot(root);
  }

  void _checkReleaseNotes() async {
    final service = ref.read(releaseNotesServiceProvider);
    if (await service.checkNewVersion()) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => const ReleaseNotesDialog(),
      );
      final version = await service.getAppVersion();
      await service.markVersionAsSeen(version);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(_tabsLifecycleProvider);
    return const _AppLayout();
  }
}

class _AppLayout extends ConsumerWidget {
  const _AppLayout();

  static final _tabsTheme = TabsViewThemeData(
    backgroundColor: Colors.transparent,
    groupDividerColor: Colors.transparent,
    selectedBackgroundColor: Colors.transparent,
    tabSeparatorColor: Colors.transparent,
    hoverBackgroundColor: Colors.transparent,
    labelColor: Colors.white,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(activeThemeProvider).brightness;
    final copilotVisible = ref.watch(copilotVisibleProvider);
    final logVisible = ref.watch(logVisibleProvider);

    Widget content = TabsView(
      ref.watch(tabsProvider),
      theme: _tabsTheme,
      actionBuilder: (tabs) => _buildTabActions(context, ref, tabs),
    );

    if (copilotVisible) {
      content = Row(
        children: [
          Expanded(child: content),
          const VerticalDivider(),
          const SizedBox(width: 600, child: CopilotSidebar()),
        ],
      );
    }

    if (logVisible) {
      content = Row(
        children: [
          Expanded(child: content),
          const VerticalDivider(),
          const SizedBox(width: 400, child: LogSidebar()),
        ],
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            _buildTitlebar(brightness),
            Expanded(child: content),
          ],
        ),
        const Positioned(
          bottom: 0,
          right: 0,
          child: DebugIndicator(),
        ),
      ],
    );
  }

  Widget _buildTitlebar(Brightness brightness) {
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: kWindowCaptionHeight,
      child: WindowCaption(
        backgroundColor: _tabsTheme.selectedBackgroundColor,
        brightness: brightness,
        title: const Text('OpenTerm'),
      ),
    );
  }

  List<TabsViewAction> _buildTabActions(
    BuildContext context,
    WidgetRef ref,
    Tabs tabs,
  ) {
    return [
      TabsViewAction(
        icon: CupertinoIcons.chevron_down,
        onPressed: () {
          context.contextMenuOverlay.show(DropdownContextMenu(tabs));
        },
      ),
      TabsViewAction(
        icon: CupertinoIcons.add,
        onPressed: () {
          ref
              .read(tabsServiceProvider)
              .openTerminal(const LocalHostSpec(), tabs: tabs);
        },
      ),
    ];
  }
}
