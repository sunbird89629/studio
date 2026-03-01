import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

/// Abstract base class for theme plugins.
///
/// Implement this class to create custom themes that can be registered
/// with the [ThemeRegistry].
///
/// Example:
/// ```dart
/// class MonokaiTheme extends ThemePlugin {
///   @override String get id => 'monokai';
///   @override String get displayName => 'Monokai Pro';
///   // ...
/// }
/// ```
abstract class ThemePlugin {
  /// Unique identifier for this theme.
  String get id;

  /// Display name shown in the UI.
  String get displayName;

  /// The brightness of this theme (light or dark).
  Brightness get brightness;

  /// Material UI theme data for the application shell.
  ThemeData get theme;

  /// Theme data for the tabs component.
  TabsViewThemeData get tabsTheme;

  /// Optional terminal theme. If null, terminal uses its own theme.
  TerminalTheme? get terminalTheme => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ThemePlugin && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
