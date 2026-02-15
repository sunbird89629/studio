import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          ],
        ),
      ),
    );
  }
}
