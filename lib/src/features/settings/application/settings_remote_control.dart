import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/features/remote_control/application/remote_control_notifier.dart';
import 'package:terminal_studio/src/features/tunnel/application/tunnel_notifier.dart';

class RemoteControlSettingsView extends ConsumerWidget {
  const RemoteControlSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remoteState = ref.watch(remoteControlServiceProvider);
    final tunnelState = ref.watch(tunnelServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Remote Control')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allow remote management of your terminal sessions from other devices.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Toggle
            SwitchListTile(
              title: Text(remoteState.isEnabled
                  ? 'Service Active'
                  : 'Service Disabled'),
              value: remoteState.isEnabled,
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
              const Text('Authentication Token'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      initialValue: remoteState.authToken,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: remoteState.authToken ?? ''));
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Web Access URL
              const SizedBox(height: 16),
              const Text('Web Console URL (Intranet)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      initialValue: remoteState.localUrl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: remoteState.localUrl ?? ''));
                    },
                    tooltip: 'Copy URL',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      final urlWithToken =
                          '${remoteState.localUrl}?token=${remoteState.authToken}';
                      Clipboard.setData(ClipboardData(text: urlWithToken));
                    },
                    tooltip: 'Copy URL with Token',
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // Intranet Penetration
              const Text('Cloudflare Tunnel',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text(
                  'Expose your local terminal to the public internet via cloudflared.',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),

              const Text('Cloudflare Tunnel Token'),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: remoteState.cloudflaredToken,
                decoration: const InputDecoration(
                  hintText: 'Paste your tunnel token here',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => ref
                    .read(remoteControlServiceProvider.notifier)
                    .setCloudflaredToken(v),
              ),

              const SizedBox(height: 16),

              const Text('Lark (Feishu) Webhook URL'),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: remoteState.larkWebhookUrl,
                decoration: const InputDecoration(
                  hintText: 'https://open.feishu.cn/open-apis/bot/v2/hook/xxx',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => ref
                    .read(remoteControlServiceProvider.notifier)
                    .setLarkWebhookUrl(v),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  FilledButton(
                    onPressed: (tunnelState.status != TunnelStatus.stopped)
                        ? null
                        : () => ref
                            .read(tunnelServiceProvider.notifier)
                            .connectQuick(remoteState.port),
                    child: const Text('Quick Tunnel (TryCloudflare)'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: (tunnelState.isConnected ||
                            remoteState.cloudflaredToken == null ||
                            remoteState.cloudflaredToken!.isEmpty)
                        ? null
                        : () =>
                            ref.read(tunnelServiceProvider.notifier).connect(
                                  remoteState.cloudflaredToken!,
                                ),
                    child: Text(
                        tunnelState.isConnected && tunnelState.publicUrl == null
                            ? 'Tunnel Active'
                            : 'Start Persistent Tunnel'),
                  ),
                  if (tunnelState.status != TunnelStatus.stopped) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () =>
                          ref.read(tunnelServiceProvider.notifier).disconnect(),
                      child: const Text('Stop'),
                    ),
                  ],
                ],
              ),

              if (tunnelState.publicUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Public Access URL'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              readOnly: true,
                              initialValue: tunnelState.publicUrl,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text: tunnelState.publicUrl ?? ''));
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.share),
                            onPressed: () {
                              final urlWithToken =
                                  '${tunnelState.publicUrl}?token=${remoteState.authToken}';
                              Clipboard.setData(
                                  ClipboardData(text: urlWithToken));
                            },
                            tooltip: 'Copy with Token',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              if (tunnelState.status != TunnelStatus.stopped)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    children: [
                      if (tunnelState.status != TunnelStatus.connected)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      Text('Status: ${tunnelState.status.name}',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),

              if (tunnelState.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Error: ${tunnelState.error!}',
                    style: TextStyle(color: Colors.red),
                  ),
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
                          const Icon(Icons.person, size: 16),
                          const SizedBox(width: 8),
                          Text(id,
                              style: Theme.of(context).textTheme.bodySmall),
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
