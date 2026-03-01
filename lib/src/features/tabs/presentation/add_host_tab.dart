import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/features/ssh/application/host_edit_page.dart';

class AddHostTab extends TabItem {
  AddHostTab() {
    title.value = const Text('Connect');
    content.value = const AddHostTabView();
  }
}

class AddHostTabView extends ConsumerStatefulWidget {
  const AddHostTabView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AddHostTabViewState();
}

class _AddHostTabViewState extends ConsumerState<AddHostTabView> {
  @override
  Widget build(BuildContext context) {
    return const HostEditPage();
  }
}
