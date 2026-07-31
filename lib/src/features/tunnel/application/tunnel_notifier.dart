import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_term/src/shared/constants/log_channels.dart';
import 'package:open_term/src/shared/models/cloudflared_event.dart';
import 'package:open_term/src/shared/logging/log_service.dart';
import 'package:open_term/src/shared/utils/cloudflared_log_parser.dart';

part 'tunnel_notifier.freezed.dart';

enum TunnelStatus {
  stopped,
  starting,
  connected,
  error,
  reconnecting,
}

class ExecCommand {
  final String executable;
  final List<String> args;
  ExecCommand({
    required this.executable,
    required this.args,
  });
}

@freezed
abstract class TunnelState with _$TunnelState {
  const TunnelState._();

  const factory TunnelState({
    @Default(TunnelStatus.stopped) TunnelStatus status,
    String? publicUrl,
    String? error,
    String? tunnelId,
    @Default([]) List<String> connections,
  }) = _TunnelState;

  bool get isConnected => status == TunnelStatus.connected;
}

class TunnelNotifier extends Notifier<TunnelState> {
  static const _channel = LogChannels.tunnel;
  Process? _process;
  StreamSubscription? _stdoutSub;
  StreamSubscription? _stderrSub;

  /// Homebrew PATH for GUI apps that don't inherit shell PATH
  Map<String, String> get _processEnvironment => {
        'PATH':
            '/opt/homebrew/bin:/usr/local/bin:${Platform.environment['PATH'] ?? ''}',
      };

  @override
  TunnelState build() {
    return const TunnelState();
  }

  ExecCommand get tunnelCommand {
    // cloudflared tunnel --url http://localhost:8080
    if (Platform.isMacOS) {
      return ExecCommand(executable: 'caffeinate', args: [
        '-i',
        'cloudflared',
        'tunnel',
        '--url',
        'http://localhost:8080',
        '--no-autoupdate',
        '--output',
        'json',
      ]);
    } else {
      return ExecCommand(
        executable: 'cloudflared',
        args: [
          'tunnel',
          '--url',
          'http://localhost:8080',
          '--no-autoupdate',
          '--output',
          'json',
        ],
      );
    }
  }

  Future<void> connect(String token, {int? localPort}) async {
    if (_process != null) await disconnect();

    state = state.copyWith(status: TunnelStatus.starting, error: null);

    LogService.instance.info(_channel, 'Starting cloudflared tunnel');

    try {
      // Command: cloudflared tunnel --no-autoupdate run --token TOKEN
      // On macOS, we wrap it with 'caffeinate -i' to prevent system sleep.
      final executable = Platform.isMacOS ? 'caffeinate' : 'cloudflared';
      final baseArgs = [
        'tunnel',
        '--no-autoupdate',
        'run',
        '--output',
        'json',
        '--token',
        token
      ];
      final args =
          Platform.isMacOS ? ['-i', 'cloudflared', ...baseArgs] : baseArgs;

      _process = await Process.start(
        executable,
        args,
        environment: _processEnvironment,
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
        LogService.instance.warning(
          _channel,
          'Cloudflared process exited with code $code',
          pid: _process?.pid,
        );
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
      LogService.instance.error(
        _channel,
        'Tunnel startup failed: $e',
      );
      _cleanup();
    }
  }

  Future<void> connectQuick(int localPort) async {
    if (_process != null) await disconnect();

    state = state.copyWith(status: TunnelStatus.starting, error: null);

    LogService.instance.info(
      _channel,
      'Starting cloudflared quick tunnel for port $localPort',
    );

    try {
      final process = await Process.start(
        tunnelCommand.executable,
        tunnelCommand.args,
        environment: _processEnvironment,
      );

      _stdoutSub = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleLog);

      _stderrSub = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleLog);

      process.exitCode.then((code) {
        LogService.instance.warning(
          _channel,
          'Cloudflared quick tunnel process exited with code $code',
        );
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
      LogService.instance.error(_channel, 'Tunnel startup failed: $e');
      _cleanup();
    }
  }

  void _handleLog(String line) {
    LogService.instance.debug(_channel, 'Cloudflared log: $line');
    final event = CloudflaredLogParser.parseLine(line);
    if (event != null) {
      _processEvent(event);
    }
  }

  void _processEvent(CloudflaredEvent event) {
    switch (event) {
      case RegisteredEvent():
        state = state.copyWith(
          tunnelId: event.id,
        );
        LogService.instance.info(
          _channel,
          'Tunnel registered: ${event.id}',
          meta: {'tunnelId': event.id},
        );
      case QuickTunnelEvent():
        state = state.copyWith(
          publicUrl: event.url,
          status: TunnelStatus
              .connected, // Quick tunnels are connected when URL is issued
        );
        LogService.instance.info(
          _channel,
          'Quick tunnel created: ${event.url}',
          meta: {'url': event.url},
        );
      case ConnectedEvent():
        final newConnections = List<String>.from(state.connections)
          ..add(event.id);
        state = state.copyWith(
          status: TunnelStatus.connected,
          connections: newConnections,
        );
        LogService.instance.info(
          _channel,
          'Connector connected: ${event.id} at ${event.location}',
          meta: {'connectionId': event.id, 'location': event.location},
        );
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
        LogService.instance.warning(
          _channel,
          'Connector disconnected: ${event.id}, reason: ${event.reason}',
          meta: {'connectionId': event.id, 'reason': event.reason},
        );
      case ErrorEvent():
        state = state.copyWith(
          status: TunnelStatus.error,
          error: event.message,
        );
        LogService.instance.error(
          _channel,
          'Cloudflared error: ${event.message}',
        );
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
    state = const TunnelState();
    LogService.instance.info(_channel, 'Tunnel disconnected');
  }
}

final tunnelServiceProvider =
    NotifierProvider<TunnelNotifier, TunnelState>(TunnelNotifier.new);
