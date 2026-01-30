import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:hive_ce/hive_ce.dart';
import 'package:terminal_studio/src/core/record/ssh_host_record.dart';
import 'package:terminal_studio/src/core/state/database.dart';

void main() {
  test('Database works with Hive CE', () async {
    // Create a temporary directory for Hive
    final tempDir = await Directory.systemTemp.createTemp('hive_test');

    // Override hiveProvider to use the temp directory and synchronous init
    final container = ProviderContainer(
      overrides: [
        hiveProvider.overrideWith((ref) async {
          Hive.init(tempDir.path);
          return Hive;
        }),
      ],
    );

    addTearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    // Test SSHHostRecord persistence
    final box = await container.read(sshHostBoxProvider.future);

    final record = SSHHostRecord(
      name: 'Test Host',
      host: 'example.com',
      port: 22,
      username: 'user',
    );

    await box.add(record);

    expect(box.length, 1);
    expect(box.getAt(0)?.host, 'example.com');

    // Verify list provider
    final list = await container.read(sshHostsProvider.future);
    expect(list.length, 1);
    expect(list.first.host, 'example.com');
  });
}
