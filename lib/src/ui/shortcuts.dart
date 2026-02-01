import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:terminal_studio/src/util/target_platform.dart';

SingleActivator get openSettings {
  return defaultTargetPlatform.isApple
      ? const SingleActivator(
          LogicalKeyboardKey.comma,
          meta: true,
        )
      : const SingleActivator(
          LogicalKeyboardKey.comma,
          control: true,
        );
}

SingleActivator get openDevTools {
  return const SingleActivator(
    LogicalKeyboardKey.f12,
  );
}

SingleActivator get openNewWindow {
  return defaultTargetPlatform.isApple
      ? const SingleActivator(
          LogicalKeyboardKey.keyN,
          meta: true,
        )
      : const SingleActivator(
          LogicalKeyboardKey.keyN,
          control: true,
        );
}

SingleActivator get openNewTab {
  return defaultTargetPlatform.isApple
      ? const SingleActivator(
          LogicalKeyboardKey.keyT,
          meta: true,
        )
      : const SingleActivator(
          LogicalKeyboardKey.keyT,
          control: true,
        );
}

SingleActivator get previousTab {
  return defaultTargetPlatform.isApple
      ? const SingleActivator(
          LogicalKeyboardKey.bracketLeft,
          meta: true,
        )
      : const SingleActivator(
          LogicalKeyboardKey.pageUp,
          control: true,
        );
}

SingleActivator get nextTab {
  return defaultTargetPlatform.isApple
      ? const SingleActivator(
          LogicalKeyboardKey.bracketRight,
          meta: true,
        )
      : const SingleActivator(
          LogicalKeyboardKey.pageDown,
          control: true,
        );
}

SingleActivator get tabClose {
  return defaultTargetPlatform.isApple
      ? const SingleActivator(
          LogicalKeyboardKey.keyW,
          meta: true,
        )
      : const SingleActivator(
          LogicalKeyboardKey.keyW,
          meta: true,
          shift: true,
        );
}

SingleActivator get terminalCopy {
  return defaultTargetPlatform.isApple
      ? const SingleActivator(
          LogicalKeyboardKey.keyC,
          meta: true,
        )
      : const SingleActivator(
          LogicalKeyboardKey.keyC,
          control: true,
          shift: true,
        );
}

SingleActivator get terminalPaste {
  return defaultTargetPlatform.isApple
      ? const SingleActivator(
          LogicalKeyboardKey.keyV,
          meta: true,
        )
      : const SingleActivator(
          LogicalKeyboardKey.keyV,
          control: true,
          shift: true,
        );
}

SingleActivator get terminalSelectAll {
  return defaultTargetPlatform.isApple
      ? const SingleActivator(
          LogicalKeyboardKey.keyA,
          meta: true,
        )
      : const SingleActivator(
          LogicalKeyboardKey.keyA,
          control: true,
          shift: true,
        );
}

SingleActivator get openCommandPalette {
  return defaultTargetPlatform.isApple
      ? const SingleActivator(
          LogicalKeyboardKey.keyP,
          meta: true,
          shift: true,
        )
      : const SingleActivator(
          LogicalKeyboardKey.keyP,
          control: true,
          shift: true,
        );
}
