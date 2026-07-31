// ─── Tab Tile ────────────────────────────────────────────────────────────────

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_term/src/features/tabs/presentation/vertical/widgets/c_w_d_widget.dart';
import 'package:open_term/src/features/tabs/presentation/vertical/widgets/command_widget.dart';
import 'package:open_term/src/features/tabs/presentation/vertical/widgets/host_widget.dart';
import 'package:open_term/src/features/terminal/application/terminal_plugin.dart';
import 'package:open_term/src/shared/state/terminal_activity_provider.dart';

class TerminalTileContent extends StatelessWidget {
  const TerminalTileContent({
    super.key,
    required this.terminal,
    required this.isActive,
  });

  final TerminalPlugin terminal;
  final bool isActive;

  (String, String) get hostAndCWD {
    final title = terminal.title.value ?? 'Terminal';
    if (title.contains(":")) {
      return (title.split(":")[0], title.split(":")[1]);
    } else {
      return (title, "");
    }
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
        final (host, cwd) = hostAndCWD;
        final secondaryColor = _secondaryColor(state);

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            HostWidget(
              host: host,
              textOpacity: textOpacity,
              isActive: isActive,
            ),
            CWDWidget(
              cwd: cwd,
              textOpacity: textOpacity,
              isActive: isActive,
            ),
            CommandWidget(
              lastThreeText: lastThreeText,
              secondaryColor: secondaryColor,
            ),
          ],
        );
      },
    );
  }
}
