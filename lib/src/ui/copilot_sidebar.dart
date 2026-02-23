import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/service/ai_service.dart';
import '../core/state/settings.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class Message {
  final String text;
  final bool isUser;

  const Message({required this.text, required this.isUser});
}

// ── State ─────────────────────────────────────────────────────────────────────

class CopilotChatState {
  final List<Message> messages;
  final bool isLoading;

  const CopilotChatState({this.messages = const [], this.isLoading = false});

  CopilotChatState copyWith({List<Message>? messages, bool? isLoading}) =>
      CopilotChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class CopilotChatNotifier extends Notifier<CopilotChatState> {
  @override
  CopilotChatState build() => const CopilotChatState();

  Future<void> send(String text, {String? model}) async {
    if (text.isEmpty) return;

    // Add user message and empty AI placeholder
    state = state.copyWith(
      messages: [
        ...state.messages,
        Message(text: text, isUser: true),
        const Message(text: '', isUser: false),
      ],
      isLoading: true,
    );

    final service = ref.read(aiCopilotServiceProvider);
    final buffer = StringBuffer();

    await for (final chunk in service.chatStream(text, model: model)) {
      buffer.write(chunk);
      final msgs = List<Message>.from(state.messages);
      msgs[msgs.length - 1] = Message(text: buffer.toString(), isUser: false);
      state = state.copyWith(messages: msgs);
    }

    state = state.copyWith(isLoading: false);
  }

  void clear() => state = const CopilotChatState();
}

final copilotChatProvider =
    NotifierProvider<CopilotChatNotifier, CopilotChatState>(
  CopilotChatNotifier.new,
);

// ── Model provider ────────────────────────────────────────────────────────────

final aiModelsProvider = FutureProvider<List<String>>((ref) async {
  // Re-fetch when the API key changes so the list stays in sync with settings.
  ref.watch(settingsProvider.select((s) => s.value?.aiApiKey));
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
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final selectedModel = ref.read(selectedModelProvider);
    ref.read(copilotChatProvider.notifier).send(text, model: selectedModel);
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final chatState = ref.watch(copilotChatProvider);

    // Scroll to bottom when messages or loading state changes
    ref.listen(copilotChatProvider, (_, __) => _scrollToBottom());

    return settingsAsync.when(
      data: (settings) {
        return Material(
          color: colorScheme.surface,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI Copilot',
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildModelSwitcher(),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Clear Chat',
                      onPressed: () =>
                          ref.read(copilotChatProvider.notifier).clear(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: chatState.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chatState.messages[index];
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
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              msg.text,
                              style: TextStyle(
                                color: msg.isUser
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg.isUser ? 'You' : 'Copilot',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (chatState.isLoading) const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Ask Copilot anything...',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _handleSend,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildModelSwitcher() {
    final modelsAsync = ref.watch(aiModelsProvider);
    final selectedModel = ref.watch(selectedModelProvider);

    return modelsAsync.when(
      data: (models) {
        if (models.isEmpty) return const SizedBox.shrink();

        final currentSelection =
            selectedModel ?? (models.isNotEmpty ? models.first : null);
        if (selectedModel == null && currentSelection != null) {
          Future.microtask(() {
            ref.read(selectedModelProvider.notifier).set(currentSelection);
          });
        }

        return DropdownButton<String>(
          value: currentSelection,
          isDense: true,
          underline: const SizedBox(),
          items: models.map((e) {
            return DropdownMenuItem<String>(
              value: e,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(e, overflow: TextOverflow.ellipsis),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              ref.read(selectedModelProvider.notifier).set(value);
            }
          },
        );
      },
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const Icon(Icons.error_outline, size: 16),
    );
  }
}
