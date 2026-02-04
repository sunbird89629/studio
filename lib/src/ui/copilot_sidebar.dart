import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/service/ai_service.dart';
import '../core/state/settings.dart';

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
    final response = await aiService.chat(text);

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
        final hasApiKey = settings.aiApiKey?.isNotEmpty ?? false;

        if (!hasApiKey) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FluentIcons.robot, size: 48),
                  const SizedBox(height: 16),
                  const Text('AI Copilot is not configured.'),
                  const SizedBox(height: 8),
                  const Text(
                      'Please add your OpenRouter API Key in settings to enable this feature.'),
                  const SizedBox(height: 16),
                  Button(
                    child: const Text('Open Settings'),
                    onPressed: () {
                      // TODO: Trigger settings dialog or navigate to settings
                    },
                  ),
                ],
              ),
            ),
          );
        }

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
}

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}
