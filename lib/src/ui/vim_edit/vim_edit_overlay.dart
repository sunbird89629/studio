import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/service/vim_edit_service.dart';
import 'package:terminal_studio/src/core/state/settings.dart';
import 'package:xterm/xterm.dart';

class VimEditOverlay extends ConsumerStatefulWidget {
  const VimEditOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<VimEditOverlay> createState() => _VimEditOverlayState();
}

class _VimEditOverlayState extends ConsumerState<VimEditOverlay> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vimEditServiceProvider);

    // Request focus when dialog becomes visible
    if (state.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }

    final theme = Theme.of(context);

    return Stack(
      children: [
        widget.child,
        if (state.isVisible)
          Positioned.fill(
            child: Material(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  width: 800,
                  height: 600,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: theme.dividerColor,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: VimTerminalView(
                      terminal: state.terminal,
                      controller: state.terminalController,
                      focusNode: _focusNode,
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
    required this.focusNode,
  });

  final Terminal terminal;
  final TerminalController controller;
  final FocusNode focusNode;

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
          focusNode: focusNode,
          backgroundOpacity: 1,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}
