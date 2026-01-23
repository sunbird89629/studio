import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProviderLogger implements ProviderObserver {
  const ProviderLogger();

  @override
  void didAddProvider(
    ProviderBase provider,
    Object? value,
    ProviderContainer container,
  ) {
    developer.log('Provider+: ${provider.describe}');
  }

  @override
  void didDisposeProvider(
    ProviderBase provider,
    ProviderContainer container,
  ) {
    developer.log('Provider-: ${provider.describe}');
  }

  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    developer.log('Provider*: ${provider.describe}');
  }

  @override
  void providerDidFail(
    ProviderBase provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    developer.log('Provider!: ${provider.describe}',
        error: error, stackTrace: stackTrace);
  }
}

extension _ProviderName on ProviderBase {
  String get describe => name ?? toString();
}
