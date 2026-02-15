import 'dart:io'; // 用于 stdout.write

import 'package:dart_openai/dart_openai.dart';

void main() async {
  // =========================================================
  // CLIProxyAPI 配置
  // 务必替换为您的 CLIProxyAPI 的实际信息！
  // =========================================================
  const String cliApiBaseUrl = "https://cliapi.aaaabb.cc";
  const String cliApiKey = "390ea36cb435840c2ad7823c5ffb7d5c";
  // =========================================================
  // dart_openai 全局设置
  // =========================================================
  OpenAI.baseUrl = cliApiBaseUrl;
  OpenAI.apiKey = cliApiKey;
  // 可选：设置请求超时时间，根据您的网络和模型响应速度调整
  OpenAI.requestsTimeOut = const Duration(seconds: 60);
  print("正在尝试连接到 CLIProxyAPI 服务: $cliApiBaseUrl");
  // =========================================================
  // 示例 1: 普通聊天补全 (非流式 - 等待全部生成完一次性返回)
  // =========================================================

  await listAllModels();

  try {
    print("\n--- 示例 1: 普通聊天补全 ---");
    final nonStreamingModel = "gemini-3-pro-preview"; // 使用一个我们确认可用的模型
    final userMessageForNonStreaming = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "请用一句话概括 Dart 语言的特点。",
        ),
      ],
      role: OpenAIChatMessageRole.user,
    );
    final chatCompletion = await OpenAI.instance.chat.create(
      model: nonStreamingModel,
      messages: [userMessageForNonStreaming],
      maxTokens: 100, // 限制回复长度
      temperature: 0.7, // 控制回复的随机性
    );
    if (chatCompletion.choices.isNotEmpty &&
        chatCompletion.choices.first.message.content?.isNotEmpty == true) {
      print("模型 ($nonStreamingModel) 回复:");
      print(chatCompletion.choices.first.message.content?.first.text);
    } else {
      print("模型 ($nonStreamingModel) 未返回有效内容。");
    }
  } catch (e) {
    print("示例 1 发生错误: $e");
    // 更详细的错误处理可以检查 e 的类型，例如 OpenAI.instance.onError.listen((error) => print(error.message));
  }
  // =========================================================
  // 示例 2: 流式聊天补全 (打字机效果)
  // =========================================================
  try {
    print("\n--- 示例 2: 流式聊天补全 (打字机效果) ---");
    final streamingModel = "gemini-3-flash"; // 使用一个我们确认可用的模型
    final userMessageForStreaming = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "请写一首关于宇宙星空的短诗，要有点神秘感。",
        ),
      ],
      role: OpenAIChatMessageRole.user,
    );
    print("模型 ($streamingModel) 回复 (流式):");
    final chatStream = OpenAI.instance.chat.createStream(
      model: streamingModel,
      messages: [userMessageForStreaming],
      maxTokens: 200,
      temperature: 0.8,
    );
    // 监听流式响应，逐块打印
    await for (final streamChatCompletion in chatStream) {
      final contentChunk = streamChatCompletion.choices.first.delta.content;
      if (contentChunk != null && contentChunk.isNotEmpty) {
        // 使用 stdout.write 模拟打字机效果，不自动换行
        stdout.write(contentChunk.first?.text ?? "");
      }
    }
    stdout.writeln(); // 流式结束后换行
    print("--- 流式回复结束 ---");
  } catch (e) {
    print("示例 2 发生错误: $e");
  }
}

Future<void> listAllModels() async {
  final models = await OpenAI.instance.model.list();

  print("所有可用模型：");

  for (final model in models) {
    print(
      "id: ${model.id}, ownedBy: ${model.ownedBy}, created: ${model.created}",
    );
  }
}
