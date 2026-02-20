import 'package:hive_ce_flutter/hive_flutter.dart';

part 'settings_record.g.dart';

@HiveType(typeId: 2)
class SettingsRecord extends HiveObject {
  @HiveField(0)
  double terminalFontSize;

  @HiveField(1)
  String? terminalFontFamily;

  @HiveField(2)
  bool? disableUnderline;

  /// The selected theme ID. Defaults to 'dark'.
  @HiveField(3)
  String themeId;

  @HiveField(4)
  String? aiApiKey;

  @HiveField(5)
  String aiProvider;

  @HiveField(6)
  String aiModel;

  // ── Phase 1: 新增配置项 ────────────────────────────

  /// Cursor shape: 'block', 'beam', or 'underline'.
  @HiveField(7)
  String cursorShape;

  /// Whether the cursor blinks.
  @HiveField(8)
  bool cursorBlink;

  /// Custom shell path. null = use system default ($SHELL).
  @HiveField(9)
  String? shell;

  /// Shell arguments. null = platform default (e.g. ['--login']).
  @HiveField(10)
  List<String>? shellArgs;

  /// Maximum scrollback lines.
  @HiveField(11)
  int scrollback;

  /// Terminal line height (relative unit).
  @HiveField(12)
  double lineHeight;

  /// Terminal letter spacing (relative unit).
  @HiveField(13)
  double letterSpacing;

  /// Whether to copy selected text to clipboard automatically.
  @HiveField(14)
  bool copyOnSelect;

  /// Custom working directory. null = $HOME.
  @HiveField(15)
  String? workingDirectory;

  /// Custom cursor color (hex string). null = follow theme.
  @HiveField(16)
  String? cursorColor;

  /// Custom background color (hex string). null = follow theme.
  @HiveField(17)
  String? backgroundColor;

  /// Terminal background opacity (0.0 ~ 1.0).
  @HiveField(18)
  double backgroundOpacity;

  /// Terminal content padding in logical pixels.
  @HiveField(19)
  double padding;

  /// Whether to preserve current working directory when opening new tabs.
  @HiveField(20)
  bool preserveCWD;

  /// Custom environment variables merged into shell session.
  @HiveField(21)
  Map<String, String>? env;

  /// Serialize all fields to a flat map (for export/import).
  Map<String, dynamic> toFlatMap() => {
        'terminal_font_size': terminalFontSize,
        'terminal_font_family': terminalFontFamily,
        'theme_id': themeId,
        'cursor_shape': cursorShape,
        'cursor_blink': cursorBlink,
        'cursor_color': cursorColor,
        'shell': shell,
        'shell_args': shellArgs,
        'working_directory': workingDirectory,
        'scrollback': scrollback,
        'line_height': lineHeight,
        'letter_spacing': letterSpacing,
        'copy_on_select': copyOnSelect,
        'background_opacity': backgroundOpacity,
        'background_color': backgroundColor,
        'padding': padding,
        'env': env,
        'preserve_cwd': preserveCWD,
        'disable_underline': disableUnderline,
        'ai_provider': aiProvider,
        'ai_model': aiModel,
        'ai_api_key': aiApiKey,
      };

  /// Apply a flat map (from export/import) to this record's fields.
  void applyFlatMap(Map<String, dynamic> map) {
    if (map['terminal_font_size'] is num) {
      terminalFontSize = (map['terminal_font_size'] as num).toDouble();
    }
    if (map['terminal_font_family'] is String) {
      terminalFontFamily = map['terminal_font_family'] as String;
    }
    if (map['theme_id'] is String) themeId = map['theme_id'] as String;
    if (map['cursor_shape'] is String) {
      cursorShape = map['cursor_shape'] as String;
    }
    if (map['cursor_blink'] is bool) cursorBlink = map['cursor_blink'] as bool;
    if (map['cursor_color'] is String) {
      cursorColor = map['cursor_color'] as String;
    }
    if (map['shell'] is String) shell = map['shell'] as String;
    if (map['shell_args'] is List) {
      shellArgs = (map['shell_args'] as List).cast<String>();
    }
    if (map['working_directory'] is String) {
      workingDirectory = map['working_directory'] as String;
    }
    if (map['scrollback'] is int) scrollback = map['scrollback'] as int;
    if (map['line_height'] is num) {
      lineHeight = (map['line_height'] as num).toDouble();
    }
    if (map['letter_spacing'] is num) {
      letterSpacing = (map['letter_spacing'] as num).toDouble();
    }
    if (map['copy_on_select'] is bool) {
      copyOnSelect = map['copy_on_select'] as bool;
    }
    if (map['background_opacity'] is num) {
      backgroundOpacity = (map['background_opacity'] as num).toDouble();
    }
    if (map['background_color'] is String) {
      backgroundColor = map['background_color'] as String;
    }
    if (map['padding'] is num) padding = (map['padding'] as num).toDouble();
    if (map['env'] is Map) env = (map['env'] as Map).cast<String, String>();
    if (map['preserve_cwd'] is bool) preserveCWD = map['preserve_cwd'] as bool;
    if (map['disable_underline'] is bool) {
      disableUnderline = map['disable_underline'] as bool;
    }
    if (map['ai_provider'] is String) aiProvider = map['ai_provider'] as String;
    if (map['ai_model'] is String) aiModel = map['ai_model'] as String;
    if (map['ai_api_key'] is String) aiApiKey = map['ai_api_key'] as String;
  }

  SettingsRecord({
    this.terminalFontSize = 14.0,
    this.terminalFontFamily = 'Hack Nerd Font Mono',
    this.disableUnderline = true,
    this.themeId = 'dark',
    this.aiApiKey,
    this.aiProvider = 'openrouter',
    this.aiModel = 'google/gemini-2.0-flash-exp:free',
    this.cursorShape = 'block',
    this.cursorBlink = true,
    this.shell,
    this.shellArgs,
    this.scrollback = 10000,
    this.lineHeight = 1.2,
    this.letterSpacing = 0.0,
    this.copyOnSelect = false,
    this.workingDirectory,
    this.cursorColor,
    this.backgroundColor,
    this.backgroundOpacity = 0.8,
    this.padding = 0.0,
    this.preserveCWD = true,
    this.env,
  });
}
