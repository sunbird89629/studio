import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/fs.dart';
import 'package:terminal_studio/src/core/plugin.dart';
import 'package:terminal_studio/src/core/service/tabs_service.dart';
import 'package:terminal_studio/src/plugins/file_manager/navigation_breadcrumbs.dart';
import 'package:terminal_studio/src/plugins/file_manager/navigation_stack.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class FileManagerPlugin extends Plugin {
  late FileSystem fs;

  String? homePath;

  final currentPath = ValueNotifier<String?>(null);

  String? get currentDirectory =>
      currentPath.value == null ? null : fs.path.basename(currentPath.value!);

  final files = ValueNotifier(<FileSystemEntity>[]);

  late final navigationStack = NavigationStack<String>(onNavigate: _onNavigate);

  final _filesCache = <String, List<FileSystemEntity>>{};

  Future<void> _fetchFiles() async {
    final path = currentPath.value;

    if (path == null) {
      return;
    }

    this.files.value = _filesCache[path] ?? [];

    final files = await fs.directory(path).list().fold(
      <FileSystemEntity>[],
      (files, file) => [...files, file],
    );

    _filesCache[path] = files;

    if (currentPath.value == path) {
      this.files.value = files;
    }
  }

  Future<void> _onNavigate(String path) async {
    currentPath.value = fs.path.normalize(path);
    title.value =
        currentDirectory == null ? null : currentDirectory! + fs.path.separator;
    _fetchFiles();
  }

  Future<void> goto(String target) async {
    late final String path;

    if (fs.path.isAbsolute(target)) {
      path = target;
    } else {
      path = fs.path.normalize(fs.path.join(currentPath.value!, target));
    }

    navigationStack.push(path);
  }

  List<String> get breadcrumbs {
    final path = currentPath.value;
    if (path == null) return [];
    final parts = fs.path.split(path);
    return parts;
  }

  bool get canGoUp => breadcrumbs.length > 1;

  Future<void> goUp() async {
    if (!canGoUp) return;
    await goto('..');
  }

  Future<void> goHome() async {
    if (homePath == null) return;
    await goto(homePath!);
  }

  @override
  void didMounted() {
    title.value = 'Files';
  }

  @override
  void didConnected() async {
    fs = await host.connectFileSystem();

    homePath = (await fs.directory('.').absolute).path;

    goto(homePath!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 48, child: FileListToolbar(this)),
          const Divider(height: 1),
          Expanded(child: FileListView(this)),
          const Divider(height: 1),
          SizedBox(height: 40, child: FileListNavigator(this)),
        ],
      ),
    );
  }
}

class FileListToolbar extends StatelessWidget {
  const FileListToolbar(this.plugin, {super.key});

  final FileManagerPlugin plugin;

  NavigationStack<String> get stack => plugin.navigationStack;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: plugin.currentPath,
      builder: (context, currentPath, _) => _buildToolbar(context),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: stack.canGoBack ? stack.back : null,
            tooltip: 'Back',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_outlined),
            onPressed: stack.canGoForward ? stack.forward : null,
            tooltip: 'Forward',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward_outlined),
            onPressed: plugin.canGoUp ? plugin.goUp : null,
            tooltip: 'Up',
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: plugin.homePath == null ? null : plugin.goHome,
            tooltip: 'Home',
          ),
          const VerticalDivider(width: 32, indent: 12, endIndent: 12),
          Expanded(
            child: Text(
              plugin.currentDirectory ?? '',
              style: Theme.of(context).textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => plugin._fetchFiles(),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}

class FileListNavigator extends StatelessWidget {
  const FileListNavigator(this.plugin, {super.key});

  final FileManagerPlugin plugin;

  NavigationStack<String> get stack => plugin.navigationStack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ValueListenableBuilder(
        valueListenable: plugin.currentPath,
        builder: (context, currentPath, _) {
          return NavigationBreadcrumbs(
            breadcrumbs: plugin.breadcrumbs,
            onTap: (breadcrumbs) {
              plugin.goto(plugin.fs.path.joinAll(breadcrumbs));
            },
          );
        },
      ),
    );
  }
}

class FileListView extends ConsumerStatefulWidget {
  const FileListView(this.plugin, {super.key});

  final FileManagerPlugin plugin;

  @override
  FileListViewState createState() => FileListViewState();
}

class FileListViewState extends ConsumerState<FileListView> {
  FileManagerPlugin get plugin => widget.plugin;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: plugin.files,
      builder: (context, files, child) {
        return _buildTable(context, files);
      },
    );
  }

  Widget _buildTable(BuildContext context, List<FileSystemEntity> files) {
    final theme = Theme.of(context);
    final source = _FilesDataSource(files, theme);
    return SfDataGrid(
      headerRowHeight: 40,
      allowSorting: true,
      allowFiltering: true,
      gridLinesVisibility: GridLinesVisibility.horizontal,
      headerGridLinesVisibility: GridLinesVisibility.horizontal,
      horizontalScrollPhysics: const NeverScrollableScrollPhysics(),
      onCellTap: (details) {
        final rowIndex = details.rowColumnIndex.rowIndex;

        if (rowIndex == 0) return;

        final row = source.effectiveRows[rowIndex - 1] as _FileDataGridRow;

        final file = row.file;

        if (file is Directory) {
          plugin.goto(file.path);
        } else if (file is File) {
          ref.read(tabsServiceProvider).openFile(file);
        }
      },
      columns: [
        GridColumn(
          columnName: 'name',
          label: Container(
            padding: const EdgeInsets.all(8),
            alignment: Alignment.centerLeft,
            child: const Text('Name',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          columnWidthMode: ColumnWidthMode.fill,
          allowFiltering: true,
        ),
        GridColumn(
          columnName: 'date',
          label: Container(
            padding: const EdgeInsets.all(8),
            alignment: Alignment.centerLeft,
            child: const Text('Date',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          minimumWidth: 210,
          allowFiltering: false,
        ),
      ],
      source: source,
    );
  }
}

class _FilesDataSource extends DataGridSource {
  _FilesDataSource(this.files, this.theme);

  final List<FileSystemEntity> files;
  final ThemeData theme;

  @override
  late final rows = files
      .where((file) => file.basename != '.' && file.basename != '..')
      .map((file) => _FileDataGridRow(file))
      .toList();

  @override
  DataGridRowAdapter buildRow(covariant _FileDataGridRow row) {
    return DataGridRowAdapter(
      cells: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                row.file is Directory
                    ? Icons.folder_outlined
                    : Icons.description_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  row.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.centerLeft,
          child: Text(row.date),
        ),
      ],
    );
  }
}

class _FileDataGridRow implements DataGridRow {
  _FileDataGridRow(this.file);

  final FileSystemEntity file;

  late final name = file.basename;

  late final date = '${file.cachedStat?.modified ?? ''}';

  @override
  List<DataGridCell> getCells() {
    return [
      DataGridCell<String>(columnName: 'name', value: name),
      DataGridCell<String>(columnName: 'date', value: date),
    ];
  }
}
