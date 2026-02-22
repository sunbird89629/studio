import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_studio/src/core/record/ssh_host_record.dart';
import 'package:terminal_studio/src/core/service/ssh_storage_service.dart';
import 'package:terminal_studio/src/core/state/database.dart';

void main() {
  test('SshStorageService persists and loads SSH hosts', () async {
    final tempDir = await Directory.systemTemp.createTemp('ssh_storage_test');
    final service = SshStorageService(configDir: tempDir.path);

    final record = SSHHostRecord(
      name: 'Test Host',
      host: 'example.com',
      port: 22,
      username: 'user',
    );

    await service.saveHosts([record]);

    final loaded = await service.loadHosts();
    expect(loaded.length, 1);
    expect(loaded.first.host, 'example.com');
    expect(loaded.first.name, 'Test Host');
    expect(loaded.first.port, 22);
    expect(loaded.first.username, 'user');

    await tempDir.delete(recursive: true);
  });

  test('sshHostsProvider loads from SshStorageService', () async {
    final container = ProviderContainer(
      overrides: [
        sshStorageServiceProvider.overrideWithValue(
          SshStorageService(configDir: Directory.systemTemp.path),
        ),
      ],
    );
    addTearDown(container.dispose);

    final hosts = await container.read(sshHostsProvider.future);
    expect(hosts, isA<List<SSHHostRecord>>());
  });
}
