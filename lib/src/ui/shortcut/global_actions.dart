import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/service/active_tab_service.dart';
import 'package:terminal_studio/src/core/service/command_palette_service.dart';
import 'package:terminal_studio/src/core/service/tabs_service.dart';
import 'package:terminal_studio/src/core/service/window_service.dart';
import 'package:terminal_studio/src/hosts/local_spec.dart';
import 'package:terminal_studio/src/ui/shortcut/intents.dart';

class GlobalActions extends ConsumerWidget {
  const GlobalActions({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Actions(
      actions: {
        NewWindowIntent: CallbackAction<NewWindowIntent>(
          onInvoke: (NewWindowIntent intent) async {
            await ref.read(windowServiceProvider).createWindow();
            return null;
          },
        ),
        NewTabIntent: CallbackAction<NewTabIntent>(
          onInvoke: (NewTabIntent intent) {
            ref.read(tabsServiceProvider).openTerminal(const LocalHostSpec());
            return null;
          },
        ),
        PreviousTabIntent: CallbackAction<PreviousTabIntent>(
          onInvoke: (PreviousTabIntent intent) {
            ref.read(activeTabServiceProvider).selectPreviousTab();
            return null;
          },
        ),
        NextTabIntent: CallbackAction<NextTabIntent>(
          onInvoke: (NextTabIntent intent) {
            ref.read(activeTabServiceProvider).selectNextTab();
            return null;
          },
        ),
        CloseTabIntent: CallbackAction<CloseTabIntent>(
          onInvoke: (CloseTabIntent intent) {
            ref.read(activeTabServiceProvider).closeCurrentTabOrWindow();
            return null;
          },
        ),
        OpenCommandPaletteIntent: CallbackAction<OpenCommandPaletteIntent>(
          onInvoke: (OpenCommandPaletteIntent intent) {
            ref.read(commandPaletteServiceProvider.notifier).toggle();
            return null;
          },
        ),
      },
      child: child,
    );
  }
}
