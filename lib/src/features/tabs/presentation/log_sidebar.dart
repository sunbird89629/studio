import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:open_term/src/shared/logging/log_entry.dart';
import 'package:open_term/src/shared/logging/log_service.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class LogFilterState {
  final LogLevel? levelFilter;
  final String? channelFilter;
  final bool autoScroll;

  const LogFilterState({
    this.levelFilter,
    this.channelFilter,
    this.autoScroll = true,
  });

  LogFilterState copyWith({
    Object? levelFilter = _sentinel,
    Object? channelFilter = _sentinel,
    bool? autoScroll,
  }) =>
      LogFilterState(
        levelFilter:
            levelFilter == _sentinel ? this.levelFilter : levelFilter as LogLevel?,
        channelFilter:
            channelFilter == _sentinel ? this.channelFilter : channelFilter as String?,
        autoScroll: autoScroll ?? this.autoScroll,
      );
}

const _sentinel = Object();

// ── Notifier ──────────────────────────────────────────────────────────────────

class LogFilterNotifier extends Notifier<LogFilterState> {
  @override
  LogFilterState build() => const LogFilterState();

  void setLevelFilter(LogLevel? level) =>
      state = state.copyWith(levelFilter: level ?? _sentinel);

  void setChannelFilter(String? channel) =>
      state = state.copyWith(channelFilter: channel ?? _sentinel);

  void toggleAutoScroll() =>
      state = state.copyWith(autoScroll: !state.autoScroll);
}

final logFilterProvider =
    NotifierProvider<LogFilterNotifier, LogFilterState>(LogFilterNotifier.new);

// ── Widget ────────────────────────────────────────────────────────────────────

/// 日志侧边栏面板
class LogSidebar extends ConsumerStatefulWidget {
  const LogSidebar({super.key});

  @override
  ConsumerState<LogSidebar> createState() => _LogSidebarState();
}

class _LogSidebarState extends ConsumerState<LogSidebar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom(bool autoScroll) {
    if (autoScroll && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      });
    }
  }

  List<LogEntry> _filterEntries(
      List<LogEntry> entries, LogFilterState filter) {
    return entries.where((e) {
      if (filter.levelFilter != null && e.level != filter.levelFilter) {
        return false;
      }
      if (filter.channelFilter != null && e.channel != filter.channelFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logService = ref.watch(logServiceProvider);
    final filter = ref.watch(logFilterProvider);
    final filterNotifier = ref.read(logFilterProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // 标题栏
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 8),
              Text('Logs', style: theme.textTheme.titleMedium),
              const Spacer(),
              // 自动滚动开关
              IconButton(
                icon: Icon(filter.autoScroll
                    ? Icons.vertical_align_bottom
                    : Icons.vertical_align_bottom_outlined),
                tooltip:
                    filter.autoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
                color:
                    filter.autoScroll ? colorScheme.primary : theme.disabledColor,
                onPressed: filterNotifier.toggleAutoScroll,
              ),
              const SizedBox(width: 4),
              // 清空按钮
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear Logs',
                onPressed: () => logService.buffer.clear(),
              ),
            ],
          ),
        ),

        // 过滤器
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // 级别过滤
              Expanded(
                child: DropdownButton<LogLevel?>(
                  isExpanded: true,
                  hint: const Text('All Levels'),
                  value: filter.levelFilter,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Levels')),
                    ...LogLevel.values.map((l) => DropdownMenuItem(
                          value: l,
                          child: Text(l.shortName),
                        )),
                  ],
                  onChanged: filterNotifier.setLevelFilter,
                ),
              ),
              const SizedBox(width: 8),
              // 通道过滤
              Expanded(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  hint: const Text('All Channels'),
                  value: filter.channelFilter,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Channels')),
                    ...logService.buffer.channels.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: filterNotifier.setChannelFilter,
                ),
              ),
            ],
          ),
        ),

        // 日志列表
        Expanded(
          child: StreamBuilder<LogEntry>(
            stream: logService.stream,
            builder: (context, snapshot) {
              final entries =
                  _filterEntries(logService.buffer.entries, filter);

              if (snapshot.hasData) {
                _scrollToBottom(filter.autoScroll);
              }

              if (entries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_outlined,
                          size: 48, color: theme.disabledColor),
                      const SizedBox(height: 8),
                      Text('No logs yet',
                          style: TextStyle(color: theme.disabledColor)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _LogEntryTile(
                    entry: entry,
                    levelColor: _getLevelColor(entry.level),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  final LogEntry entry;
  final Color levelColor;

  const _LogEntryTile({
    required this.entry,
    required this.levelColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final time =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间戳
          Text(
            time,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.disabledColor,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          // 级别标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              entry.level.shortName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: levelColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 通道
          Text(
            entry.channel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.secondary,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          // 消息
          Expanded(
            child: SelectableText(
              entry.message,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
