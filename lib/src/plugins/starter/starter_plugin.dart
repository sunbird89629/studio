import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/plugin.dart';

class StarterPlugin extends Plugin {
  final _uptime = ValueNotifier<String?>(null);
  Timer? _timer;

  Future<void> _updateUptime() async {
    if (!connected) return;
    final result = await AsyncValue.guard(() => host.execute('uptime'));

    result.when(
      data: (data) => _uptime.value = data.stdout,
      loading: () => _uptime.value = 'Loading...',
      error: (error, stackTrace) => _uptime.value = 'Error: $error',
    );
  }

  void _startPolling() {
    _updateUptime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateUptime());
  }

  @override
  void didMounted() {
    title.value = 'Uptime';
    super.didMounted();
  }

  @override
  void didConnected() {
    _startPolling();
    super.didConnected();
  }

  @override
  void didDisconnected() {
    _timer?.cancel();
    _timer = null;
    _uptime.value = 'Disconnected';
    super.didDisconnected();
  }

  @override
  void didUnmounted() {
    _timer?.cancel();
    _timer = null;
    super.didUnmounted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uptime'),
        leading: const Icon(Icons.dns_outlined),
        centerTitle: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined, size: 48),
            const SizedBox(height: 16),
            ValueListenableBuilder<String?>(
              valueListenable: _uptime,
              builder: (context, value, child) {
                return Text(
                  value ?? 'Waiting...',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
