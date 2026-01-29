import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

final class ProviderLogger extends ProviderObserver {
  const ProviderLogger();

  @override
  void didAddProvider(
    ProviderBase provider,
    Object? value,
    ProviderContainer container,
  ) {
    developer.log('Provider+: $provider');
  }

  @override
  void didDisposeProvider(
    ProviderBase provider,
    ProviderContainer container,
  ) {
    developer.log('Provider-: $provider');
  }

  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    developer.log('Provider*: $provider (old: $previousValue, new: $newValue)');
  }

  @override
  void providerDidFail(
    ProviderBase provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    developer.log('Provider!: $provider',
        error: error, stackTrace: stackTrace);
  }

  @override
  void mutationStart(
    ProviderObserverMutationContext context,
  ) {
    developer.log('Mutation start: ${context.provider}');
  }

  @override
  void mutationSuccess(
    ProviderObserverMutationContext context,
  ) {
    developer.log('Mutation success: ${context.provider}');
  }

  @override
  void mutationError(
    ProviderObserverMutationContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    developer.log('Mutation error: ${context.provider}',
        error: error, stackTrace: stackTrace);
  }

  @override
  void mutationReset(
    ProviderObserverMutationContext context,
  ) {
    developer.log('Mutation reset: ${context.provider}');
  }
}
