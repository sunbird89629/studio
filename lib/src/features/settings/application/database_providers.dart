import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/shared/models/records/profile_record.dart';
import 'package:terminal_studio/src/shared/models/records/ssh_host_record.dart';
import 'package:terminal_studio/src/shared/models/records/ssh_key_record.dart';
import 'package:terminal_studio/src/features/settings/infrastructure/config_file_repository.dart';
import 'package:terminal_studio/src/features/ssh/infrastructure/ssh_storage_repository.dart';

/// SSH hosts loaded from `~/.config/openterm/hosts.json`.
final sshHostsProvider = FutureProvider<List<SSHHostRecord>>((ref) async {
  final service = ref.read(sshStorageServiceProvider);
  return service.loadHosts();
});

/// SSH keys loaded from `~/.config/openterm/keys.json`.
final sshKeysProvider = FutureProvider<List<SSHKeyRecord>>((ref) async {
  final service = ref.read(sshStorageServiceProvider);
  return service.loadKeys();
});

/// Profiles loaded from the `profiles` section of `config.jsonc`.
final profilesProvider = FutureProvider<List<ProfileRecord>>((ref) async {
  final config = ref.read(configFileServiceProvider);
  return config.loadProfiles();
});
