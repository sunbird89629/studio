// Import the language & theme
import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flex_tabs/flex_tabs.dart';
import 'package:highlight/languages/all.dart';
import 'package:terminal_studio/src/core/fs.dart';

class CodeEditorTab extends TabItem {
  final File file;

  CodeEditorTab(this.file) {
    title.value = Text(file.basename);
    content.value = CodeEditorView(this);
    loadContent();
  }

  final codeController = ValueNotifier<CodeController?>(null);

  Future<void> loadContent() async {
    final content = await file.readAsString();
    codeController.value = CodeController(
      text: content,
      language: _detectLanguage(content),
    );
  }
}

class CodeEditorView extends StatelessWidget {
  const CodeEditorView(this.tab, {super.key});

  final CodeEditorTab tab;

  static const fontFamily = 'SourceCode';

  static const fontFamilyFallback = [
    'Menlo', // macos
    'Consolas', // windows
    'monospace',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildToolbar(),
          const Divider(height: 1),
          Expanded(child: _buildEditor()),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save',
            onPressed: () async {
              final controller = tab.codeController.value;
              if (controller == null) return;
              await tab.file.writeAsString(controller.value.text);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return ValueListenableBuilder<CodeController?>(
      valueListenable: tab.codeController,
      builder: (context, codeController, child) {
        if (codeController == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: SingleChildScrollView(
            child: CodeField(
              controller: codeController,
              lineNumberStyle: const LineNumberStyle(
                textStyle: TextStyle(
                  fontFamily: fontFamily,
                  fontFamilyFallback: fontFamilyFallback,
                ),
              ),
              textStyle: const TextStyle(
                fontFamily: fontFamily,
                fontSize: 12,
                fontFamilyFallback: fontFamilyFallback,
              ),
            ),
          ),
        );
      },
    );
  }
}

Mode _detectLanguage(String source) {
  final result = highlight.parse(source, autoDetection: true);
  return allLanguages[result.language]!;
}
