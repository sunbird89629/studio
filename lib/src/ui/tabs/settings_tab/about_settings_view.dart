import 'dart:convert';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/service/config_export_service.dart';
import 'package:terminal_studio/src/core/service/release_notes_service.dart';
import 'package:terminal_studio/src/ui/shared/release_notes_dialog.dart';

class AboutSettingsView extends ConsumerWidget {
  const AboutSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('About')),
      content: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TerminalStudio',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: ref.read(releaseNotesServiceProvider).getAppVersion(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text('Version: ${snapshot.data}');
                }
                return const Text('Loading version...');
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Copyright © 2024 TerminalStudio Contributors',
            ),
            const SizedBox(height: 24),
            Button(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ReleaseNotesDialog(),
                );
              },
              child: const Text('Show Release Notes'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Configuration',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: () => _exportConfig(context, ref),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.download, size: 14),
                      SizedBox(width: 8),
                      Text('Export Configuration'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Button(
                  onPressed: () => _importConfig(context, ref),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.upload, size: 14),
                      SizedBox(width: 8),
                      Text('Import Configuration'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Export or import settings, profiles, keymaps, and SSH hosts.',
              style: TextStyle(
                color: FluentTheme.of(context).inactiveColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportConfig(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(configExportServiceProvider);
      final json = await service.exportAsJson();

      // Write to a temp file and show success
      final home = Platform.environment['HOME'] ?? '/tmp';
      final exportPath = '$home/terminal_studio_config.json';
      await File(exportPath).writeAsString(json);

      if (context.mounted) {
        await displayInfoBar(
          context,
          builder: (ctx, close) => InfoBar(
            title: const Text('Configuration Exported'),
            content: Text('Saved to: $exportPath'),
            severity: InfoBarSeverity.success,
            action: IconButton(
              icon: const Icon(FluentIcons.chrome_close),
              onPressed: close,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        await displayInfoBar(
          context,
          builder: (ctx, close) => InfoBar(
            title: const Text('Export Failed'),
            content: Text('$e'),
            severity: InfoBarSeverity.error,
            action: IconButton(
              icon: const Icon(FluentIcons.chrome_close),
              onPressed: close,
            ),
          ),
        );
      }
    }
  }

  Future<void> _importConfig(BuildContext context, WidgetRef ref) async {
    // Show a dialog asking to select the file path
    final controller = TextEditingController();
    final home = Platform.environment['HOME'] ?? '/tmp';
    controller.text = '$home/terminal_studio_config.json';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Import Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the path to the configuration file:'),
            const SizedBox(height: 12),
            TextBox(
              controller: controller,
              placeholder: 'File path',
            ),
            const SizedBox(height: 8),
            Text(
              '⚠ Existing settings will be overwritten.',
              style: TextStyle(
                color: Colors.warningPrimaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          FilledButton(
            child: const Text('Import'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final filePath = controller.text.trim();
      final file = File(filePath);
      if (!await file.exists()) {
        if (context.mounted) {
          await displayInfoBar(
            context,
            builder: (ctx, close) => InfoBar(
              title: const Text('File Not Found'),
              content: Text(filePath),
              severity: InfoBarSeverity.error,
              action: IconButton(
                icon: const Icon(FluentIcons.chrome_close),
                onPressed: close,
              ),
            ),
          );
        }
        return;
      }

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final service = ref.read(configExportServiceProvider);
      final result = await service.importConfig(data);

      if (context.mounted) {
        await displayInfoBar(
          context,
          builder: (ctx, close) => InfoBar(
            title: Text(result.success ? 'Import Successful' : 'Import Failed'),
            content: Text(result.message),
            severity: result.success
                ? InfoBarSeverity.success
                : InfoBarSeverity.error,
            action: IconButton(
              icon: const Icon(FluentIcons.chrome_close),
              onPressed: close,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        await displayInfoBar(
          context,
          builder: (ctx, close) => InfoBar(
            title: const Text('Import Failed'),
            content: Text('$e'),
            severity: InfoBarSeverity.error,
            action: IconButton(
              icon: const Icon(FluentIcons.chrome_close),
              onPressed: close,
            ),
          ),
        );
      }
    }
  }
}
