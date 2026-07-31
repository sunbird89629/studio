import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_term/src/platform/plugins/plugin_runtime.dart';

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
  void onMounted() {
    title.value = 'Uptime';
    super.onMounted();
  }

  @override
  void onConnected() {
    _startPolling();
    super.onConnected();
  }

  @override
  void onDisconnected() {
    _timer?.cancel();
    _timer = null;
    _uptime.value = 'Disconnected';
    super.onDisconnected();
  }

  @override
  void onUnmounted() {
    _timer?.cancel();
    _timer = null;
    super.onUnmounted();
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
