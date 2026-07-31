import 'package:open_term/src/platform/hosts/host_connector.dart';
import 'package:open_term/src/platform/hosts/local_host.dart';

class LocalConnector extends HostConnector<LocalHost> {
  LocalConnector();

  @override
  Future<LocalHost> createHost() async {
    return LocalHost();
  }
}
