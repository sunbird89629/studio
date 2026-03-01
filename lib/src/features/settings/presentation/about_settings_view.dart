import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/features/settings/application/config_export_usecase.dart';
import 'package:terminal_studio/src/shared/state/release_notes_service.dart';
import 'package:terminal_studio/src/shared/widgets/release_notes_dialog.dart';

class AboutSettingsView extends ConsumerWidget {
  const AboutSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
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
            OutlinedButton(
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
                FilledButton.icon(
                  onPressed: () => _exportConfig(context, ref),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export Configuration'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _importConfig(context, ref),
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text('Import Configuration'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Export or import settings, profiles, keymaps, and SSH hosts.',
              style: Theme.of(context).textTheme.bodySmall,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Configuration exported to: $exportPath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
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
      builder: (ctx) => AlertDialog(
        title: const Text('Import Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the path to the configuration file:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'File path',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '⚠ Existing settings will be overwritten.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File not found: $filePath'),
              backgroundColor: Theme.of(context).colorScheme.error,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success
                ? Colors.green
                : Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
