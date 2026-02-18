import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/service/vim_edit_service.dart';
import 'package:terminal_studio/src/core/state/settings.dart';
import 'package:xterm/xterm.dart';

class VimEditListener extends ConsumerWidget {
  const VimEditListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(vimEditServiceProvider.select((s) => s.isVisible), (_, next) {
      if (next == true) {
        showGeneralDialog<void>(
          context: context,
          useRootNavigator: true,
          barrierDismissible: false,
          barrierColor: Colors.black54,
          pageBuilder: (_, __, ___) => const _VimEditDialog(),
          transitionBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          ),
          transitionDuration: const Duration(milliseconds: 150),
        );
      }
    });
    return child;
  }
}

class _VimEditDialog extends ConsumerStatefulWidget {
  const _VimEditDialog();

  @override
  ConsumerState<_VimEditDialog> createState() => _VimEditDialogState();
}

class _VimEditDialogState extends ConsumerState<_VimEditDialog> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(vimEditServiceProvider.select((s) => s.isVisible), (_, next) {
      if (next == false && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });

    final state = ref.watch(vimEditServiceProvider);
    // final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(80),
      child: Container(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        foregroundDecoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _VimTerminalView(
          terminal: state.terminal,
          controller: state.terminalController,
          focusNode: _focusNode,
        ),
      ),
    );
  }
}

class _VimTerminalView extends ConsumerWidget {
  const _VimTerminalView({
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
