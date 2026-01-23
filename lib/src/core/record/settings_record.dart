import 'package:hive_flutter/hive_flutter.dart';

part 'settings_record.g.dart';

@HiveType(typeId: 2)
class SettingsRecord extends HiveObject {
  @HiveField(0)
  double terminalFontSize;

  @HiveField(1)
  String? terminalFontFamily;

  SettingsRecord({
    this.terminalFontSize = 14.0,
    this.terminalFontFamily,
  });
}
