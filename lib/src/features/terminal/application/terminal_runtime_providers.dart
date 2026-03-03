import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/features/tabs/application/active_tab_service.dart';
import 'package:terminal_studio/src/features/tabs/application/plugin_tab.dart';
import 'package:terminal_studio/src/features/terminal/runtime/terminal_runtime.dart';

/// Exposes the runtime capability of the currently active terminal tab.
final activeTerminalRuntimeProvider = Provider<TerminalRuntimeAccess?>((ref) {
  final activeTab = ref.watch(activeTabServiceProvider).getActiveTab();
  if (activeTab is! PluginTab) return null;

  final plugin = activeTab.plugin;
  if (plugin is! TerminalRuntimeAccess) return null;
  return plugin as TerminalRuntimeAccess;
});
