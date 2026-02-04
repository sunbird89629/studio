import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:terminal_studio/src/core/utils/ai_logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

class RemoteControlState {
  final bool isEnabled;
  final int port;
  final String? authToken;
  final String? localUrl;
  final String? publicUrl;
  final List<String> activeClients;

  RemoteControlState({
    required this.isEnabled,
    required this.port,
    this.authToken,
    this.localUrl,
    this.publicUrl,
    this.activeClients = const [],
  });

  factory RemoteControlState.initial() {
    return RemoteControlState(
      isEnabled: false,
      port: 8080,
    );
  }

  RemoteControlState copyWith({
    bool? isEnabled,
    int? port,
    String? authToken,
    String? localUrl,
    String? publicUrl,
    List<String>? activeClients,
  }) {
    return RemoteControlState(
      isEnabled: isEnabled ?? this.isEnabled,
      port: port ?? this.port,
      authToken: authToken ?? this.authToken,
      localUrl: localUrl ?? this.localUrl,
      publicUrl: publicUrl ?? this.publicUrl,
      activeClients: activeClients ?? this.activeClients,
    );
  }
}

class RemoteControlNotifier extends Notifier<RemoteControlState> {
  HttpServer? _server;
  final _logger = AILogger();
  final _connections = <String, WebSocketChannel>{};

  @override
  RemoteControlState build() {
    return RemoteControlState.initial();
  }

  Future<void> start({int port = 8080, String? token}) async {
    if (state.isEnabled) await stop();

    final authToken = token ?? const Uuid().v4().substring(0, 8);

    try {
      final handler = webSocketHandler((Object webSocket, _) {
        if (webSocket is WebSocketChannel) {
          _handleNewConnection(webSocket, authToken);
        }
      });

      _server = await io.serve(handler, '0.0.0.0', port);

      final localIp = await _getLocalIp();
      final localUrl = 'ws://$localIp:$port';

      state = state.copyWith(
        isEnabled: true,
        port: port,
        authToken: authToken,
        localUrl: localUrl,
      );

      _logger.i(
          'Remote Control Server started at $localUrl (Token: $authToken)',
          context: const LogContext(component: 'RemoteControlService'));
    } catch (e) {
      _logger.e('Failed to start Remote Control Server: $e',
          context: const LogContext(component: 'RemoteControlService'));
      rethrow;
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;

    for (final channel in _connections.values) {
      channel.sink.close();
    }
    _connections.clear();

    state = state.copyWith(
      isEnabled: false,
      activeClients: [],
    );

    _logger.i('Remote Control Server stopped',
        context: const LogContext(component: 'RemoteControlService'));
  }

  void _handleNewConnection(WebSocketChannel channel, String requiredToken) {
    String? clientId;
    bool authenticated = false;

    channel.stream.listen((message) {
      try {
        final data = jsonDecode(message as String);
        final type = data['type'];

        if (!authenticated) {
          if (type == 'auth' && data['token'] == requiredToken) {
            authenticated = true;
            clientId = const Uuid().v4();
            _connections[clientId!] = channel;
            state = state
                .copyWith(activeClients: [...state.activeClients, clientId!]);

            channel.sink.add(jsonEncode({
              'type': 'auth_success',
              'clientId': clientId,
            }));
            _logger.i('Remote client $clientId authenticated',
                context: const LogContext(component: 'RemoteControlService'));
          } else {
            channel.sink.add(jsonEncode({'type': 'auth_failed'}));
            channel.sink.close();
          }
          return;
        }

        // Handle terminal input from remote
        if (type == 'input') {
          final input = data['data'] as String;
          // TODO: Forward to active terminal session
          _logger.d('Received remote input: $input',
              context: const LogContext(component: 'RemoteControlService'));
        }
      } catch (e) {
        _logger.e('Error handling remote message: $e',
            context: const LogContext(component: 'RemoteControlService'));
      }
    }, onDone: () {
      if (clientId != null) {
        _connections.remove(clientId);
        state = state.copyWith(
            activeClients:
                state.activeClients.where((id) => id != clientId).toList());
        _logger.i('Remote client $clientId disconnected',
            context: const LogContext(component: 'RemoteControlService'));
      }
    });
  }

  /// Broadcast terminal output to all authenticated clients
  void broadcastTerminalOutput(String output) {
    if (!state.isEnabled || _connections.isEmpty) return;

    final message = jsonEncode({
      'type': 'output',
      'data': output,
    });

    for (final channel in _connections.values) {
      channel.sink.add(message);
    }
  }

  Future<String> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return 'localhost';
  }
}

final remoteControlServiceProvider =
    NotifierProvider<RemoteControlNotifier, RemoteControlState>(
        RemoteControlNotifier.new);
