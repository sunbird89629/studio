import 'package:terminal_studio/src/core/command/command.dart';

/// 命令注册表，管理所有可用命令
class CommandRegistry {
  final _commands = <String, Command>{};

  /// 注册一个命令
  void register(Command command) {
    if (_commands.containsKey(command.id)) {
      throw StateError('Command with id "${command.id}" already registered');
    }
    _commands[command.id] = command;
  }

  /// 注册多个命令
  void registerAll(Iterable<Command> commands) {
    for (final command in commands) {
      register(command);
    }
  }

  /// 注销一个命令
  void unregister(String id) {
    _commands.remove(id);
  }

  /// 获取所有已注册的命令
  List<Command> get all => List.unmodifiable(_commands.values.toList());

  /// 根据 ID 获取命令
  Command? get(String id) => _commands[id];

  /// 搜索命令（模糊匹配）
  ///
  /// 搜索逻辑：
  /// 1. 空查询返回所有命令
  /// 2. 按 label 和 category 进行模糊匹配
  /// 3. 结果按匹配度排序
  List<Command> search(String query) {
    if (query.isEmpty) {
      return all;
    }

    final lowerQuery = query.toLowerCase();
    final results = <_SearchResult>[];

    for (final command in _commands.values) {
      final score = _calculateScore(command, lowerQuery);
      if (score > 0) {
        results.add(_SearchResult(command, score));
      }
    }

    // 按分数降序排序
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.map((r) => r.command).toList();
  }

  /// 计算命令与查询的匹配分数
  int _calculateScore(Command command, String lowerQuery) {
    final label = command.label.toLowerCase();
    final category = command.category?.toLowerCase() ?? '';

    // 完全匹配 label 开头得高分
    if (label.startsWith(lowerQuery)) {
      return 100;
    }

    // label 包含查询字符串
    if (label.contains(lowerQuery)) {
      return 80;
    }

    // category 匹配
    if (category.contains(lowerQuery)) {
      return 60;
    }

    // 模糊匹配：检查所有查询字符是否按顺序出现
    if (_fuzzyMatch(label, lowerQuery)) {
      return 40;
    }

    return 0;
  }

  /// 简单的模糊匹配：检查 query 中的字符是否按顺序出现在 text 中
  bool _fuzzyMatch(String text, String query) {
    var queryIndex = 0;
    for (var i = 0; i < text.length && queryIndex < query.length; i++) {
      if (text[i] == query[queryIndex]) {
        queryIndex++;
      }
    }
    return queryIndex == query.length;
  }
}

class _SearchResult {
  final Command command;
  final int score;

  _SearchResult(this.command, this.score);
}
