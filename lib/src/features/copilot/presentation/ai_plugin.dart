import 'package:flutter/material.dart';
import 'package:terminal_studio/src/platform/plugins/plugin_runtime.dart';
import 'package:terminal_studio/src/features/copilot/presentation/copilot_sidebar.dart';

/// An AI plugin that provides an AI assistant interface within a tab.
class AIPlugin extends Plugin {
  AIPlugin() {
    title.value = 'AI Assistant';
  }

  @override
  Widget build(BuildContext context) {
    return const CopilotSidebar();
  }

  @override
  void onMounted() {
    // Set the title to AI Assistant when mounted
    title.value = 'AI Assistant';
    super.onMounted();
  }
}