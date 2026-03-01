// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'remote_control_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RemoteControlState {
  bool get isEnabled;
  int get port;
  String? get authToken;
  String? get localUrl;
  String? get publicUrl;
  List<String> get activeClients;
  String? get cloudflaredToken;
  String? get larkWebhookUrl;

  /// Create a copy of RemoteControlState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RemoteControlStateCopyWith<RemoteControlState> get copyWith =>
      _$RemoteControlStateCopyWithImpl<RemoteControlState>(
          this as RemoteControlState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RemoteControlState &&
            (identical(other.isEnabled, isEnabled) ||
                other.isEnabled == isEnabled) &&
            (identical(other.port, port) || other.port == port) &&
            (identical(other.authToken, authToken) ||
                other.authToken == authToken) &&
            (identical(other.localUrl, localUrl) ||
                other.localUrl == localUrl) &&
            (identical(other.publicUrl, publicUrl) ||
                other.publicUrl == publicUrl) &&
            const DeepCollectionEquality()
                .equals(other.activeClients, activeClients) &&
            (identical(other.cloudflaredToken, cloudflaredToken) ||
                other.cloudflaredToken == cloudflaredToken) &&
            (identical(other.larkWebhookUrl, larkWebhookUrl) ||
                other.larkWebhookUrl == larkWebhookUrl));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isEnabled,
      port,
      authToken,
      localUrl,
      publicUrl,
      const DeepCollectionEquality().hash(activeClients),
      cloudflaredToken,
      larkWebhookUrl);

  @override
  String toString() {
    return 'RemoteControlState(isEnabled: $isEnabled, port: $port, authToken: $authToken, localUrl: $localUrl, publicUrl: $publicUrl, activeClients: $activeClients, cloudflaredToken: $cloudflaredToken, larkWebhookUrl: $larkWebhookUrl)';
  }
}

/// @nodoc
abstract mixin class $RemoteControlStateCopyWith<$Res> {
  factory $RemoteControlStateCopyWith(
          RemoteControlState value, $Res Function(RemoteControlState) _then) =
      _$RemoteControlStateCopyWithImpl;
  @useResult
  $Res call(
      {bool isEnabled,
      int port,
      String? authToken,
      String? localUrl,
      String? publicUrl,
      List<String> activeClients,
      String? cloudflaredToken,
      String? larkWebhookUrl});
}

/// @nodoc
class _$RemoteControlStateCopyWithImpl<$Res>
    implements $RemoteControlStateCopyWith<$Res> {
  _$RemoteControlStateCopyWithImpl(this._self, this._then);

  final RemoteControlState _self;
  final $Res Function(RemoteControlState) _then;

  /// Create a copy of RemoteControlState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isEnabled = null,
    Object? port = null,
    Object? authToken = freezed,
    Object? localUrl = freezed,
    Object? publicUrl = freezed,
    Object? activeClients = null,
    Object? cloudflaredToken = freezed,
    Object? larkWebhookUrl = freezed,
  }) {
    return _then(_self.copyWith(
      isEnabled: null == isEnabled
          ? _self.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      port: null == port
          ? _self.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      authToken: freezed == authToken
          ? _self.authToken
          : authToken // ignore: cast_nullable_to_non_nullable
              as String?,
      localUrl: freezed == localUrl
          ? _self.localUrl
          : localUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      publicUrl: freezed == publicUrl
          ? _self.publicUrl
          : publicUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      activeClients: null == activeClients
          ? _self.activeClients
          : activeClients // ignore: cast_nullable_to_non_nullable
              as List<String>,
      cloudflaredToken: freezed == cloudflaredToken
          ? _self.cloudflaredToken
          : cloudflaredToken // ignore: cast_nullable_to_non_nullable
              as String?,
      larkWebhookUrl: freezed == larkWebhookUrl
          ? _self.larkWebhookUrl
          : larkWebhookUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [RemoteControlState].
extension RemoteControlStatePatterns on RemoteControlState {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_RemoteControlState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RemoteControlState() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_RemoteControlState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RemoteControlState():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_RemoteControlState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RemoteControlState() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            bool isEnabled,
            int port,
            String? authToken,
            String? localUrl,
            String? publicUrl,
            List<String> activeClients,
            String? cloudflaredToken,
            String? larkWebhookUrl)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RemoteControlState() when $default != null:
        return $default(
            _that.isEnabled,
            _that.port,
            _that.authToken,
            _that.localUrl,
            _that.publicUrl,
            _that.activeClients,
            _that.cloudflaredToken,
            _that.larkWebhookUrl);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            bool isEnabled,
            int port,
            String? authToken,
            String? localUrl,
            String? publicUrl,
            List<String> activeClients,
            String? cloudflaredToken,
            String? larkWebhookUrl)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RemoteControlState():
        return $default(
            _that.isEnabled,
            _that.port,
            _that.authToken,
            _that.localUrl,
            _that.publicUrl,
            _that.activeClients,
            _that.cloudflaredToken,
            _that.larkWebhookUrl);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            bool isEnabled,
            int port,
            String? authToken,
            String? localUrl,
            String? publicUrl,
            List<String> activeClients,
            String? cloudflaredToken,
            String? larkWebhookUrl)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RemoteControlState() when $default != null:
        return $default(
            _that.isEnabled,
            _that.port,
            _that.authToken,
            _that.localUrl,
            _that.publicUrl,
            _that.activeClients,
            _that.cloudflaredToken,
            _that.larkWebhookUrl);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _RemoteControlState implements RemoteControlState {
  const _RemoteControlState(
      {this.isEnabled = false,
      this.port = 8080,
      this.authToken,
      this.localUrl,
      this.publicUrl,
      final List<String> activeClients = const [],
      this.cloudflaredToken,
      this.larkWebhookUrl})
      : _activeClients = activeClients;

  @override
  @JsonKey()
  final bool isEnabled;
  @override
  @JsonKey()
  final int port;
  @override
  final String? authToken;
  @override
  final String? localUrl;
  @override
  final String? publicUrl;
  final List<String> _activeClients;
  @override
  @JsonKey()
  List<String> get activeClients {
    if (_activeClients is EqualUnmodifiableListView) return _activeClients;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_activeClients);
  }

  @override
  final String? cloudflaredToken;
  @override
  final String? larkWebhookUrl;

  /// Create a copy of RemoteControlState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RemoteControlStateCopyWith<_RemoteControlState> get copyWith =>
      __$RemoteControlStateCopyWithImpl<_RemoteControlState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RemoteControlState &&
            (identical(other.isEnabled, isEnabled) ||
                other.isEnabled == isEnabled) &&
            (identical(other.port, port) || other.port == port) &&
            (identical(other.authToken, authToken) ||
                other.authToken == authToken) &&
            (identical(other.localUrl, localUrl) ||
                other.localUrl == localUrl) &&
            (identical(other.publicUrl, publicUrl) ||
                other.publicUrl == publicUrl) &&
            const DeepCollectionEquality()
                .equals(other._activeClients, _activeClients) &&
            (identical(other.cloudflaredToken, cloudflaredToken) ||
                other.cloudflaredToken == cloudflaredToken) &&
            (identical(other.larkWebhookUrl, larkWebhookUrl) ||
                other.larkWebhookUrl == larkWebhookUrl));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isEnabled,
      port,
      authToken,
      localUrl,
      publicUrl,
      const DeepCollectionEquality().hash(_activeClients),
      cloudflaredToken,
      larkWebhookUrl);

  @override
  String toString() {
    return 'RemoteControlState(isEnabled: $isEnabled, port: $port, authToken: $authToken, localUrl: $localUrl, publicUrl: $publicUrl, activeClients: $activeClients, cloudflaredToken: $cloudflaredToken, larkWebhookUrl: $larkWebhookUrl)';
  }
}

/// @nodoc
abstract mixin class _$RemoteControlStateCopyWith<$Res>
    implements $RemoteControlStateCopyWith<$Res> {
  factory _$RemoteControlStateCopyWith(
          _RemoteControlState value, $Res Function(_RemoteControlState) _then) =
      __$RemoteControlStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool isEnabled,
      int port,
      String? authToken,
      String? localUrl,
      String? publicUrl,
      List<String> activeClients,
      String? cloudflaredToken,
      String? larkWebhookUrl});
}

/// @nodoc
class __$RemoteControlStateCopyWithImpl<$Res>
    implements _$RemoteControlStateCopyWith<$Res> {
  __$RemoteControlStateCopyWithImpl(this._self, this._then);

  final _RemoteControlState _self;
  final $Res Function(_RemoteControlState) _then;

  /// Create a copy of RemoteControlState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? isEnabled = null,
    Object? port = null,
    Object? authToken = freezed,
    Object? localUrl = freezed,
    Object? publicUrl = freezed,
    Object? activeClients = null,
    Object? cloudflaredToken = freezed,
    Object? larkWebhookUrl = freezed,
  }) {
    return _then(_RemoteControlState(
      isEnabled: null == isEnabled
          ? _self.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      port: null == port
          ? _self.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      authToken: freezed == authToken
          ? _self.authToken
          : authToken // ignore: cast_nullable_to_non_nullable
              as String?,
      localUrl: freezed == localUrl
          ? _self.localUrl
          : localUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      publicUrl: freezed == publicUrl
          ? _self.publicUrl
          : publicUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      activeClients: null == activeClients
          ? _self._activeClients
          : activeClients // ignore: cast_nullable_to_non_nullable
              as List<String>,
      cloudflaredToken: freezed == cloudflaredToken
          ? _self.cloudflaredToken
          : cloudflaredToken // ignore: cast_nullable_to_non_nullable
              as String?,
      larkWebhookUrl: freezed == larkWebhookUrl
          ? _self.larkWebhookUrl
          : larkWebhookUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
