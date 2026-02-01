import 'package:flutter/material.dart';
import 'package:terminal_studio/src/ui/shortcut/intents.dart';
import 'package:terminal_studio/src/ui/shortcuts.dart' as shortcuts;

class GlobalShortcuts extends StatelessWidget {
  const GlobalShortcuts({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        shortcuts.openNewWindow: const NewWindowIntent(),
        shortcuts.openNewTab: const NewTabIntent(),
        shortcuts.previousTab: const PreviousTabIntent(),
        shortcuts.nextTab: const NextTabIntent(),
        shortcuts.tabClose: const CloseTabIntent(),
        shortcuts.openCommandPalette: const OpenCommandPaletteIntent(),
      },
      child: child,
    );
  }
}
