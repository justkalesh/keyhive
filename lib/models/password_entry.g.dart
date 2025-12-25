// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PasswordEntryAdapter extends TypeAdapter<PasswordEntry> {
  @override
  final int typeId = 0;

  @override
  PasswordEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PasswordEntry(
      id: fields[0] as String,
      platformName: fields[1] as String,
      username: fields[2] as String,
      password: fields[3] as String,
      dateCreated: fields[4] as DateTime,
      dateModified: fields[5] as DateTime,
      websiteUrl: fields[6] as String?,
      notes: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PasswordEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.platformName)
      ..writeByte(2)
      ..write(obj.username)
      ..writeByte(3)
      ..write(obj.password)
      ..writeByte(4)
      ..write(obj.dateCreated)
      ..writeByte(5)
      ..write(obj.dateModified)
      ..writeByte(6)
      ..write(obj.websiteUrl)
      ..writeByte(7)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasswordEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
