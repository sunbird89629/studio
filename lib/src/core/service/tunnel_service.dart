import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/utils/ai_logger.dart';
import 'package:terminal_studio/src/util/lark_utils.dart';

class TunnelState {
  final bool isConnected;
  final String? publicUrl;
  final String? status;

  TunnelState({
    required this.isConnected,
    this.publicUrl,
    this.status,
  });

  factory TunnelState.initial() {
    return TunnelState(isConnected: false, status: 'Stopped');
  }

  TunnelState copyWith({
    bool? isConnected,
    String? publicUrl,
    String? status,
  }) {
    return TunnelState(
      isConnected: isConnected ?? this.isConnected,
      publicUrl: publicUrl ?? this.publicUrl,
      status: status ?? this.status,
    );
  }
}

class TunnelNotifier extends Notifier<TunnelState> {
  final _logger = AILogger();
  Process? _sshProcess;
  StreamSubscription? _stdoutSub;
  StreamSubscription? _stderrSub;

  @override
  TunnelState build() {
    return TunnelState.initial();
  }

  /// In a real scenario, this would connect to a service like frp, ngrok, or a custom relay.
  /// For now, we will simulate a tunnel connection or provide a placeholder for the user to integrate.
  Future<void> connect(int localPort, String password) async {
    if (_sshProcess != null) await disconnect();

    state = state.copyWith(status: 'Initializing SSH...', isConnected: false);

    _logger.i(
      'Starting real intranet penetration for port $localPort via localhost.run',
      context: const LogContext(component: 'TunnelService'),
    );

    try {
      // Command: ssh -R 80:localhost:PORT nokey@localhost.run
      // We use Process.start to handle the persistent connection.
      _sshProcess = await Process.start(
        'ssh',
        ['-R', '80:localhost:$localPort', 'nokey@localhost.run'],
        runInShell: true,
      );

      bool urlFound = false;

      // Listen to stdout to find the URL
      _stdoutSub = _sshProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        _logger.d(
          'SSH STDOUT: $line',
          context: const LogContext(component: 'TunnelService'),
        );
        // localhost.run typically outputs: "tunneled with https://[id].lhr.life"
        if (line.contains('https://')) {
          final urlMatch =
              RegExp(r'https://[a-fA-F0-9]+\.lhr\.life').firstMatch(line);
          if (urlMatch != null) {
            final publicUrl = urlMatch.group(0);
            final linkWithToken = "$publicUrl?token=$password";
            LarkUtils.sendMessage(linkWithToken);
            state = state.copyWith(
              isConnected: true,
              publicUrl: linkWithToken,
              status: 'Connected',
            );
            urlFound = true;
            _logger.i(
              'Real tunnel established: $publicUrl',
              context: const LogContext(component: 'TunnelService'),
            );
          }
        }
      });

      // Listen to stderr for errors (like SSH key warnings)
      _stderrSub = _sshProcess!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        _logger.w('SSH STDERR: $line',
            context: const LogContext(component: 'TunnelService'));
        if (line.contains('Permission denied') || line.contains('failed')) {
          state = state.copyWith(status: 'SSH Error: $line');
        }
      });

      // Wait a few seconds to see if it connects, or handle exit
      _sshProcess!.exitCode.then((code) {
        if (!urlFound) {
          state = state.copyWith(
              status: 'SSH exited with code $code', isConnected: false);
          _logger.e('SSH process exited prematurely with code $code',
              context: const LogContext(component: 'TunnelService'));
        }
        _cleanup();
      });

      // Timeout if nothing found in 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        if (!state.isConnected && state.status == 'Initializing SSH...') {
          state = state.copyWith(status: 'Connection timeout');
          disconnect();
        }
      });
    } catch (e) {
      state =
          state.copyWith(status: 'Error launching SSH: $e', isConnected: false);
      _logger.e('Tunnel startup failed: $e',
          context: const LogContext(component: 'TunnelService'));
      _cleanup();
    }
  }

  void _cleanup() {
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;
    _sshProcess = null;
  }

  Future<void> disconnect() async {
    _sshProcess?.kill();
    _cleanup();
    state = TunnelState.initial();
    _logger.i('Tunnel disconnected and process killed',
        context: const LogContext(component: 'TunnelService'));
  }
}

final tunnelServiceProvider =
    NotifierProvider<TunnelNotifier, TunnelState>(TunnelNotifier.new);
