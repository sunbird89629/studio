import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:terminal_studio/app.dart';
import 'package:terminal_studio/src/features/command_palette/application/intents.dart';
import 'package:terminal_studio/src/features/tabs/application/tabs_service.dart';
import 'package:terminal_studio/src/platform/hosts/local_spec.dart';
import 'package:terminal_studio/src/features/tabs/application/tabs_provider.dart';
import 'package:terminal_studio/src/features/tabs/presentation/home.dart';

Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (predicate()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  throw TestFailure('Timed out waiting for condition after $timeout');
}

Future<void> _openCommandPalette(WidgetTester tester) async {
  final context = tester.element(find.byType(Home));
  Actions.invoke(context, const OpenCommandPaletteIntent());
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('open command palette and create new tab', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final homeContext = tester.element(find.byType(Home));
    final container = ProviderScope.containerOf(homeContext, listen: false);

    int tabCount() => container.read(tabsProvider).root?.children.length ?? 0;

    await _waitUntil(tester, () => tabCount() >= 1);
    final initialTabCount = tabCount();

    // Step 2: open command palette.
    final inputsBeforeOpen = find.byType(EditableText).evaluate().length;
    await _openCommandPalette(tester);
    await _waitUntil(
      tester,
      () => find.byType(EditableText).evaluate().length > inputsBeforeOpen,
    );

    // Step 3: type "new tab".
    final input = find.byType(TextField).last;
    await tester.tap(input);
    await tester.enterText(input, 'new tab');
    await tester.pumpAndSettle();

    // Step 4: execute "new tab" action.
    final rootTabs = container.read(tabsProvider).root;
    expect(rootTabs, isA<Tabs>());
    container.read(tabsServiceProvider).openTerminal(
          const LocalHostSpec(),
          tabs: rootTabs as Tabs,
        );
    await tester.pumpAndSettle();

    await _waitUntil(
      tester,
      () => tabCount() == initialTabCount + 1,
      timeout: const Duration(seconds: 15),
    );

    expect(tabCount(), initialTabCount + 1);
  });
}
