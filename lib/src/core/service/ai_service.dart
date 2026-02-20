import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/settings.dart';
import '../utils/app_logger.dart';

final aiCopilotServiceProvider = Provider((ref) {
  final apiKey = ref.watch(settingsProvider).value?.aiApiKey;
  return AICopilotService(apiKey: apiKey);
});

class AICopilotService {
  final AppLogger _logger = AppLogger.forComponent('AICopilotService');

  static const String _baseUrl = "https://cliapi.aaaabb.cc";
  static const String _defaultModel = "gemini-3-flash";

  AICopilotService({String? apiKey}) {
    OpenAI.baseUrl = _baseUrl;
    OpenAI.apiKey = (apiKey != null && apiKey.isNotEmpty) ? apiKey : '';
    OpenAI.requestsTimeOut = const Duration(seconds: 60);
  }

  Future<List<OpenAIModelModel>> listModels() async {
    try {
      final models = await OpenAI.instance.model.list();
      return models;
    } catch (e, stack) {
      _logger.e('Failed to list models', error: e, stackTrace: stack);
      return [];
    }
  }

  Future<String> _chat(List<OpenAIChatCompletionChoiceMessageModel> messages,
      {String? model}) async {
    try {
      final chatCompletion = await OpenAI.instance.chat.create(
        model: model ?? _defaultModel,
        messages: messages,
        // maxTokens: 1000,
      );

      if (chatCompletion.choices.isNotEmpty &&
          chatCompletion.choices.first.message.content?.isNotEmpty == true) {
        final content =
            chatCompletion.choices.first.message.content!.first.text ?? '';
        return content.trim();
      } else {
        return 'No response content.';
      }
    } catch (e, stack) {
      _logger.e('Failed to call AI Service', error: e, stackTrace: stack);
      return 'Error: Failed to connect to AI Provider. ${e.toString()}';
    }
  }

  Future<String> generateCommand(String description) async {
    _logger.i('Generating command for: $description');
    final messages = [
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
              'You are a terminal expert. Translate the following natural language description into a single, executable shell command for a POSIX-compliant shell. Return ONLY the command itself, no explanation, no markdown formatting (like ```bash), and no additional text.'),
        ],
      ),
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(description),
        ],
      ),
    ];

    return await _chat(messages);
  }

  Future<String> explainError(String errorOutput) async {
    _logger.i('Explaining error: ${errorOutput.take(100)}...');

    final messages = [
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
              'You are a terminal expert. Explain the following terminal error message and suggest a brief solution. Keep the explanation concise and actionable.'),
        ],
      ),
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(errorOutput),
        ],
      ),
    ];

    return await _chat(messages);
  }

  Future<String> chat(String message, {String? model}) async {
    _logger.i('Chatting with Copilot: $message (model: $model)');

    final messages = [
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(message),
        ],
      ),
    ];

    return await _chat(messages, model: model);
  }
}

extension StringExtension on String {
  String take(int n) => length <= n ? this : substring(0, n);
}
