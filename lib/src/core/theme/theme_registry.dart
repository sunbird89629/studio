import 'package:flutter/foundation.dart';
import 'package:terminal_studio/src/core/theme/theme_plugin.dart';

/// Registry for managing theme plugins.
///
/// Themes can be registered and unregistered dynamically. The registry
/// notifies listeners when the theme list changes.
class ThemeRegistry with ChangeNotifier {
  final Map<String, ThemePlugin> _themes = {};

  /// All registered themes.
  List<ThemePlugin> get all => List.unmodifiable(_themes.values.toList());

  /// Get a theme by its ID. Returns null if not found.
  ThemePlugin? get(String id) => _themes[id];

  /// Register a theme plugin.
  ///
  /// Throws if a theme with the same ID is already registered.
  void register(ThemePlugin theme) {
    if (_themes.containsKey(theme.id)) {
      throw ArgumentError('Theme with id "${theme.id}" is already registered');
    }
    _themes[theme.id] = theme;
    notifyListeners();
  }

  /// Register multiple themes at once.
  void registerAll(Iterable<ThemePlugin> themes) {
    for (final theme in themes) {
      if (_themes.containsKey(theme.id)) {
        throw ArgumentError(
            'Theme with id "${theme.id}" is already registered');
      }
      _themes[theme.id] = theme;
    }
    notifyListeners();
  }

  /// Unregister a theme by its ID.
  ///
  /// Returns true if the theme was removed, false if it wasn't registered.
  bool unregister(String id) {
    final removed = _themes.remove(id) != null;
    if (removed) {
      notifyListeners();
    }
    return removed;
  }

  /// Check if a theme with the given ID is registered.
  bool contains(String id) => _themes.containsKey(id);
}
