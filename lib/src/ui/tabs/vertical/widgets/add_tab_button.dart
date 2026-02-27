import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/service/tabs_service.dart';
import 'package:terminal_studio/src/hosts/local_spec.dart';
import 'package:terminal_studio/src/plugins/ai/ai_plugin.dart';

class AddTabButton extends ConsumerWidget {
  const AddTabButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void openTerminal() {
      ref.read(tabsServiceProvider).openTerminal(const LocalHostSpec());
    }

    void openAIAssistant() {
      final plugin = AIPlugin();
      ref.read(tabsServiceProvider).openPlugin(const LocalHostSpec(), plugin);
    }

    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        tooltip: 'Add new tab',
        onSelected: (String value) {
          switch (value) {
            case 'terminal':
              openTerminal();
              break;
            case 'ai_assistant':
              openAIAssistant();
              break;
          }
        },
        child: Tooltip(
          message: 'New Tab',
          child: SizedBox(
            height: 44,
            child: Center(
              child: Icon(
                Icons.add,
                size: 18,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'terminal',
            child: Row(
              children: [
                Icon(Icons.terminal, size: 16),
                SizedBox(width: 8),
                Text('Terminal'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'ai_assistant',
            child: Row(
              children: [
                Icon(Icons.smart_toy, size: 16),
                SizedBox(width: 8),
                Text('AI Assistant'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
