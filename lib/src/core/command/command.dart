import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 命令的抽象基类
///
/// 所有可通过 Command Palette 执行的命令都应继承此类。
abstract class Command {
  /// 唯一标识符，如 'terminal.newTab'
  String get id;

  /// 显示名称，如 'New Terminal Tab'
  String get label;

  /// 分类，如 'File', 'Edit', 'View'
  String? get category => null;

  /// 快捷键（如有）
  SingleActivator? get shortcut => null;

  /// 命令是否可用
  bool isEnabled(BuildContext context) => true;

  /// 执行命令
  void execute(BuildContext context, WidgetRef ref);
}
