import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:terminal_studio/src/features/command_palette/application/command.dart';
import 'package:terminal_studio/src/features/command_palette/application/command_registry.dart';
import 'package:terminal_studio/src/features/command_palette/application/builtin_commands.dart';
import 'package:terminal_studio/src/features/command_palette/application/snippet_commands.dart';
import 'package:terminal_studio/src/features/command_palette/application/theme_commands.dart';
import 'package:terminal_studio/src/shared/theme/theme_providers.dart';

part 'command_palette_notifier.freezed.dart';

/// Command Palette 状态
@freezed
abstract class CommandPaletteState with _$CommandPaletteState {
  const CommandPaletteState._();

  const factory CommandPaletteState({
    @Default(false) bool isVisible,
    @Default('') String query,
    @Default([]) List<Command> filteredCommands,
    @Default(0) int selectedIndex,
  }) = _CommandPaletteState;

  /// 当前选中的命令
  Command? get selectedCommand =>
      filteredCommands.isNotEmpty && selectedIndex < filteredCommands.length
          ? filteredCommands[selectedIndex]
          : null;
}

/// Command Palette 状态管理 Notifier
class CommandPaletteNotifier extends Notifier<CommandPaletteState> {
  final CommandRegistry _registry = CommandRegistry();

  @override
  CommandPaletteState build() {
    _registry.clear();

    // 注册内置命令
    _registry.registerAll(builtinCommands);

    // 注册主题命令
    final themeRegistry = ref.read(themeRegistryProvider);
    _registry.register(ToggleThemeCommand());
    for (final theme in themeRegistry.all) {
      _registry.register(SelectThemeCommand(
        themeId: theme.id,
        themeName: theme.displayName,
      ));
    }

    // 注册 snippet 命令（当 settings 变化时自动重建）
    final snippetCmds = buildSnippetCommands(ref);
    _registry.registerAll(snippetCmds);

    return CommandPaletteState(
      filteredCommands: _registry.all,
    );
  }

  /// 命令注册表
  CommandRegistry get registry => _registry;

  /// 显示 Command Palette
  void show() {
    state = CommandPaletteState(
      isVisible: true,
      query: '',
      filteredCommands: _registry.all,
      selectedIndex: 0,
    );
  }

  /// 隐藏 Command Palette
  void hide() {
    state = state.copyWith(isVisible: false);
  }

  /// 切换 Command Palette 可见性
  void toggle() {
    if (state.isVisible) {
      hide();
    } else {
      show();
    }
  }

  /// 设置查询字符串
  void setQuery(String query) {
    state = state.copyWith(
      query: query,
      filteredCommands: _registry.search(query),
      selectedIndex: 0,
    );
  }

  /// 选择下一个命令
  void selectNext() {
    if (state.filteredCommands.isEmpty) return;
    state = state.copyWith(
      selectedIndex: (state.selectedIndex + 1) % state.filteredCommands.length,
    );
  }

  /// 选择上一个命令
  void selectPrevious() {
    if (state.filteredCommands.isEmpty) return;
    state = state.copyWith(
      selectedIndex: (state.selectedIndex - 1 + state.filteredCommands.length) %
          state.filteredCommands.length,
    );
  }

  /// 执行当前选中的命令
  void executeSelected(BuildContext context, WidgetRef ref) {
    final command = state.selectedCommand;
    if (command != null && command.isEnabled(context)) {
      hide();
      command.execute(context, ref);
    }
  }

  /// 执行指定命令
  void executeCommand(Command command, BuildContext context, WidgetRef ref) {
    if (command.isEnabled(context)) {
      hide();
      command.execute(context, ref);
    }
  }
}

final commandPaletteServiceProvider =
    NotifierProvider<CommandPaletteNotifier, CommandPaletteState>(
  CommandPaletteNotifier.new,
);
