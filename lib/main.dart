import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_devtools/riverpod_devtools.dart';
import 'package:terminal_studio/src/core/open_term.dart';
import 'package:terminal_studio/src/core/service/log_service.dart';
import 'package:terminal_studio/src/core/log/app_logger.dart';
import 'package:terminal_studio/src/util/provider_logger.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initWindow();
  await LogService.instance.initialize();

  final logger = AppLogger(context: const LogContext(component: 'Main'));
  logger.i('OpenTerm starting up...');

  final container = ProviderContainer(
    observers: [
      ProviderLogger(),
      RiverpodDevToolsObserver(),
    ],
  );
  initOpenTerm(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class _AppWindowListener extends WindowListener {
  @override
  Future<void> onWindowClose() async {
    await LogService.instance.dispose();
    await windowManager.destroy();
  }
}

Future<void> initWindow() async {
  await windowManager.ensureInitialized();
  await windowManager.setBackgroundColor(const Color(0x00000000));
  await windowManager.setTitle('');
  await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  await windowManager.setPreventClose(true);
  windowManager.addListener(_AppWindowListener());

  windowManager.waitUntilReadyToShow(null, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
