import 'package:hive_flutter/hive_flutter.dart';

part 'settings_record.g.dart';

@HiveType(typeId: 2)
class SettingsRecord extends HiveObject {
  @HiveField(0)
  double terminalFontSize;

  @HiveField(1)
  String? terminalFontFamily;

  @HiveField(2)
  bool disableUnderline;

  SettingsRecord({
    this.terminalFontSize = 14.0,
    this.terminalFontFamily = 'Hack Nerd Font Mono',
    this.disableUnderline = true,
  });
}
