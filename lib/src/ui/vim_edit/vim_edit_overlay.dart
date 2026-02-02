import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/service/vim_edit_service.dart';
import 'package:terminal_studio/src/core/state/settings.dart';
import 'package:xterm/xterm.dart';

class VimEditOverlay extends ConsumerWidget {
  const VimEditOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vimEditServiceProvider);

    final theme = FluentTheme.of(context);

    return Stack(
      children: [
        child,
        if (state.isVisible)
          Positioned.fill(
            child: Material(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  width: 800,
                  height: 600,
                  decoration: BoxDecoration(
                    color: theme.micaBackgroundColor, // Use theme background
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: VimTerminalView(
                      terminal: state.terminal,
                      controller: state.terminalController,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class VimTerminalView extends ConsumerWidget {
  const VimTerminalView({
    super.key,
    required this.terminal,
    required this.controller,
  });

  final Terminal terminal;
  final TerminalController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) {
        final style = settings.terminalFontFamily?.isNotEmpty == true
            ? TerminalStyle(
                fontSize: settings.terminalFontSize,
                fontFamily: settings.terminalFontFamily!,
              )
            : const TerminalStyle(
                fontSize: 14,
                fontFamily: 'Hack Nerd Font Mono',
              );

        return TerminalView(
          terminal,
          controller: controller,
          textStyle: style,
          autofocus: true,
          backgroundOpacity: 1,
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}
