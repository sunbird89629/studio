import 'package:terminal_studio/src/core/record/profile_record.dart';
import 'package:terminal_studio/src/core/record/settings_record.dart';

/// Resolved settings after merging Profile over Global.
///
/// Priority: Profile (non-null) > Global Settings > Code Default.
class EffectiveSettings {
  final SettingsRecord global;
  final ProfileRecord? profile;

  EffectiveSettings(this.global, [this.profile]);

  // ── Terminal ──

  double get terminalFontSize => profile?.fontSize ?? global.terminalFontSize;
  String get terminalFontFamily =>
      profile?.fontFamily ?? global.terminalFontFamily ?? 'Hack Nerd Font Mono';
  double get lineHeight => profile?.lineHeight ?? global.lineHeight;
  double get letterSpacing => profile?.letterSpacing ?? global.letterSpacing;
  int get scrollback => global.scrollback;
  bool get disableUnderline => global.disableUnderline ?? true;

  // ── Cursor ──

  String get cursorShape => profile?.cursorShape ?? global.cursorShape;
  bool get cursorBlink => profile?.cursorBlink ?? global.cursorBlink;
  String? get cursorColor => global.cursorColor;

  // ── Appearance ──

  String get themeId => profile?.themeId ?? global.themeId;
  double get backgroundOpacity =>
      profile?.backgroundOpacity ?? global.backgroundOpacity;
  double get padding => profile?.padding ?? global.padding;
  String? get backgroundColor => global.backgroundColor;

  // ── Shell ──

  String? get shell => profile?.shell ?? global.shell;
  List<String>? get shellArgs => profile?.shellArgs ?? global.shellArgs;
  String? get workingDirectory =>
      profile?.workingDirectory ?? global.workingDirectory;
  bool get preserveCWD => global.preserveCWD;
  bool get copyOnSelect => global.copyOnSelect;

  /// Merged environment variables: global env + profile env overlay.
  Map<String, String>? get env {
    if (global.env == null && profile?.env == null) return null;
    return {
      ...?global.env,
      ...?profile?.env,
    };
  }

  // ── AI ──

  String? get aiApiKey => global.aiApiKey;
  String get aiProvider => global.aiProvider;
  String get aiModel => global.aiModel;

  /// The ID of the active profile, or null if using global settings.
  String? get profileId => profile?.id;
  String get profileName => profile?.name ?? 'Default';
}
