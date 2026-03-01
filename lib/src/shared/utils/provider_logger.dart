import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

final class ProviderLogger extends ProviderObserver {
  const ProviderLogger();

  @override
  void didAddProvider(
    ProviderObserverContext context,
    Object? value,
  ) {
    developer.log('Provider+: ${context.provider}');
  }

  @override
  void didDisposeProvider(
    ProviderObserverContext context,
  ) {
    developer.log('Provider-: ${context.provider}');
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    developer.log(
        'Provider*: ${context.provider} (old: $previousValue, new: $newValue)');
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    developer.log('Provider!: ${context.provider}',
        error: error, stackTrace: stackTrace);
  }
}
