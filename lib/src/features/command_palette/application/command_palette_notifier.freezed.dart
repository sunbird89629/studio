// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'command_palette_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommandPaletteState {
  bool get isVisible;
  String get query;
  List<Command> get filteredCommands;
  int get selectedIndex;

  /// Create a copy of CommandPaletteState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CommandPaletteStateCopyWith<CommandPaletteState> get copyWith =>
      _$CommandPaletteStateCopyWithImpl<CommandPaletteState>(
          this as CommandPaletteState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CommandPaletteState &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality()
                .equals(other.filteredCommands, filteredCommands) &&
            (identical(other.selectedIndex, selectedIndex) ||
                other.selectedIndex == selectedIndex));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isVisible, query,
      const DeepCollectionEquality().hash(filteredCommands), selectedIndex);

  @override
  String toString() {
    return 'CommandPaletteState(isVisible: $isVisible, query: $query, filteredCommands: $filteredCommands, selectedIndex: $selectedIndex)';
  }
}

/// @nodoc
abstract mixin class $CommandPaletteStateCopyWith<$Res> {
  factory $CommandPaletteStateCopyWith(
          CommandPaletteState value, $Res Function(CommandPaletteState) _then) =
      _$CommandPaletteStateCopyWithImpl;
  @useResult
  $Res call(
      {bool isVisible,
      String query,
      List<Command> filteredCommands,
      int selectedIndex});
}

/// @nodoc
class _$CommandPaletteStateCopyWithImpl<$Res>
    implements $CommandPaletteStateCopyWith<$Res> {
  _$CommandPaletteStateCopyWithImpl(this._self, this._then);

  final CommandPaletteState _self;
  final $Res Function(CommandPaletteState) _then;

  /// Create a copy of CommandPaletteState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isVisible = null,
    Object? query = null,
    Object? filteredCommands = null,
    Object? selectedIndex = null,
  }) {
    return _then(_self.copyWith(
      isVisible: null == isVisible
          ? _self.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      query: null == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      filteredCommands: null == filteredCommands
          ? _self.filteredCommands
          : filteredCommands // ignore: cast_nullable_to_non_nullable
              as List<Command>,
      selectedIndex: null == selectedIndex
          ? _self.selectedIndex
          : selectedIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [CommandPaletteState].
extension CommandPaletteStatePatterns on CommandPaletteState {
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
    TResult Function(_CommandPaletteState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CommandPaletteState() when $default != null:
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
    TResult Function(_CommandPaletteState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CommandPaletteState():
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
    TResult? Function(_CommandPaletteState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CommandPaletteState() when $default != null:
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
    TResult Function(bool isVisible, String query,
            List<Command> filteredCommands, int selectedIndex)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CommandPaletteState() when $default != null:
        return $default(_that.isVisible, _that.query, _that.filteredCommands,
            _that.selectedIndex);
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
    TResult Function(bool isVisible, String query,
            List<Command> filteredCommands, int selectedIndex)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CommandPaletteState():
        return $default(_that.isVisible, _that.query, _that.filteredCommands,
            _that.selectedIndex);
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
    TResult? Function(bool isVisible, String query,
            List<Command> filteredCommands, int selectedIndex)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CommandPaletteState() when $default != null:
        return $default(_that.isVisible, _that.query, _that.filteredCommands,
            _that.selectedIndex);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _CommandPaletteState extends CommandPaletteState {
  const _CommandPaletteState(
      {this.isVisible = false,
      this.query = '',
      final List<Command> filteredCommands = const [],
      this.selectedIndex = 0})
      : _filteredCommands = filteredCommands,
        super._();

  @override
  @JsonKey()
  final bool isVisible;
  @override
  @JsonKey()
  final String query;
  final List<Command> _filteredCommands;
  @override
  @JsonKey()
  List<Command> get filteredCommands {
    if (_filteredCommands is EqualUnmodifiableListView)
      return _filteredCommands;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_filteredCommands);
  }

  @override
  @JsonKey()
  final int selectedIndex;

  /// Create a copy of CommandPaletteState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CommandPaletteStateCopyWith<_CommandPaletteState> get copyWith =>
      __$CommandPaletteStateCopyWithImpl<_CommandPaletteState>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CommandPaletteState &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality()
                .equals(other._filteredCommands, _filteredCommands) &&
            (identical(other.selectedIndex, selectedIndex) ||
                other.selectedIndex == selectedIndex));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isVisible, query,
      const DeepCollectionEquality().hash(_filteredCommands), selectedIndex);

  @override
  String toString() {
    return 'CommandPaletteState(isVisible: $isVisible, query: $query, filteredCommands: $filteredCommands, selectedIndex: $selectedIndex)';
  }
}

/// @nodoc
abstract mixin class _$CommandPaletteStateCopyWith<$Res>
    implements $CommandPaletteStateCopyWith<$Res> {
  factory _$CommandPaletteStateCopyWith(_CommandPaletteState value,
          $Res Function(_CommandPaletteState) _then) =
      __$CommandPaletteStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool isVisible,
      String query,
      List<Command> filteredCommands,
      int selectedIndex});
}

/// @nodoc
class __$CommandPaletteStateCopyWithImpl<$Res>
    implements _$CommandPaletteStateCopyWith<$Res> {
  __$CommandPaletteStateCopyWithImpl(this._self, this._then);

  final _CommandPaletteState _self;
  final $Res Function(_CommandPaletteState) _then;

  /// Create a copy of CommandPaletteState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? isVisible = null,
    Object? query = null,
    Object? filteredCommands = null,
    Object? selectedIndex = null,
  }) {
    return _then(_CommandPaletteState(
      isVisible: null == isVisible
          ? _self.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      query: null == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      filteredCommands: null == filteredCommands
          ? _self._filteredCommands
          : filteredCommands // ignore: cast_nullable_to_non_nullable
              as List<Command>,
      selectedIndex: null == selectedIndex
          ? _self.selectedIndex
          : selectedIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
