// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tunnel_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TunnelState {
  TunnelStatus get status;
  String? get publicUrl;
  String? get error;
  String? get tunnelId;
  List<String> get connections;

  /// Create a copy of TunnelState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TunnelStateCopyWith<TunnelState> get copyWith =>
      _$TunnelStateCopyWithImpl<TunnelState>(this as TunnelState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TunnelState &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.publicUrl, publicUrl) ||
                other.publicUrl == publicUrl) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.tunnelId, tunnelId) ||
                other.tunnelId == tunnelId) &&
            const DeepCollectionEquality()
                .equals(other.connections, connections));
  }

  @override
  int get hashCode => Object.hash(runtimeType, status, publicUrl, error,
      tunnelId, const DeepCollectionEquality().hash(connections));

  @override
  String toString() {
    return 'TunnelState(status: $status, publicUrl: $publicUrl, error: $error, tunnelId: $tunnelId, connections: $connections)';
  }
}

/// @nodoc
abstract mixin class $TunnelStateCopyWith<$Res> {
  factory $TunnelStateCopyWith(
          TunnelState value, $Res Function(TunnelState) _then) =
      _$TunnelStateCopyWithImpl;
  @useResult
  $Res call(
      {TunnelStatus status,
      String? publicUrl,
      String? error,
      String? tunnelId,
      List<String> connections});
}

/// @nodoc
class _$TunnelStateCopyWithImpl<$Res> implements $TunnelStateCopyWith<$Res> {
  _$TunnelStateCopyWithImpl(this._self, this._then);

  final TunnelState _self;
  final $Res Function(TunnelState) _then;

  /// Create a copy of TunnelState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? publicUrl = freezed,
    Object? error = freezed,
    Object? tunnelId = freezed,
    Object? connections = null,
  }) {
    return _then(_self.copyWith(
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as TunnelStatus,
      publicUrl: freezed == publicUrl
          ? _self.publicUrl
          : publicUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      tunnelId: freezed == tunnelId
          ? _self.tunnelId
          : tunnelId // ignore: cast_nullable_to_non_nullable
              as String?,
      connections: null == connections
          ? _self.connections
          : connections // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// Adds pattern-matching-related methods to [TunnelState].
extension TunnelStatePatterns on TunnelState {
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
    TResult Function(_TunnelState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TunnelState() when $default != null:
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
    TResult Function(_TunnelState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TunnelState():
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
    TResult? Function(_TunnelState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TunnelState() when $default != null:
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
    TResult Function(TunnelStatus status, String? publicUrl, String? error,
            String? tunnelId, List<String> connections)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TunnelState() when $default != null:
        return $default(_that.status, _that.publicUrl, _that.error,
            _that.tunnelId, _that.connections);
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
    TResult Function(TunnelStatus status, String? publicUrl, String? error,
            String? tunnelId, List<String> connections)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TunnelState():
        return $default(_that.status, _that.publicUrl, _that.error,
            _that.tunnelId, _that.connections);
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
    TResult? Function(TunnelStatus status, String? publicUrl, String? error,
            String? tunnelId, List<String> connections)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TunnelState() when $default != null:
        return $default(_that.status, _that.publicUrl, _that.error,
            _that.tunnelId, _that.connections);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TunnelState extends TunnelState {
  const _TunnelState(
      {this.status = TunnelStatus.stopped,
      this.publicUrl,
      this.error,
      this.tunnelId,
      final List<String> connections = const []})
      : _connections = connections,
        super._();

  @override
  @JsonKey()
  final TunnelStatus status;
  @override
  final String? publicUrl;
  @override
  final String? error;
  @override
  final String? tunnelId;
  final List<String> _connections;
  @override
  @JsonKey()
  List<String> get connections {
    if (_connections is EqualUnmodifiableListView) return _connections;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_connections);
  }

  /// Create a copy of TunnelState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TunnelStateCopyWith<_TunnelState> get copyWith =>
      __$TunnelStateCopyWithImpl<_TunnelState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TunnelState &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.publicUrl, publicUrl) ||
                other.publicUrl == publicUrl) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.tunnelId, tunnelId) ||
                other.tunnelId == tunnelId) &&
            const DeepCollectionEquality()
                .equals(other._connections, _connections));
  }

  @override
  int get hashCode => Object.hash(runtimeType, status, publicUrl, error,
      tunnelId, const DeepCollectionEquality().hash(_connections));

  @override
  String toString() {
    return 'TunnelState(status: $status, publicUrl: $publicUrl, error: $error, tunnelId: $tunnelId, connections: $connections)';
  }
}

/// @nodoc
abstract mixin class _$TunnelStateCopyWith<$Res>
    implements $TunnelStateCopyWith<$Res> {
  factory _$TunnelStateCopyWith(
          _TunnelState value, $Res Function(_TunnelState) _then) =
      __$TunnelStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {TunnelStatus status,
      String? publicUrl,
      String? error,
      String? tunnelId,
      List<String> connections});
}

/// @nodoc
class __$TunnelStateCopyWithImpl<$Res> implements _$TunnelStateCopyWith<$Res> {
  __$TunnelStateCopyWithImpl(this._self, this._then);

  final _TunnelState _self;
  final $Res Function(_TunnelState) _then;

  /// Create a copy of TunnelState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? status = null,
    Object? publicUrl = freezed,
    Object? error = freezed,
    Object? tunnelId = freezed,
    Object? connections = null,
  }) {
    return _then(_TunnelState(
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as TunnelStatus,
      publicUrl: freezed == publicUrl
          ? _self.publicUrl
          : publicUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      tunnelId: freezed == tunnelId
          ? _self.tunnelId
          : tunnelId // ignore: cast_nullable_to_non_nullable
              as String?,
      connections: null == connections
          ? _self._connections
          : connections // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

// dart format on
