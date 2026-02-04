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

  SettingsRecord({
    this.terminalFontSize = 14.0,
    this.terminalFontFamily = 'Hack Nerd Font Mono',
    this.disableUnderline = true,
    this.themeId = 'dark',
    this.aiApiKey,
    this.aiProvider = 'openrouter',
    this.aiModel = 'google/gemini-2.0-flash-exp:free',
  });
}
