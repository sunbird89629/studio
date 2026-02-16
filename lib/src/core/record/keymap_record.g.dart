// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keymap_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KeymapRecordAdapter extends TypeAdapter<KeymapRecord> {
  @override
  final typeId = 4;

  @override
  KeymapRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KeymapRecord(
      bindings: (fields[0] as Map?)?.cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, KeymapRecord obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.bindings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeymapRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
