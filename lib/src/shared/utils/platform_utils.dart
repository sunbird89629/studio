import 'dart:io' as io;

/// Returns the current user's home directory, or `null` if not determinable.
String? platformHomeDirectory() => io.Platform.isWindows
    ? io.Platform.environment['USERPROFILE']
    : io.Platform.environment['HOME'];
