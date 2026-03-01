import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/platform/hosts/host_connector.dart';
import 'package:terminal_studio/src/platform/plugins/exceptions.dart';
import 'package:terminal_studio/src/platform/hosts/ssh_connection_pool.dart';
import 'package:terminal_studio/src/platform/hosts/ssh_host.dart';
import 'package:terminal_studio/src/shared/models/records/ssh_host_record.dart';

class SSHConnector extends HostConnector<SSHHost> {
  final SSHHostRecord record;

  SSHConnector(this.record);

  @override
  Future<SSHHost> createHost() async {
    final client = await SSHConnectionPool.instance.acquire(
      username: record.username!,
      host: record.host,
      port: record.port,
      connect: _createFreshClient,
    );
    return SSHHost(client, _releasePoolEntry);
  }

  /// Creates a brand-new [SSHClient] — called only when the pool has no
  /// live entry for this host.
  Future<SSHClient> _createFreshClient() async {
    final socket = await AsyncValue.guard(
      () => SSHSocket.connect(record.host, record.port),
    );

    if (socket.hasError) {
      final error = socket.error!;
      throw SSHConnectionException('Failed to connect: $error');
    }

    final client = SSHClient(
      socket.value!,
      username: record.username!,
      onPasswordRequest: () => record.password,
    );

    final authenticated = await AsyncValue.guard(() => client.authenticated);

    if (authenticated.hasError) {
      final error = authenticated.error!;
      throw SSHAuthException('Failed to authenticate: $error');
    }

    return client;
  }

  void _releasePoolEntry() {
    SSHConnectionPool.instance.release(record.username!, record.host, record.port);
  }
}
