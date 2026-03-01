import 'package:context_menus/context_menus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/shared/state/notification_service.dart';
import 'package:terminal_studio/src/shared/theme/theme_providers.dart';
import 'package:terminal_studio/src/features/command_palette/presentation/command_palette_overlay.dart';
import 'package:terminal_studio/src/features/tabs/presentation/home.dart';
import 'package:terminal_studio/src/features/tabs/presentation/platform_menu.dart';
import 'package:terminal_studio/src/shared/widgets/studio_menu_card.dart';
import 'package:terminal_studio/src/features/command_palette/presentation/shortcut/global_actions.dart';
import 'package:terminal_studio/src/features/command_palette/presentation/shortcut/global_shortcuts.dart';
import 'package:terminal_studio/src/features/command_palette/presentation/vim_edit_listener.dart';

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
