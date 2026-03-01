import 'package:uuid/uuid.dart';

class ProfileRecord {
  /// Unique identifier.
  String id;

  /// Human-readable name, e.g. "Work", "Personal".
  String name;

  // ── Overridable fields (null = inherit from global settings) ──

  String? shell;

  List<String>? shellArgs;

  String? themeId;

  double? fontSize;

  String? fontFamily;

  Map<String, String>? env;

  String? workingDirectory;

  String? cursorShape;

  bool? cursorBlink;

  double? lineHeight;

  double? letterSpacing;

  double? backgroundOpacity;

  double? padding;

  ProfileRecord({
    String? id,
    this.name = 'Default',
    this.shell,
    this.shellArgs,
    this.themeId,
    this.fontSize,
    this.fontFamily,
    this.env,
    this.workingDirectory,
    this.cursorShape,
    this.cursorBlink,
    this.lineHeight,
    this.letterSpacing,
    this.backgroundOpacity,
    this.padding,
  }) : id = id ?? const Uuid().v4();

  /// Create a copy of this profile with a new ID and name.
  ProfileRecord duplicate({String? newName}) {
    return ProfileRecord(
      name: newName ?? '$name (Copy)',
      shell: shell,
      shellArgs: shellArgs != null ? List<String>.from(shellArgs!) : null,
      themeId: themeId,
      fontSize: fontSize,
      fontFamily: fontFamily,
      env: env != null ? Map<String, String>.from(env!) : null,
      workingDirectory: workingDirectory,
      cursorShape: cursorShape,
      cursorBlink: cursorBlink,
      lineHeight: lineHeight,
      letterSpacing: letterSpacing,
      backgroundOpacity: backgroundOpacity,
      padding: padding,
    );
  }

  /// Convert to a JSON-serializable map (for JSONC export).
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'name': name};
    if (shell != null) map['shell'] = shell;
    if (shellArgs != null) map['shell_args'] = shellArgs;
    if (themeId != null) map['theme'] = themeId;
    if (fontSize != null) map['font_size'] = fontSize;
    if (fontFamily != null) map['font_family'] = fontFamily;
    if (env != null && env!.isNotEmpty) map['env'] = env;
    if (workingDirectory != null) map['working_directory'] = workingDirectory;
    if (cursorShape != null) map['cursor_shape'] = cursorShape;
    if (cursorBlink != null) map['cursor_blink'] = cursorBlink;
    if (lineHeight != null) map['line_height'] = lineHeight;
    if (letterSpacing != null) map['letter_spacing'] = letterSpacing;
    if (backgroundOpacity != null) {
      map['background_opacity'] = backgroundOpacity;
    }
    if (padding != null) map['padding'] = padding;
    return map;
  }

  /// Create from a JSON map (for JSONC import).
  factory ProfileRecord.fromJson(String id, Map<String, dynamic> json) {
    return ProfileRecord(
      id: id,
      name: json['name'] as String? ?? id,
      shell: json['shell'] as String?,
      shellArgs: (json['shell_args'] as List?)?.cast<String>(),
      themeId: json['theme'] as String?,
      fontSize: (json['font_size'] as num?)?.toDouble(),
      fontFamily: json['font_family'] as String?,
      env: (json['env'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v.toString())),
      workingDirectory: json['working_directory'] as String?,
      cursorShape: json['cursor_shape'] as String?,
      cursorBlink: json['cursor_blink'] as bool?,
      lineHeight: (json['line_height'] as num?)?.toDouble(),
      letterSpacing: (json['letter_spacing'] as num?)?.toDouble(),
      backgroundOpacity: (json['background_opacity'] as num?)?.toDouble(),
      padding: (json['padding'] as num?)?.toDouble(),
    );
  }
}
