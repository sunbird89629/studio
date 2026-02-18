import 'package:context_menus/context_menus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/service/notification_service.dart';
import 'package:terminal_studio/src/core/state/theme.dart';
import 'package:terminal_studio/src/ui/command_palette/command_palette_overlay.dart';
import 'package:terminal_studio/src/ui/home.dart';
import 'package:terminal_studio/src/ui/platform_menu.dart';
import 'package:terminal_studio/src/ui/shared/studio_menu_card.dart';
import 'package:terminal_studio/src/ui/shortcut/global_actions.dart';
import 'package:terminal_studio/src/ui/shortcut/global_shortcuts.dart';
import 'package:terminal_studio/src/ui/vim_edit/vim_edit_listener.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(tunnelObserverProvider);

    final theme = ref.watch(activeThemeProvider);

    return MaterialApp(
      title: 'OpenTerm',
      debugShowCheckedModeBanner: false,
      theme: theme.theme,
      home: ContextMenuOverlay(
        cardBuilder: (context, children) => StudioMenuCard(children: children),
        child: _withPlatformMenu(
          const GlobalActions(
            child: GlobalShortcuts(
              child: CommandPaletteListener(
                child: VimEditListener(
                  child: Home(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _withPlatformMenu(Widget child) {
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return GlobalPlatformMenu(child: child);
    }
    return child;
  }
}
