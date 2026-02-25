// ─── Tab Tile ────────────────────────────────────────────────────────────────

import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:terminal_studio/src/core/state/terminal_activity.dart';
import 'package:terminal_studio/src/plugins/terminal/terminal_plugin.dart';
import 'package:terminal_studio/src/ui/tabs/plugin_tab.dart';

class TabTitle extends StatefulWidget {
  const TabTitle({
    super.key,
    required this.tabItem,
    required this.tabs,
    required this.index,
  });

  final TabItem tabItem;
  final Tabs tabs;
  final int index;

  @override
  State<TabTitle> createState() => _TabTitleState();
}

class _TabTitleState extends State<TabTitle> {
  bool _hover = false;

  TabItem get _tab => widget.tabItem;

  bool get _isActive => _tab.isActivated;

  /// Returns the TerminalPlugin if this tab hosts one; null otherwise.
  TerminalPlugin? get _terminalPlugin {
    if (_tab is PluginTab) {
      final plugin = (_tab as PluginTab).plugin;
      if (plugin is TerminalPlugin) return plugin;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tab.title.addListener(_onTitleChanged);
    widget.tabs.addListener(_onTabsChanged);
  }

  @override
  void didUpdateWidget(TabTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabItem != widget.tabItem) {
      oldWidget.tabItem.title.removeListener(_onTitleChanged);
      _tab.title.addListener(_onTitleChanged);
    }
    if (oldWidget.tabs != widget.tabs) {
      oldWidget.tabs.removeListener(_onTabsChanged);
      widget.tabs.addListener(_onTabsChanged);
    }
  }

  @override
  void dispose() {
    _tab.title.removeListener(_onTitleChanged);
    widget.tabs.removeListener(_onTabsChanged);
    super.dispose();
  }

  void _onTitleChanged() => setState(() {});
  void _onTabsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final terminal = _terminalPlugin;
    return Material(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: _tab.activate,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 120,
            decoration: BoxDecoration(
              color: _isActive
                  ? Colors.white.withValues(alpha: 0.12)
                  : _hover
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.transparent,
              border: Border(
                right: BorderSide(
                  color: _isActive
                      ? CupertinoColors.activeBlue
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Plugin icon
                      Icon(
                        Icons.terminal,
                        size: 16,
                        color: _isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 8),
                      // Title + secondary info
                      Expanded(
                        child: terminal != null
                            ? _TerminalTileContent(
                                terminal: terminal,
                                isActive: _isActive,
                              )
                            : _SimpleTileContent(
                                tabItem: _tab,
                                isActive: _isActive,
                              ),
                      ),
                      // Activity badge (right side)
                      if (terminal != null && !_isActive)
                        _ActivityBadge(terminal: terminal),
                      // Close button (on hover)
                      if (_hover) _CloseButton(onPressed: () => _tab.dispose()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tile content widgets ─────────────────────────────────────────────────────

class _TerminalTileContent extends StatefulWidget {
  const _TerminalTileContent({
    required this.terminal,
    required this.isActive,
  });

  final TerminalPlugin terminal;
  final bool isActive;

  @override
  State<_TerminalTileContent> createState() => _TerminalTileContentState();
}

class _TerminalTileContentState extends State<_TerminalTileContent> {
  @override
  void initState() {
    super.initState();
    widget.terminal.activityState.addListener(_rebuild);
    widget.terminal.title.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(_TerminalTileContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.terminal != widget.terminal) {
      oldWidget.terminal.activityState.removeListener(_rebuild);
      oldWidget.terminal.title.removeListener(_rebuild);
      widget.terminal.activityState.addListener(_rebuild);
      widget.terminal.title.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.terminal.activityState.removeListener(_rebuild);
    widget.terminal.title.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  /// Strip the dimensions suffix " — WxH" that TerminalPlugin appends to title.
  String _primaryText() {
    final raw = widget.terminal.title.value ?? 'Terminal';
    final sepIdx = raw.indexOf(' \u2014 ');
    return sepIdx >= 0 ? raw.substring(0, sepIdx) : raw;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.terminal.activityState.value;
    final lastCommand = widget.terminal.lastCommand;

    final secondaryText = switch (state) {
      TerminalActivityState.running =>
        lastCommand.isNotEmpty ? lastCommand : 'Running\u2026',
      TerminalActivityState.attention =>
        lastCommand.isNotEmpty ? lastCommand : 'Waiting\u2026',
      TerminalActivityState.disconnected => 'Disconnected',
      TerminalActivityState.idle => widget.terminal.manager.hostSpec.name,
    };

    final textOpacity = widget.isActive
        ? 1.0
        : (state == TerminalActivityState.disconnected ? 0.35 : 0.75);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _primaryText(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: textOpacity),
            fontWeight: widget.isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          secondaryText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: _secondaryColor(state, widget.isActive),
          ),
        ),
      ],
    );
  }

  Color _secondaryColor(TerminalActivityState state, bool isActive) {
    if (isActive) return Colors.white.withValues(alpha: 0.5);
    return switch (state) {
      TerminalActivityState.running =>
        CupertinoColors.activeGreen.withValues(alpha: 0.8),
      TerminalActivityState.attention =>
        CupertinoColors.systemOrange.withValues(alpha: 0.9),
      TerminalActivityState.disconnected =>
        Colors.white.withValues(alpha: 0.25),
      TerminalActivityState.idle => Colors.white.withValues(alpha: 0.4),
    };
  }
}

class _SimpleTileContent extends StatelessWidget {
  const _SimpleTileContent({
    required this.tabItem,
    required this.isActive,
  });

  final TabItem tabItem;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Widget?>(
      valueListenable: tabItem.title,
      builder: (context, titleWidget, _) {
        return Text(
          'Tab',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: isActive ? 1.0 : 0.7),
          ),
        );
      },
    );
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
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.terminal.activityState.value;

    if (state == TerminalActivityState.idle) {
      return const SizedBox.shrink();
    }

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

// ─── Close button ─────────────────────────────────────────────────────────────

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(
          CupertinoIcons.xmark,
          size: 12,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
