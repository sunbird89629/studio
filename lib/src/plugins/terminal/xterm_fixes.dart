import 'package:xterm/xterm.dart';
import 'package:xterm/src/core/input/keytab/keytab.dart'; // ignore: implementation_imports

/// A [TerminalInputHandler] that translates key events according to a keytab
/// file. Fixed to use [cursorKeysMode] instead of [appKeypadMode] for [appCursorKeys].
class FixedKeytabInputHandler implements TerminalInputHandler {
  const FixedKeytabInputHandler([this.keytab]);

  final Keytab? keytab;

  @override
  String? call(TerminalKeyboardEvent event) {
    final keytab = this.keytab ?? Keytab.defaultKeytab;

    final record = keytab.find(
      event.key,
      ctrl: event.ctrl,
      alt: event.alt,
      shift: event.shift,
      newLineMode: event.state.lineFeedMode,
      appCursorKeys: event.state.cursorKeysMode, // FIXED: use cursorKeysMode
      appKeyPad: event.state.appKeypadMode,
      appScreen: event.altBuffer,
      macos: event.platform == TerminalTargetPlatform.macos,
    );

    if (record == null) {
      return null;
    }

    var result = record.action.unescapedValue();
    result = insertModifiers(event, result);
    return result;
  }

  String insertModifiers(TerminalKeyboardEvent event, String action) {
    String? code;

    if (event.shift && event.alt && event.ctrl) {
      code = '8';
    } else if (event.ctrl && event.alt) {
      code = '7';
    } else if (event.shift && event.ctrl) {
      code = '6';
    } else if (event.ctrl) {
      code = '5';
    } else if (event.shift && event.alt) {
      code = '4';
    } else if (event.alt) {
      code = '3';
    } else if (event.shift) {
      code = '2';
    }

    if (code != null) {
      return action.replaceAll('*', code);
    }

    return action;
  }
}

/// A fixed mouse reporter that fixes the row reporting for normal and utf modes.
abstract class FixedMouseReporter {
  static String report(
    TerminalMouseButton button,
    TerminalMouseButtonState state,
    CellOffset position,
    MouseReportMode reportMode,
  ) {
    final x = position.x + 1;
    final y = position.y + 1;

    // xterm.dart incorrectly adds 4 to wheel button IDs.
    // wheelUp: 68 -> 64, wheelDown: 69 -> 65, etc.
    var buttonID = button.id;
    if (button.isWheel && buttonID >= 68) {
      buttonID -= 4;
    }

    switch (reportMode) {
      case MouseReportMode.normal:
      case MouseReportMode.utf:
        final finalButtonID =
            state == TerminalMouseButtonState.up ? 3 : buttonID;
        final btn = String.fromCharCode(32 + finalButtonID);
        final col = (reportMode == MouseReportMode.normal && x > 223) ||
                (reportMode == MouseReportMode.utf && x > 2015)
            ? '\x00'
            : String.fromCharCode(32 + x);

        // FIXED: xterm.dart had y + 1 + 32, but it should be y + 32.
        // Wait, standard x11 reporting is 32 + coords.
        // If y is 1-based, then it's 32 + y.
        // xterm.dart did: String.fromCharCode(32 + y + 1);
        // If y = position.y + 1, then 32 + y is already 1-based.
        final row = (reportMode == MouseReportMode.normal && y > 223) ||
                (reportMode == MouseReportMode.utf && y > 2015)
            ? '\x00'
            : String.fromCharCode(32 + y);
        return "\x1b[M$btn$col$row";
      case MouseReportMode.sgr:
        final upDown = state == TerminalMouseButtonState.down ? 'M' : 'm';
        return "\x1b[<$buttonID;$x;$y$upDown";
      case MouseReportMode.urxvt:
        final finalButtonID =
            32 + (state == TerminalMouseButtonState.up ? 3 : buttonID);
        return "\x1b[$finalButtonID;$x;${y}M";
    }
  }
}

class FixedClickMouseHandler implements TerminalMouseHandler {
  const FixedClickMouseHandler();

  @override
  String? call(TerminalMouseEvent event) {
    switch (event.state.mouseMode) {
      case MouseMode.clickOnly:
        if (event.buttonState == TerminalMouseButtonState.down &&
            (event.button.id < 3)) {
          return FixedMouseReporter.report(
            event.button,
            event.buttonState,
            event.position,
            event.state.mouseReportMode,
          );
        }
        return null;
      case MouseMode.none:
      case MouseMode.upDownScroll:
      case MouseMode.upDownScrollDrag:
      case MouseMode.upDownScrollMove:
        return null;
    }
  }
}

class FixedUpDownMouseHandler implements TerminalMouseHandler {
  const FixedUpDownMouseHandler();

  @override
  String? call(TerminalMouseEvent event) {
    switch (event.state.mouseMode) {
      case MouseMode.none:
      case MouseMode.clickOnly:
        return null;
      case MouseMode.upDownScroll:
      case MouseMode.upDownScrollDrag:
      case MouseMode.upDownScrollMove:
        if (event.button.isWheel &&
            event.buttonState == TerminalMouseButtonState.up) {
          return null;
        }
        return FixedMouseReporter.report(
          event.button,
          event.buttonState,
          event.position,
          event.state.mouseReportMode,
        );
    }
  }
}

const fixedDefaultInputHandler = CascadeInputHandler([
  FixedKeytabInputHandler(),
  CtrlInputHandler(),
  AltInputHandler(),
]);

const fixedDefaultMouseHandler = CascadeMouseHandler([
  FixedClickMouseHandler(),
  FixedUpDownMouseHandler(),
]);
