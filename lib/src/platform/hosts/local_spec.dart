import 'package:terminal_studio/src/platform/hosts/host_connector.dart';
import 'package:terminal_studio/src/platform/hosts/local_conn.dart';

class LocalHostSpec implements HostSpec {
  const LocalHostSpec();

  @override
  final name = 'Local';

  @override
  HostConnector createConnector() => LocalConnector();

  @override
  bool operator ==(Object other) => other is LocalHostSpec;

  @override
  int get hashCode => name.hashCode;
}
