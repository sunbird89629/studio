// ─── Tab Tile ────────────────────────────────────────────────────────────────

import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:terminal_studio/src/features/tabs/application/plugin_tab.dart';
import 'package:terminal_studio/src/features/tabs/presentation/close_tab_button.dart';
import 'package:terminal_studio/src/features/tabs/presentation/icons/ai_icons.dart';
import 'package:terminal_studio/src/features/tabs/presentation/vertical/widgets/vertical_tab_content_widget.dart';
import 'package:terminal_studio/src/features/terminal/application/terminal_plugin.dart';
import 'package:terminal_studio/src/shared/state/terminal_activity_provider.dart';

class TabTitle extends StatefulWidget {
  const TabTitle({
    super.key,
    required this.tabItem,
    required this.tabs,
  });

  final TabItem tabItem;
  final Tabs tabs;

  @override
  State<TabTitle> createState() => _TabTitleState();
}

class _TabTitleState extends State<TabTitle> {
  bool _hover = false;

  TabItem get _tab => widget.tabItem;

  /// Returns the TerminalPlugin if this tab hosts one; null otherwise.
  TerminalPlugin? get _terminalPlugin {
    if (_tab is PluginTab) {
      final plugin = (_tab as PluginTab).plugin;
      if (plugin is TerminalPlugin) return plugin;
    }
    return null;
  }

  /// Returns the appropriate icon based on the plugin type and running process.
  IconData get _getTabIcon {
    final title = _terminalPlugin?.terminalTitle.toLowerCase();
    if (title == null) {
      return Icons.circle_outlined;
    } else if (title.contains("claude")) {
      return AIIcons.claude;
    } else if (title.contains("codex")) {
      return AIIcons.openai;
    } else if (title.contains("opencode")) {
      return AIIcons.opencode;
    } else {
      return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final terminal = _terminalPlugin;
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.tabs,
        if (terminal != null) terminal.activityState,
      ]),
      builder: (context, _) {
        final isActive = _tab.isActivated;
        return Material(
          color: Colors.transparent,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: GestureDetector(
              onTap: _tab.activate,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: 120,
                decoration: BoxDecoration(
                  color: getBackgroundColor(isActive),
                  // border: Border(
                  //   right: BorderSide(
                  //     color: isActive
                  //         ? CupertinoColors.activeBlue
                  //         : Colors.transparent,
                  //     width: 2,
                  //   ),
                  // ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Positioned(
                    //   left: 0,
                    //   top: 0,
                    //   bottom: 0,
                    //   child: AspectRatio(
                    //     aspectRatio: 1,
                    //     child: Icon(
                    //       _getTabIcon,
                    //       size: 100,
                    //       color: Colors.white.withValues(alpha: 0.12),
                    //     ),
                    //   ),
                    // ),
                    VerticalTabContentWidget(
                      terminal: terminal,
                      isActive: isActive,
                      tab: _tab,
                    ),
                    if (terminal != null && !isActive)
                      Positioned(
                        right: 0,
                        child: _ActivityBadge(terminal: terminal),
                      ),
                    if (_hover)
                      Positioned(
                        right: 0,
                        width: 40,
                        height: 40,
                        child: CloseTabButton(onPressed: _tab.dispose),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color getBackgroundColor(bool isActive) {
    if (isActive) {
      return Colors.transparent;
    }
    //  else if (_hover) {
    //   return Colors.white.withValues(alpha: 0.06);
    // }
    else {
      return Colors.white.withValues(alpha: 0.12);
    }
  }
}

// ─── Activity badge ───────────────────────────────────────────────────────────

class _ActivityBadge extends StatefulWidget {
  const _ActivityBadge({required this.terminal});

  final TerminalPlugin terminal;

  @override
  State<_ActivityBadge> createState() => _ActivityBadgeState();
}

class _ActivityBadgeState extends State<_ActivityBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    widget.terminal.activityState.addListener(_onStateChanged);
    _syncAnimation(widget.terminal.activityState.value);
  }

  @override
  void didUpdateWidget(_ActivityBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.terminal != widget.terminal) {
      oldWidget.terminal.activityState.removeListener(_onStateChanged);
      widget.terminal.activityState.addListener(_onStateChanged);
      _syncAnimation(widget.terminal.activityState.value);
    }
  }

  @override
  void dispose() {
    widget.terminal.activityState.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    _syncAnimation(widget.terminal.activityState.value);
    setState(() {});
  }

  void _syncAnimation(TerminalActivityState state) {
    if (state == TerminalActivityState.attention) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.terminal.activityState.value;

    if (state == TerminalActivityState.idle) return const SizedBox.shrink();

    final (color, size) = switch (state) {
      TerminalActivityState.running => (CupertinoColors.activeGreen, 7.0),
      TerminalActivityState.attention => (CupertinoColors.systemOrange, 8.0),
      TerminalActivityState.disconnected => (Colors.grey, 5.0),
      TerminalActivityState.idle => (Colors.transparent, 0.0),
    };

    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: AnimatedBuilder(
        animation: _opacity,
        builder: (context, _) {
          return Opacity(
            opacity: _opacity.value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }
}
