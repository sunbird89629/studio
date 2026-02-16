// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProfileRecordAdapter extends TypeAdapter<ProfileRecord> {
  @override
  final typeId = 3;

  @override
  ProfileRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProfileRecord(
      id: fields[0] as String?,
      name: fields[1] == null ? 'Default' : fields[1] as String,
      shell: fields[2] as String?,
      shellArgs: (fields[3] as List?)?.cast<String>(),
      themeId: fields[4] as String?,
      fontSize: (fields[5] as num?)?.toDouble(),
      fontFamily: fields[6] as String?,
      env: (fields[7] as Map?)?.cast<String, String>(),
      workingDirectory: fields[8] as String?,
      cursorShape: fields[9] as String?,
      cursorBlink: fields[10] as bool?,
      lineHeight: (fields[11] as num?)?.toDouble(),
      letterSpacing: (fields[12] as num?)?.toDouble(),
      backgroundOpacity: (fields[13] as num?)?.toDouble(),
      padding: (fields[14] as num?)?.toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, ProfileRecord obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.shell)
      ..writeByte(3)
      ..write(obj.shellArgs)
      ..writeByte(4)
      ..write(obj.themeId)
      ..writeByte(5)
      ..write(obj.fontSize)
      ..writeByte(6)
      ..write(obj.fontFamily)
      ..writeByte(7)
      ..write(obj.env)
      ..writeByte(8)
      ..write(obj.workingDirectory)
      ..writeByte(9)
      ..write(obj.cursorShape)
      ..writeByte(10)
      ..write(obj.cursorBlink)
      ..writeByte(11)
      ..write(obj.lineHeight)
      ..writeByte(12)
      ..write(obj.letterSpacing)
      ..writeByte(13)
      ..write(obj.backgroundOpacity)
      ..writeByte(14)
      ..write(obj.padding);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
