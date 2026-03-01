import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/features/command_palette/application/command.dart';

/// 将现有 Intent 包装为 Command 的适配器
class IntentCommand extends Command {
  @override
  final String id;

  @override
  final String label;

  @override
  final String? category;

  @override
  final String? shortcutId;

  final Intent _intent;

  IntentCommand({
    required this.id,
    required this.label,
    required Intent intent,
    this.category,
    this.shortcutId,
  }) : _intent = intent;

  @override
  void execute(BuildContext context, WidgetRef ref) {
    Actions.invoke(context, _intent);
  }
}
