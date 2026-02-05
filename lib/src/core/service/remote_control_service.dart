import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:terminal_studio/src/core/service/active_tab_service.dart';
import 'package:terminal_studio/src/core/utils/ai_logger.dart';
import 'package:terminal_studio/src/plugins/terminal/terminal_plugin.dart';
import 'package:terminal_studio/src/ui/tabs/plugin_tab.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
      final router = Router();

      // 1. Web Console HTML
      router.get('/', (shelf.Request request) {
        final queryToken = request.url.queryParameters['token'] ?? '';
        return shelf.Response.ok(
          _buildWebConsoleHtml(authToken: queryToken),
          headers: {'content-type': 'text/html'},
        );
      });

      // 2. WebSocket Upgrade
      router.get('/ws', (shelf.Request request) {
        return webSocketHandler((Object webSocket, _) {
          if (webSocket is WebSocketChannel) {
            _handleNewConnection(webSocket, authToken);
          }
        })(request);
      });

      _server = await io.serve(router.call, '0.0.0.0', port);

      final localIp = await _getLocalIp();
      final localUrl =
          'http://$localIp:$port'; // Change to HTTP for web console
      final wsUrl = 'ws://$localIp:$port/ws';
      _logger.i('Remote WebSocket: $wsUrl');

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

    _logger.i(
      'Remote Control Server stopped',
      context: const LogContext(component: 'RemoteControlService'),
    );
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
          _forwardInputToActiveTerminal(input);
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

  void _forwardInputToActiveTerminal(String input) {
    final activeTab = ref.read(activeTabServiceProvider).getActiveTab();
    if (activeTab is PluginTab) {
      final plugin = activeTab.plugin;
      if (plugin is TerminalPlugin) {
        plugin.session?.write(utf8.encode(input));
        _logger.d('Forwarded remote input to active terminal',
            context: const LogContext(component: 'RemoteControlService'));
        return;
      }
    }
    _logger.w('No active Terminal session found to forward input',
        context: const LogContext(component: 'RemoteControlService'));
  }

  String _buildWebConsoleHtml({String authToken = ''}) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OpenTerm Console</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/xterm@5.3.0/css/xterm.min.css">
    <script src="https://cdn.jsdelivr.net/npm/xterm@5.3.0/lib/xterm.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/xterm-addon-fit@0.8.0/lib/xterm-addon-fit.min.js"></script>
    <style>
        body { margin: 0; background: #000; color: #fff; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; height: 100vh; display: flex; flex-direction: column; }
        header { padding: 10px 20px; background: #1e1e1e; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #333; }
        #terminal-container { flex: 1; padding: 10px; background: #000; overflow: hidden; }
        .status-bar { padding: 5px 20px; font-size: 12px; background: #1e1e1e; color: #888; border-top: 1px solid #333; }
        .auth-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.85); display: flex; justify-content: center; align-items: center; z-index: 100; backdrop-filter: blur(5px); }
        .auth-card { background: #252526; padding: 30px; border-radius: 8px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); width: 320px; }
        h2 { margin-top: 0; color: #fff; font-size: 1.2rem; }
        input { width: 100%; border: 1px solid #333; background: #3c3c3c; color: #fff; padding: 10px; box-sizing: border-box; border-radius: 4px; margin: 15px 0; outline: none; }
        input:focus { border-color: #007acc; }
        button { width: 100%; background: #007acc; color: #fff; border: none; padding: 10px; border-radius: 4px; cursor: pointer; font-weight: bold; }
        button:hover { background: #0062a3; }
    </style>
</head>
<body>
    <header>
        <div style="font-weight: bold; color: #007acc;">OpenTerm <span style="color: #888; font-weight: normal;">Remote</span></div>
        <div id="connection-status" style="font-size: 12px; color: #f44336;">Disconnected</div>
    </header>

    <div id="terminal-container"></div>

    <div class="status-bar">
        Connected: <span id="client-id">-</span>
    </div>

    <div id="auth-overlay" class="auth-overlay" style="display: none;">
        <div class="auth-card">
            <h2>Authentication Required</h2>
            <p style="color: #888; font-size: 13px;">Enter the token displayed in OpenTerm settings.</p>
            <input type="password" id="token-input" placeholder="Access Token" value="$authToken">
            <button onclick="authenticate()">Connect</button>
        </div>
    </div>

    <script>
        const term = new Terminal({
            cursorBlink: true,
            fontSize: 14,
            theme: { background: '#000000' }
        });
        const fitAddon = new FitAddon.FitAddon();
        term.loadAddon(fitAddon);
        term.open(document.getElementById('terminal-container'));
        fitAddon.fit();

        window.addEventListener('resize', () => fitAddon.fit());

        let ws;
        const statusEl = document.getElementById('connection-status');
        const overlayEl = document.getElementById('auth-overlay');
        const tokenInput = document.getElementById('token-input');

        function connect() {
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const wsUrl = protocol + '//' + window.location.host + '/ws';
            ws = new WebSocket(wsUrl);

            ws.onopen = () => {
                statusEl.textContent = 'Authenticating...';
                statusEl.style.color = '#ff9800';
                
                // Auto-auth if token is provided
                const token = tokenInput.value;
                if (token) {
                    authenticate();
                } else {
                    overlayEl.style.display = 'flex';
                }
            };

            ws.onmessage = (event) => {
                const msg = JSON.parse(event.data);
                if (msg.type === 'auth_success') {
                    overlayEl.style.display = 'none';
                    statusEl.textContent = 'Connected';
                    statusEl.style.color = '#4caf50';
                    document.getElementById('client-id').textContent = msg.clientId;
                    term.focus();
                } else if (msg.type === 'auth_failed') {
                    alert('Authentication failed. Invalid token.');
                    overlayEl.style.display = 'flex';
                    statusEl.textContent = 'Auth Failed';
                    statusEl.style.color = '#f44336';
                } else if (msg.type === 'output') {
                    term.write(msg.data);
                }
            };

            ws.onclose = () => {
                statusEl.textContent = 'Disconnected';
                statusEl.style.color = '#f44336';
                setTimeout(connect, 3000); // Reconnect loop
            };
        }

        function authenticate() {
            const token = tokenInput.value;
            if (!token) return;
            ws.send(JSON.stringify({ type: 'auth', token: token }));
        }

        term.onData(data => {
            if (ws && ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify({ type: 'input', data: data }));
            }
        });

        connect();
    </script>
</body>
</html>
''';
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
