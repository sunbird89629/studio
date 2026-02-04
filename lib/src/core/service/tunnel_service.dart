import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/utils/ai_logger.dart';

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

  @override
  TunnelState build() {
    return TunnelState.initial();
  }

  /// In a real scenario, this would connect to a service like frp, ngrok, or a custom relay.
  /// For now, we will simulate a tunnel connection or provide a placeholder for the user to integrate.
  Future<void> connect(int localPort) async {
    state = state.copyWith(status: 'Connecting...', isConnected: false);

    _logger.i('Starting intranet penetration for port $localPort',
        context: const LogContext(component: 'TunnelService'));

    try {
      // Simulate tunnel negotiation
      await Future.delayed(const Duration(seconds: 2));

      // Placeholder: In a real implementation, we might execute a binary or use a library.
      // E.g., shell.execute('ssh -R 80:localhost:$localPort nokey@localhost.run')

      final publicUrl =
          'https://term-studio-${DateTime.now().millisecond}.locality.io';

      state = state.copyWith(
        isConnected: true,
        publicUrl: publicUrl,
        status: 'Connected',
      );

      _logger.i('Tunnel established: $publicUrl',
          context: const LogContext(component: 'TunnelService'));
    } catch (e) {
      state = state.copyWith(status: 'Error: $e', isConnected: false);
      _logger.e('Tunnel connection failed: $e',
          context: const LogContext(component: 'TunnelService'));
    }
  }

  Future<void> disconnect() async {
    state = TunnelState.initial();
    _logger.i('Tunnel disconnected',
        context: const LogContext(component: 'TunnelService'));
  }
}

final tunnelServiceProvider =
    NotifierProvider<TunnelNotifier, TunnelState>(TunnelNotifier.new);
