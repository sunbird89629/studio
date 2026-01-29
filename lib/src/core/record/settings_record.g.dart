// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsRecordAdapter extends TypeAdapter<SettingsRecord> {
  @override
  final int typeId = 2;

  @override
  SettingsRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsRecord(
      terminalFontSize: fields[0] as double,
      terminalFontFamily: fields[1] as String?,
      disableUnderline: (fields[2] as bool?) ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsRecord obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.terminalFontSize)
      ..writeByte(1)
      ..write(obj.terminalFontFamily)
      ..writeByte(2)
      ..write(obj.disableUnderline);
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
