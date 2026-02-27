// ─── Tab Tile ────────────────────────────────────────────────────────────────

import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:terminal_studio/src/core/state/terminal_activity.dart';
import 'package:terminal_studio/src/plugins/terminal/terminal_plugin.dart';

class ContentWidget extends StatelessWidget {
  const ContentWidget({
    super.key,
    required this.terminal,
    required this.isActive,
    required TabItem tab,
  }) : _tab = tab;

  final TerminalPlugin? terminal;
  final bool isActive;
  final TabItem _tab;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      child: _buildByTerminal(),
    );
  }

  Widget _buildByTerminal() {
    if (terminal != null) {
      return _TerminalTileContent(
        terminal: terminal!,
        isActive: isActive,
      );
    } else {
      return _SimpleTileContent(
        tabItem: _tab,
        isActive: isActive,
      );
    }
  }
}

// ─── Tile content widgets ─────────────────────────────────────────────────────

class _TerminalTileContent extends StatelessWidget {
  const _TerminalTileContent({
    required this.terminal,
    required this.isActive,
  });

  final TerminalPlugin terminal;
  final bool isActive;

  /// Strip the dimensions suffix " — WxH" that TerminalPlugin appends to title.
  String _primaryText() {
    final raw = terminal.title.value ?? 'Terminal';
    final sepIdx = raw.indexOf(' \u2014 ');
    return sepIdx >= 0 ? raw.substring(0, sepIdx) : raw;
  }

  Color _secondaryColor(TerminalActivityState state) {
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

  String get lastThreeText {
    try {
      return terminal.terminal.buffer.getText();
    } catch (e) {
      debugPrint(e.toString());
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([terminal.activityState, terminal.title]),
      builder: (context, _) {
        final state = terminal.activityState.value;
        // final lastCommand = terminal.lastCommand;
        // final secondaryText = switch (state) {
        //   TerminalActivityState.running =>
        //     lastCommand.isNotEmpty ? lastCommand : 'Running\u2026',
        //   TerminalActivityState.attention =>
        //     lastCommand.isNotEmpty ? lastCommand : 'Waiting\u2026',
        //   TerminalActivityState.disconnected => 'Disconnected',
        //   TerminalActivityState.idle => terminal.manager.hostSpec.name,
        // };

        final textOpacity = isActive
            ? 1.0
            : (state == TerminalActivityState.disconnected ? 0.35 : 0.75);

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _primaryText().split(":")[0],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: textOpacity),
                fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            Text(
              _primaryText().split(":")[1],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: textOpacity),
                fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              // secondaryText,
              lastThreeText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: _secondaryColor(state),
              ),
            ),
          ],
        );
      },
    );
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
        return titleWidget ??
            Text(
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
