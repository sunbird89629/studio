import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:open_term/src/features/settings/application/database_providers.dart';
import 'package:open_term/src/features/ssh/application/host_edit_page.dart';

class HostsSettingView extends ConsumerStatefulWidget {
  const HostsSettingView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _HostsSettingViewState();
}

class _HostsSettingViewState extends ConsumerState<HostsSettingView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hosts'),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.plus),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HostEditPage(),
                ),
              );
            },
            tooltip: 'Add',
          ),
        ],
      ),
      body: _buildSSHHosts(),
    );
  }

  Widget _buildSSHHosts() {
    final hosts = ref.watch(sshHostsProvider);

    return hosts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Error: $e'),
      data: (box) => ListView.builder(
        shrinkWrap: true,
        itemCount: box.length,
        itemBuilder: (context, index) {
          final record = box[index];
          return ListTile(
            title: Text(record.name),
            subtitle: Text('${record.host}:${record.port}'),
            leading: const FaIcon(FontAwesomeIcons.computer),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HostEditPage(record: record),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
