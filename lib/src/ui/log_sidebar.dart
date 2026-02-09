import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/log/log_entry.dart';
import '../core/service/log_service.dart';

/// 日志侧边栏面板
class LogSidebar extends ConsumerStatefulWidget {
  const LogSidebar({super.key});

  @override
  ConsumerState<LogSidebar> createState() => _LogSidebarState();
}

class _LogSidebarState extends ConsumerState<LogSidebar> {
  LogLevel? _levelFilter;
  String? _channelFilter;
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      });
    }
  }

  List<LogEntry> _filterEntries(List<LogEntry> entries) {
    return entries.where((e) {
      if (_levelFilter != null && e.level != _levelFilter) return false;
      if (_channelFilter != null && e.channel != _channelFilter) return false;
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
    final theme = FluentTheme.of(context);

    return Column(
      children: [
        // 标题栏
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.micaBackgroundColor),
            ),
          ),
          child: Row(
            children: [
              const Icon(FluentIcons.event_info),
              const SizedBox(width: 8),
              Text('Logs', style: theme.typography.subtitle),
              const Spacer(),
              // 自动滚动开关
              Tooltip(
                message: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
                child: ToggleButton(
                  checked: _autoScroll,
                  onChanged: (v) => setState(() => _autoScroll = v),
                  child: const Icon(FluentIcons.down),
                ),
              ),
              const SizedBox(width: 4),
              // 清空按钮
              IconButton(
                icon: const Icon(FluentIcons.delete),
                onPressed: () {
                  logService.buffer.clear();
                  setState(() {});
                },
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
                child: ComboBox<LogLevel?>(
                  placeholder: const Text('All Levels'),
                  value: _levelFilter,
                  items: [
                    const ComboBoxItem(value: null, child: Text('All Levels')),
                    ...LogLevel.values.map((l) => ComboBoxItem(
                          value: l,
                          child: Text(l.shortName),
                        )),
                  ],
                  onChanged: (v) => setState(() => _levelFilter = v),
                ),
              ),
              const SizedBox(width: 8),
              // 通道过滤
              Expanded(
                child: ComboBox<String?>(
                  placeholder: const Text('All Channels'),
                  value: _channelFilter,
                  items: [
                    const ComboBoxItem(
                        value: null, child: Text('All Channels')),
                    ...logService.buffer.channels.map((c) => ComboBoxItem(
                          value: c,
                          child: Text(c),
                        )),
                  ],
                  onChanged: (v) => setState(() => _channelFilter = v),
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
              final entries = _filterEntries(logService.buffer.entries);

              if (snapshot.hasData) {
                _scrollToBottom();
              }

              if (entries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.text_document,
                          size: 48, color: theme.inactiveColor),
                      const SizedBox(height: 8),
                      Text('No logs yet',
                          style: TextStyle(color: theme.inactiveColor)),
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
    final theme = FluentTheme.of(context);
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
            style: theme.typography.caption?.copyWith(
              color: theme.inactiveColor,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          // 级别标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              entry.level.shortName,
              style: theme.typography.caption?.copyWith(
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
            style: theme.typography.caption?.copyWith(
              color: Colors.purple,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          // 消息
          Expanded(
            child: SelectableText(
              entry.message,
              style: theme.typography.body?.copyWith(
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
