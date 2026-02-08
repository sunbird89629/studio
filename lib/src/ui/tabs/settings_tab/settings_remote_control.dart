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

              // Web Access URL
              InfoLabel(
                label: 'Web Console URL (Intranet)',
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormBox(
                        readOnly: true,
                        initialValue: remoteState.localUrl,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Copy URL',
                      child: Button(
                        child: const Icon(FluentIcons.copy),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: remoteState.localUrl ?? ''));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Copy URL with Token',
                      child: Button(
                        child: const Icon(FluentIcons.share),
                        onPressed: () {
                          final urlWithToken =
                              '${remoteState.localUrl}?token=${remoteState.authToken}';
                          Clipboard.setData(ClipboardData(text: urlWithToken));
                        },
                      ),
                    ),
                  ],
                ),
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

              InfoLabel(
                label: 'Cloudflare Tunnel Token',
                child: TextFormBox(
                  placeholder: 'Paste your tunnel token here',
                  initialValue: remoteState.cloudflaredToken,
                  onChanged: (v) => ref
                      .read(remoteControlServiceProvider.notifier)
                      .setCloudflaredToken(v),
                ),
              ),

              const SizedBox(height: 16),

              InfoLabel(
                label: 'Lark (Feishu) Webhook URL',
                child: TextFormBox(
                  placeholder:
                      'https://open.feishu.cn/open-apis/bot/v2/hook/xxx',
                  initialValue: remoteState.larkWebhookUrl,
                  onChanged: (v) => ref
                      .read(remoteControlServiceProvider.notifier)
                      .setLarkWebhookUrl(v),
                ),
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
                  Button(
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
                    Button(
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
                  child: InfoLabel(
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
                            Clipboard.setData(ClipboardData(
                                text: tunnelState.publicUrl ?? ''));
                          },
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Copy with Token',
                          child: Button(
                            child: const Icon(FluentIcons.share),
                            onPressed: () {
                              final urlWithToken =
                                  '${tunnelState.publicUrl}?token=${remoteState.authToken}';
                              Clipboard.setData(
                                  ClipboardData(text: urlWithToken));
                            },
                          ),
                        ),
                      ],
                    ),
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
                            child: ProgressRing(strokeWidth: 2),
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
