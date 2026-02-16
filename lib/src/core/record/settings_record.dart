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
