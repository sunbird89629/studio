import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/service/remote_control_service.dart';
import 'package:terminal_studio/src/core/service/tunnel_service.dart';

class RemoteControlSettingsView extends ConsumerWidget {
  const RemoteControlSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remoteState = ref.watch(remoteControlServiceProvider);
    final tunnelState = ref.watch(tunnelServiceProvider);

    return ScaffoldPage(
      header: const PageHeader(title: Text('Remote Control')),
      content: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Allow remote management of your terminal sessions from other devices.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Toggle
            ToggleSwitch(
              checked: remoteState.isEnabled,
              content: Text(remoteState.isEnabled
                  ? 'Service Active'
                  : 'Service Disabled'),
              onChanged: (v) async {
                if (v) {
                  await ref.read(remoteControlServiceProvider.notifier).start();
                } else {
                  await ref.read(remoteControlServiceProvider.notifier).stop();
                  await ref.read(tunnelServiceProvider.notifier).disconnect();
                }
              },
            ),

            if (remoteState.isEnabled) ...[
              const SizedBox(height: 32),
              const Text('Access Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),

              // Token
              InfoLabel(
                label: 'Authentication Token',
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormBox(
                        readOnly: true,
                        initialValue: remoteState.authToken,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Button(
                      child: const Icon(FluentIcons.copy),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: remoteState.authToken ?? ''));
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Local URL
              InfoLabel(
                label: 'Local Access URL (Intranet)',
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormBox(
                        readOnly: true,
                        initialValue: remoteState.localUrl,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Button(
                      child: const Icon(FluentIcons.copy),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: remoteState.localUrl ?? ''));
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // Intranet Penetration
              const Text('Intranet Penetration',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Expose your local terminal to the public internet.',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),

              Row(
                children: [
                  FilledButton(
                    onPressed: tunnelState.isConnected
                        ? null
                        : () => ref
                            .read(tunnelServiceProvider.notifier)
                            .connect(remoteState.port),
                    child: Text(tunnelState.isConnected
                        ? 'Penetration Active'
                        : 'Enable Public Access'),
                  ),
                  if (tunnelState.isConnected) ...[
                    const SizedBox(width: 8),
                    Button(
                      onPressed: () =>
                          ref.read(tunnelServiceProvider.notifier).disconnect(),
                      child: const Text('Stop'),
                    ),
                  ],
                ],
              ),

              if (tunnelState.isConnected) ...[
                const SizedBox(height: 16),
                InfoLabel(
                  label: 'Public Access URL',
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormBox(
                          readOnly: true,
                          initialValue: tunnelState.publicUrl,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Button(
                        child: const Icon(FluentIcons.copy),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: tunnelState.publicUrl ?? ''));
                        },
                      ),
                    ],
                  ),
                ),
              ],

              if (tunnelState.status != null && !tunnelState.isConnected)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(tunnelState.status!,
                      style: const TextStyle(color: Colors.grey)),
                ),

              const SizedBox(height: 32),
              const Text('Active Clients',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (remoteState.activeClients.isEmpty)
                const Text('No clients connected',
                    style: TextStyle(color: Colors.grey))
              else
                ...remoteState.activeClients.map((id) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const Icon(FluentIcons.contact, size: 12),
                          const SizedBox(width: 8),
                          Text(id, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    )),
            ],
          ],
        ),
      ),
    );
  }
}
