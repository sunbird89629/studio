import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/service/ai_service.dart';
import '../core/state/settings.dart';

final aiModelsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.read(aiCopilotServiceProvider);
  final models = await service.listModels();
  return models.map((e) => e.id).toList();
});

final selectedModelProvider =
    NotifierProvider<SelectedModelNotifier, String?>(SelectedModelNotifier.new);

class SelectedModelNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

class CopilotSidebar extends ConsumerStatefulWidget {
  const CopilotSidebar({super.key});

  @override
  ConsumerState<CopilotSidebar> createState() => _CopilotSidebarState();
}

class _CopilotSidebarState extends ConsumerState<CopilotSidebar> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  bool _isLoading = false;

  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(Message(text: text, isUser: true));
      _controller.clear();
      _isLoading = true;
    });

    final aiService = ref.read(aiCopilotServiceProvider);
    final selectedModel = ref.read(selectedModelProvider);
    final response = await aiService.chat(text, model: selectedModel);

    if (mounted) {
      setState(() {
        _messages.add(Message(text: response, isUser: false));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) {
        // Since we are using hardcoded keys for now, we might not strictly need this check,
        // but it's good practice. For now, let's assume if it's not configured in settings,
        // we might still want to show it because we hardcoded it?
        // Actually, the previous code showed a warning if not configured.
        // Given we are overriding in service, let's skip the check or assume
        // the user might have empty settings but we proceed.
        // HOWEVER, to be safe and consistent with previous behavior:
        // If the service is using hardcoded values, we can skip the check on settings.
        // Let's just show the UI.

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: FluentTheme.of(context).micaBackgroundColor)),
              ),
              child: Row(
                children: [
                  const Icon(FluentIcons.robot),
                  const SizedBox(width: 8),
                  Text(
                    'AI Copilot',
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const Spacer(),
                  _buildModelSwitcher(),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(FluentIcons.clear),
                    onPressed: () => setState(() => _messages.clear()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: msg.isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: msg.isUser
                                ? FluentTheme.of(context).accentColor.lightest
                                : FluentTheme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(msg.text),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg.isUser ? 'You' : 'Copilot',
                          style: FluentTheme.of(context).typography.caption,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ProgressBar(),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextBox(
                      controller: _controller,
                      placeholder: 'Ask Copilot anything...',
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(FluentIcons.send),
                    onPressed: _handleSend,
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: ProgressRing()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildModelSwitcher() {
    final modelsAsync = ref.watch(aiModelsProvider);
    final selectedModel = ref.watch(selectedModelProvider);

    return modelsAsync.when(
      data: (models) {
        if (models.isEmpty) return const SizedBox.shrink();

        // Ensure selection is valid or default to first
        final currentSelection =
            selectedModel ?? (models.isNotEmpty ? models.first : null);
        if (selectedModel == null && currentSelection != null) {
          // Initialize selection
          Future.microtask(() {
            ref.read(selectedModelProvider.notifier).set(currentSelection);
          });
        }

        return ComboBox<String>(
          value: currentSelection,
          items: models.map((e) {
            return ComboBoxItem<String>(
              value: e,
              child: Text(e, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              ref.read(selectedModelProvider.notifier).set(value);
            }
          },
          placeholder: const Text('Select Model'),
        );
      },
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: ProgressRing(strokeWidth: 2),
      ),
      error: (_, __) => const Icon(FluentIcons.error, size: 16),
    );
  }
}

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}
