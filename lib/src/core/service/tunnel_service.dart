import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/utils/ai_logger.dart';
import 'package:terminal_studio/src/core/model/cloudflared_event.dart';
import 'package:terminal_studio/src/core/utils/cloudflared_log_parser.dart';

enum TunnelStatus {
  stopped,
  starting,
  connected,
  error,
  reconnecting,
}

class TunnelState {
  final TunnelStatus status;
  final String? publicUrl;
  final String? error;
  final String? tunnelId;
  final List<String> connections;

  TunnelState({
    required this.status,
    this.publicUrl,
    this.error,
    this.tunnelId,
    this.connections = const [],
  });

  bool get isConnected => status == TunnelStatus.connected;

  factory TunnelState.initial() {
    return TunnelState(status: TunnelStatus.stopped);
  }

  TunnelState copyWith({
    TunnelStatus? status,
    String? publicUrl,
    String? error,
    String? tunnelId,
    List<String>? connections,
  }) {
    return TunnelState(
      status: status ?? this.status,
      publicUrl: publicUrl ?? this.publicUrl,
      error: error ?? this.error,
      tunnelId: tunnelId ?? this.tunnelId,
      connections: connections ?? this.connections,
    );
  }
}

class TunnelNotifier extends Notifier<TunnelState> {
  final _logger = AILogger();
  Process? _process;
  StreamSubscription? _stdoutSub;
  StreamSubscription? _stderrSub;

  @override
  TunnelState build() {
    return TunnelState.initial();
  }

  Future<void> connect(String token, {int? localPort}) async {
    if (_process != null) await disconnect();

    state = state.copyWith(status: TunnelStatus.starting, error: null);

    _logger.i(
      'Starting cloudflared tunnel',
      context: const LogContext(component: 'TunnelService'),
    );

    try {
      // Command: cloudflared tunnel --no-autoupdate run --token TOKEN
      // We assume cloudflared is in the PATH.
      _process = await Process.start(
        'cloudflared',
        ['tunnel', '--no-autoupdate', 'run', '--token', token],
      );

      _stdoutSub = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleLog);

      _stderrSub = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleLog);

      _process!.exitCode.then((code) {
        _logger.w('Cloudflared process exited with code $code',
            context: const LogContext(component: 'TunnelService'));
        if (state.status != TunnelStatus.stopped) {
          state = state.copyWith(
            status: TunnelStatus.error,
            error: 'Process exited with code $code',
          );
        }
        _cleanup();
      });
    } catch (e) {
      state = state.copyWith(
        status: TunnelStatus.error,
        error: 'Failed to launch cloudflared: $e',
      );
      _logger.e('Tunnel startup failed: $e',
          context: const LogContext(component: 'TunnelService'));
      _cleanup();
    }
  }

  Future<void> connectQuick(int localPort) async {
    if (_process != null) await disconnect();

    state = state.copyWith(status: TunnelStatus.starting, error: null);

    _logger.i(
      'Starting cloudflared quick tunnel for port $localPort',
      context: const LogContext(component: 'TunnelService'),
    );

    try {
      // Command: cloudflared tunnel --no-autoupdate run --url http://localhost:PORT
      _process = await Process.start(
        'cloudflared',
        ['tunnel', '--no-autoupdate', '--url', 'http://localhost:$localPort'],
      );

      _stdoutSub = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleLog);

      _stderrSub = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleLog);

      _process!.exitCode.then((code) {
        _logger.w('Cloudflared quick tunnel process exited with code $code',
            context: const LogContext(component: 'TunnelService'));
        if (state.status != TunnelStatus.stopped) {
          state = state.copyWith(
            status: TunnelStatus.error,
            error: 'Process exited with code $code',
          );
        }
        _cleanup();
      });
    } catch (e) {
      state = state.copyWith(
        status: TunnelStatus.error,
        error: 'Failed to launch cloudflared: $e',
      );
      _logger.e('Tunnel startup failed: $e',
          context: const LogContext(component: 'TunnelService'));
      _cleanup();
    }
  }

  void _handleLog(String line) {
    // If not JSON, it might be a quick tunnel notification
    if (!line.trim().startsWith('{')) {
      if (line.contains('https://') && line.contains('.trycloudflare.com')) {
        final urlMatch = RegExp(r'https://[a-zA-Z0-9-]+\.trycloudflare\.com')
            .firstMatch(line);
        if (urlMatch != null) {
          _processEvent(QuickTunnelEvent(url: urlMatch.group(0)!));
          return;
        }
      }
    }

    final event = CloudflaredLogParser.parseLine(line);
    if (event == null) {
      // Handle non-JSON logs or noise
      if (line.isNotEmpty) {
        _logger.d('Cloudflared log: $line',
            context: const LogContext(component: 'TunnelService'));
      }
      return;
    }

    _processEvent(event);
  }

  void _processEvent(CloudflaredEvent event) {
    switch (event) {
      case RegisteredEvent():
        state = state.copyWith(
          tunnelId: event.id,
        );
        _logger.i('Tunnel registered: ${event.id}',
            context: const LogContext(component: 'TunnelService'));
      case QuickTunnelEvent():
        state = state.copyWith(
          publicUrl: event.url,
          status: TunnelStatus
              .connected, // Quick tunnels are connected when URL is issued
        );
        _logger.i('Quick tunnel created: ${event.url}',
            context: const LogContext(component: 'TunnelService'));
      case ConnectedEvent():
        final newConnections = List<String>.from(state.connections)
          ..add(event.id);
        state = state.copyWith(
          status: TunnelStatus.connected,
          connections: newConnections,
        );
        _logger.i('Connector connected: ${event.id} at ${event.location}',
            context: const LogContext(component: 'TunnelService'));
      case DisconnectedEvent():
        final newConnections = List<String>.from(state.connections)
          ..remove(event.id);
        final newStatus = (newConnections.isEmpty && state.publicUrl == null)
            ? TunnelStatus.reconnecting
            : state.status;
        state = state.copyWith(
          status: newStatus,
          connections: newConnections,
        );
        _logger.w(
            'Connector disconnected: ${event.id}, reason: ${event.reason}',
            context: const LogContext(component: 'TunnelService'));
      case ErrorEvent():
        state = state.copyWith(
          status: TunnelStatus.error,
          error: event.message,
        );
        _logger.e('Cloudflared error: ${event.message}',
            context: const LogContext(component: 'TunnelService'));
      case LogEvent():
        // Optional: process other specific log messages if needed
        break;
    }
  }

  void _cleanup() {
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;
    _process = null;
  }

  Future<void> disconnect() async {
    _process?.kill();
    _cleanup();
    state = TunnelState.initial();
    _logger.i('Tunnel disconnected',
        context: const LogContext(component: 'TunnelService'));
  }
}

final tunnelServiceProvider =
    NotifierProvider<TunnelNotifier, TunnelState>(TunnelNotifier.new);
