/// Detects URLs and file paths in terminal text.
///
/// Used by the terminal plugin to resolve what was clicked
/// when the user Cmd+Clicks (macOS) or Ctrl+Clicks (Win/Linux).
class LinkDetector {
  LinkDetector._();

  static final _urlPattern = RegExp(
    r'https?://[^\s<>"{}|\\^\[\]`]+',
    caseSensitive: false,
  );

  // Matches absolute paths (/foo/bar) or home-relative paths (~/foo/bar).
  // Optionally followed by :line or :line:col (e.g. from compiler output).
  static final _filePattern = RegExp(
    r'(?:^|(?<=\s))(~?/[\w./\-_@+%:]+)',
  );

  /// Returns the URL or file path at [column] within [line], or null.
  static String? detectAt(String line, int column) {
    for (final pattern in [_urlPattern, _filePattern]) {
      for (final match in pattern.allMatches(line)) {
        if (column >= match.start && column < match.end) {
          // Strip trailing punctuation that is unlikely part of the URL/path.
          var result = match.group(0)!;
          if (result.endsWith('.') ||
              result.endsWith(',') ||
              result.endsWith(')') ||
              result.endsWith(']')) {
            result = result.substring(0, result.length - 1);
          }
          return result.isEmpty ? null : result;
        }
      }
    }
    return null;
  }
}
