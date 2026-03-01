import 'package:terminal_studio/src/platform/hosts/host_connector.dart';
import 'package:terminal_studio/src/platform/hosts/ssh_conn.dart';
import 'package:terminal_studio/src/shared/utils/uuid.dart';

class SSHHostRecord implements HostSpec {
  String uuid;

  @override
  String name;

  String host;

  int port;

  String? username;

  String? password;

  SSHHostRecord({
    String? uuid,
    required this.name,
    required this.host,
    required this.port,
    this.username,
    this.password,
  }) : uuid = uuid ?? uuidV4();

  SSHHostRecord.uninitialized()
      : this(
          name: '',
          host: '',
          port: 22,
        );

  @override
  HostConnector createConnector() => SSHConnector(this);

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'name': name,
        'host': host,
        'port': port,
        if (username != null) 'username': username,
        if (password != null) 'password': password,
      };

  factory SSHHostRecord.fromJson(Map<String, dynamic> json) {
    return SSHHostRecord(
      uuid: json['uuid'] as String?,
      name: json['name'] as String? ?? '',
      host: json['host'] as String? ?? '',
      port: json['port'] as int? ?? 22,
      username: json['username'] as String?,
      password: json['password'] as String?,
    );
  }
}
