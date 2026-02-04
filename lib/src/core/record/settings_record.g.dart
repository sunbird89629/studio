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
    );
  }

  @override
  void write(BinaryWriter writer, SettingsRecord obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.aiModel);
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
