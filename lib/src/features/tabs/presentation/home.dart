import 'dart:io';

import 'package:context_menus/context_menus.dart';
import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/features/copilot/application/copilot_providers.dart';
import 'package:terminal_studio/src/features/copilot/presentation/copilot_sidebar.dart';
import 'package:terminal_studio/src/features/tabs/application/tabs_provider.dart';
import 'package:terminal_studio/src/features/tabs/application/tabs_service.dart';
import 'package:terminal_studio/src/features/tabs/presentation/context_menu.dart';
import 'package:terminal_studio/src/features/tabs/presentation/log_sidebar.dart';
import 'package:terminal_studio/src/features/tabs/presentation/vertical/vertical_tab_rail.dart';
import 'package:terminal_studio/src/platform/hosts/local_spec.dart';
import 'package:terminal_studio/src/shared/state/log_visible_provider.dart';
import 'package:terminal_studio/src/shared/state/release_notes_service.dart';
import 'package:terminal_studio/src/shared/theme/theme_providers.dart';
import 'package:terminal_studio/src/shared/widgets/debug_indicator.dart';
import 'package:terminal_studio/src/shared/widgets/release_notes_dialog.dart';
import 'package:window_manager/window_manager.dart';

/// Manages the app exit lifecycle: exits when all tabs are closed.
/// Extracted from _HomeState to keep UI and side-effect logic separate.
final _tabsLifecycleProvider = Provider<void>((ref) {
  final document = ref.read(tabsProvider.notifier).document;
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
    ref
        .read(tabsServiceProvider)
        .openTerminal(const LocalHostSpec(), tabs: root);
    ref.read(tabsProvider.notifier).document.setRoot(root);
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
    tabBarHeight: 0.0,
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

    final tabsView = TabsView(
      ref.watch(tabsDocumentProvider),
      theme: _tabsTheme,
      actionBuilder: (tabs) => _buildTabActions(context, ref, tabs),
    );

    Widget content = Row(
      children: [
        const SizedBox(
          width: 200,
          child: VerticalTabRail(),
        ),
        // const VerticalDivider(width: 1, thickness: 1),
        SizedBox(width: 6),
        Expanded(child: tabsView),
      ],
    );

    final sidebars = <Widget>[
      if (copilotVisible) ...[
        const VerticalDivider(),
        const SizedBox(width: 600, child: CopilotSidebar()),
      ],
      if (logVisible) ...[
        const VerticalDivider(),
        const SizedBox(width: 400, child: LogSidebar()),
      ],
    ];
    if (sidebars.isNotEmpty) {
      content = Row(children: [Expanded(child: content), ...sidebars]);
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
    ];
  }
}
