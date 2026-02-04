import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/settings.dart';
import '../utils/ai_logger.dart';

final aiCopilotServiceProvider = Provider((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.when(
    data: (settings) => AICopilotService(
      apiKey: settings.aiApiKey,
      modelName: settings.aiModel,
    ),
    loading: () => AICopilotService(
        apiKey: null, modelName: 'google/gemini-2.0-flash-exp:free'),
    error: (_, __) => AICopilotService(
        apiKey: null, modelName: 'google/gemini-2.0-flash-exp:free'),
  );
});

class AICopilotService {
  final String? apiKey;
  final String modelName;
  final AILogger _logger =
      AILogger(context: const LogContext(component: 'AICopilotService'));

  AICopilotService({
    required this.apiKey,
    required this.modelName,
  });

  Future<String> _requestOpenRouter(List<Map<String, String>> messages) async {
    if (apiKey == null || apiKey!.isEmpty) {
      _logger.w('API Key is missing, AI features will not work.');
      return 'Error: API Key not configured in settings.';
    }

    final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer':
              'https://github.com/TerminalStudio', // Optional, for OpenRouter tracking
          'X-Title': 'TerminalStudio', // Optional
        },
        body: jsonEncode({
          'model': modelName,
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return content?.trim() ?? 'No response content.';
      } else {
        _logger.e(
            'OpenRouter API error: ${response.statusCode} - ${response.body}');
        return 'Error: AI Provider returned ${response.statusCode}. ${response.body}';
      }
    } catch (e, stack) {
      _logger.e('Failed to call OpenRouter', error: e, stackTrace: stack);
      return 'Error: Failed to connect to AI Provider. ${e.toString()}';
    }
  }

  Future<String> generateCommand(String description) async {
    _logger.i('Generating command for: $description');
    final messages = [
      {
        'role': 'system',
        'content':
            'You are a terminal expert. Translate the following natural language description into a single, executable shell command for a POSIX-compliant shell. Return ONLY the command itself, no explanation, no markdown formatting (like ```bash), and no additional text.'
      },
      {'role': 'user', 'content': description},
    ];

    return await _requestOpenRouter(messages);
  }

  Future<String> explainError(String errorOutput) async {
    _logger.i('Explaining error: ${errorOutput.take(100)}...');
    final messages = [
      {
        'role': 'system',
        'content':
            'You are a terminal expert. Explain the following terminal error message and suggest a brief solution. Keep the explanation concise and actionable.'
      },
      {'role': 'user', 'content': errorOutput},
    ];

    return await _requestOpenRouter(messages);
  }

  Future<String> chat(String message) async {
    _logger.i('Chatting with Copilot: $message');
    final messages = [
      {'role': 'user', 'content': message},
    ];

    return await _requestOpenRouter(messages);
  }
}

extension StringExtension on String {
  String take(int n) => length <= n ? this : substring(0, n);
}
