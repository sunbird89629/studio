import 'package:terminal_studio/src/platform/hosts/host_connector.dart';
import 'package:terminal_studio/src/platform/hosts/local_host.dart';

class LocalConnector extends HostConnector<LocalHost> {
  LocalConnector();

  @override
  Future<LocalHost> createHost() async {
    return LocalHost();
  }
}
