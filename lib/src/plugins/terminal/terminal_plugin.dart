import 'dart:convert';

import 'package:context_menus/context_menus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/conn.dart';
import 'package:terminal_studio/src/core/host.dart';
import 'package:terminal_studio/src/core/plugin.dart';
import 'package:terminal_studio/src/core/state/settings.dart';
import 'package:terminal_studio/src/plugins/terminal/terminal_menu.dart';
import 'package:xterm/xterm.dart';

class TerminalPlugin extends Plugin {
  final terminal = Terminal(maxLines: 10000);

  final terminalController = TerminalController();

  var terminalTitle = '';

  ExecutionSession? session;

  void _updateTitle() {
    if (session != null) {
      title.value =
          '$terminalTitle — ${terminal.viewWidth}x${terminal.viewHeight}';
    }
  }

  @override
  void didMounted() {
    title.value = 'Connecting';

    terminal.onTitleChange = (title) {
      terminalTitle = title;
      _updateTitle();
    };

    terminal.onOutput = (data) {
      print('Terminal input (user typed): ${data.length} chars: $data');
      session?.write(const Utf8Encoder().convert(data));
    };

    terminal.onResize = (w, h, pw, ph) {
      session?.resize(w, h);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _updateTitle();
      });
    };

    super.didMounted();
  }

  @override
  void didConnected() async {
    title.value = 'Terminal';
    print('TerminalPlugin connected. requesting shell...');

    session = await host.shell(
      width: terminal.viewWidth,
      height: terminal.viewHeight,
    );

    print('Shell session created: $session');

    session!.output.cast<List<int>>().transform(const Utf8Decoder()).listen(
        (data) {
      print('Terminal received output: ${data.length} chars');
      terminal.write(data);
    }, onError: (e) {
      print('Terminal session error: $e');
    }, onDone: () {
      print('Terminal session done');
    });

    session!.exitCode.then((code) {
      print('Terminal session exited with code: $code');
      session = null;
      if (mounted) {
        manager.remove(this);
      }
    });
  }

  @override
  void didDisconnected() {
    print('TerminalPlugin disconnected');
    session = null;
    title.value = 'Disconnected';
  }

  @override
  void onConnectionStatus(HostConnectorStatus status) {
    switch (status) {
      case HostConnectorStatus.connecting:
        title.value = 'Connecting';
        break;
      case HostConnectorStatus.connected:
        title.value = 'Terminal';
        break;
      case HostConnectorStatus.disconnected:
        title.value = 'Disconnected';
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return TerminalTabView(this);
  }
}

class TerminalTabView extends ConsumerStatefulWidget {
  const TerminalTabView(this.plugin, {super.key});

  final TerminalPlugin plugin;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _TerminalTabViewState();
}

class _TerminalTabViewState extends ConsumerState<TerminalTabView> {
  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) {
        final style = settings.terminalFontFamily?.isNotEmpty == true
            ? TerminalStyle(
                fontSize: settings.terminalFontSize,
                fontFamily: settings.terminalFontFamily!,
              )
            : TerminalStyle(
                fontSize: settings.terminalFontSize,
                fontFamily: 'Hack Nerd Font Mono',
              );

        return CupertinoPageScaffold(
          key: ValueKey(widget.plugin),
          backgroundColor: Colors.transparent,
          child: SafeArea(
            child: ClipRect(
              child: TerminalView(
                widget.plugin.terminal,
                textStyle: style,
                controller: widget.plugin.terminalController,
                onSecondaryTapDown: (_, __) => showMenu(),
                backgroundOpacity: 0.8,
                autofocus: true,
              ),
            ),
          ),
        );
      },
      loading: () => const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (error, stack) => CupertinoPageScaffold(
        child: Center(child: Text('Error: $error')),
      ),
    );
  }

  void showMenu() {
    final menu = TerminalContextMenu(plugin: widget.plugin);
    context.contextMenuOverlay.show(menu);
  }
}
