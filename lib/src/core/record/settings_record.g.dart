// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsRecordAdapter extends TypeAdapter<SettingsRecord> {
  @override
  final typeId = 2;

  @override
  SettingsRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsRecord(
      terminalFontSize:
          fields[0] == null ? 14.0 : (fields[0] as num).toDouble(),
      terminalFontFamily:
          fields[1] == null ? 'Hack Nerd Font Mono' : fields[1] as String?,
      disableUnderline: fields[2] == null ? true : fields[2] as bool?,
      themeId: fields[3] == null ? 'dark' : fields[3] as String,
      aiApiKey: fields[4] as String?,
      aiProvider: fields[5] == null ? 'openrouter' : fields[5] as String,
      aiModel: fields[6] == null
          ? 'google/gemini-2.0-flash-exp:free'
          : fields[6] as String,
      cursorShape: fields[7] == null ? 'block' : fields[7] as String,
      cursorBlink: fields[8] == null ? true : fields[8] as bool,
      shell: fields[9] as String?,
      shellArgs: (fields[10] as List?)?.cast<String>(),
      scrollback: fields[11] == null ? 10000 : (fields[11] as num).toInt(),
      lineHeight: fields[12] == null ? 1.2 : (fields[12] as num).toDouble(),
      letterSpacing: fields[13] == null ? 0.0 : (fields[13] as num).toDouble(),
      copyOnSelect: fields[14] == null ? false : fields[14] as bool,
      workingDirectory: fields[15] as String?,
      cursorColor: fields[16] as String?,
      backgroundColor: fields[17] as String?,
      backgroundOpacity:
          fields[18] == null ? 0.8 : (fields[18] as num).toDouble(),
      padding: fields[19] == null ? 0.0 : (fields[19] as num).toDouble(),
      preserveCWD: fields[20] == null ? true : fields[20] as bool,
      env: (fields[21] as Map?)?.cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, SettingsRecord obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.terminalFontSize)
      ..writeByte(1)
      ..write(obj.terminalFontFamily)
      ..writeByte(2)
      ..write(obj.disableUnderline)
      ..writeByte(3)
      ..write(obj.themeId)
      ..writeByte(4)
      ..write(obj.aiApiKey)
      ..writeByte(5)
      ..write(obj.aiProvider)
      ..writeByte(6)
      ..write(obj.aiModel)
      ..writeByte(7)
      ..write(obj.cursorShape)
      ..writeByte(8)
      ..write(obj.cursorBlink)
      ..writeByte(9)
      ..write(obj.shell)
      ..writeByte(10)
      ..write(obj.shellArgs)
      ..writeByte(11)
      ..write(obj.scrollback)
      ..writeByte(12)
      ..write(obj.lineHeight)
      ..writeByte(13)
      ..write(obj.letterSpacing)
      ..writeByte(14)
      ..write(obj.copyOnSelect)
      ..writeByte(15)
      ..write(obj.workingDirectory)
      ..writeByte(16)
      ..write(obj.cursorColor)
      ..writeByte(17)
      ..write(obj.backgroundColor)
      ..writeByte(18)
      ..write(obj.backgroundOpacity)
      ..writeByte(19)
      ..write(obj.padding)
      ..writeByte(20)
      ..write(obj.preserveCWD)
      ..writeByte(21)
      ..write(obj.env);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
