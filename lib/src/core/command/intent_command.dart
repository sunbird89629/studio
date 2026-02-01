import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/command/command.dart';

/// 将现有 Intent 包装为 Command 的适配器
class IntentCommand extends Command {
  final Intent _intent;

  @override
  final String id;

  @override
  final String label;

  @override
  final String? category;

  @override
  final SingleActivator? shortcut;

  IntentCommand({
    required this.id,
    required this.label,
    required Intent intent,
    this.category,
    this.shortcut,
  }) : _intent = intent;

  @override
  void execute(BuildContext context, WidgetRef ref) {
    Actions.invoke(context, _intent);
  }
}
